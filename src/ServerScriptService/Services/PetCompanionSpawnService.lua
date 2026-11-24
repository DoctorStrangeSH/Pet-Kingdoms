--!strict
-- Server-authoritative creation and cleanup of equipped companion models.
-- The model factory is injected so Studio tests can exercise lifecycle behavior
-- without publishing or enabling an unreviewed production pet asset.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetCollectionData = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetCollectionData")
)

local PetCompanionSpawnService = {}

type ModelFactory = (speciesId: string, scale: number?) -> (Model?, string)
type IsCurrent = () -> boolean

local function getPlayerFolder(ownerUserId: number): Folder
	local root = Workspace:FindFirstChild("PlayerPets")
	if root == nil then
		root = Instance.new("Folder")
		root.Name = "PlayerPets"
		root.Parent = Workspace
	end

	local folderName = tostring(ownerUserId)
	local playerFolder = root:FindFirstChild(folderName)
	if playerFolder == nil then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = folderName
		playerFolder.Parent = root
	end
	return playerFolder :: Folder
end

local function clearFolder(folder: Folder): number
	local removed = 0
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
		removed += 1
	end
	return removed
end

function PetCompanionSpawnService.clear(ownerUserId: number): (number, string)
	if type(ownerUserId) ~= "number" or ownerUserId <= 0 or ownerUserId % 1 ~= 0 then
		return 0, "INVALID_OWNER"
	end

	local root = Workspace:FindFirstChild("PlayerPets")
	local folder = root and root:FindFirstChild(tostring(ownerUserId))
	if folder == nil or not folder:IsA("Folder") then
		return 0, "NOT_FOUND"
	end
	return clearFolder(folder), "CLEARED"
end

function PetCompanionSpawnService.spawn(
	ownerUserId: number,
	character: Model,
	profile: any,
	createModel: ModelFactory,
	isCurrent: IsCurrent
): (number, string)
	if type(ownerUserId) ~= "number" or ownerUserId <= 0 or ownerUserId % 1 ~= 0 then
		return 0, "INVALID_OWNER"
	end
	if typeof(character) ~= "Instance" or not character:IsA("Model") or character.Parent == nil then
		return 0, "INVALID_CHARACTER"
	end
	if type(createModel) ~= "function" or type(isCurrent) ~= "function" then
		return 0, "INVALID_DEPENDENCY"
	end

	local valid, reason = PetCollectionData.validate(profile, ownerUserId)
	if not valid then
		return 0, "INVALID_PROFILE:" .. reason
	end
	if not isCurrent() then
		return 0, "SPAWN_CANCELLED"
	end

	local playerFolder = getPlayerFolder(ownerUserId)
	-- Rebuilding a formation always starts from an empty folder. This makes
	-- equip changes and character respawns idempotent instead of duplicating pets.
	clearFolder(playerFolder)

	local targetRoot = character:FindFirstChild("HumanoidRootPart")
	if targetRoot == nil or not targetRoot:IsA("BasePart") then
		return 0, "CHARACTER_ROOT_MISSING"
	end

	local spawnedModels: { Model } = {}
	local spawnedCount = 0
	local failedCount = 0

	local function destroyModelsCreatedByThisRun()
		for _, model in ipairs(spawnedModels) do
			model:Destroy()
		end
		table.clear(spawnedModels)
	end

	for slotIndex, petId in ipairs(profile.equipped) do
		if not isCurrent() or character.Parent == nil then
			destroyModelsCreatedByThisRun()
			return 0, "SPAWN_CANCELLED"
		end

		local record: any = nil
		for _, ownedRecord in ipairs(profile.owned) do
			if ownedRecord.petId == petId then
				record = ownedRecord
				break
			end
		end

		if record ~= nil then
			local factoryOk, petModel, status = pcall(createModel, record.speciesId, 1)
			if not factoryOk then
				petModel = nil
				status = "MODEL_FACTORY_ERROR"
			end

			-- A factory may yield. Re-check ownership of this spawn attempt before
			-- publishing its model so a stale character cannot repopulate the folder.
			if not isCurrent() or character.Parent == nil then
				if petModel and typeof(petModel) == "Instance" then
					petModel:Destroy()
				end
				destroyModelsCreatedByThisRun()
				return 0, "SPAWN_CANCELLED"
			end

			if petModel and typeof(petModel) == "Instance" and petModel:IsA("Model")
				and status == "CREATED" and petModel.PrimaryPart ~= nil
				and petModel.PrimaryPart:IsDescendantOf(petModel)
			then
				petModel.Name = petId
				petModel:SetAttribute("PetId", petId)
				petModel:SetAttribute("OwnerUserId", ownerUserId)
				petModel:SetAttribute("FormationSlot", slotIndex)
				petModel.Parent = playerFolder
				petModel:PivotTo(targetRoot.CFrame * CFrame.new((slotIndex - 2) * 2.4, 0, 4.5))
				table.insert(spawnedModels, petModel)
				spawnedCount += 1
			else
				if petModel and typeof(petModel) == "Instance" then
					petModel:Destroy()
				end
				failedCount += 1
				warn("[PetKingdoms] Could not create equipped pet", petId, status)
			end
		end
	end

	if spawnedCount == 0 then
		return 0, if failedCount > 0 then "NO_PETS_CREATED" else "NO_EQUIPPED_PETS"
	end
	return spawnedCount, if failedCount > 0 then "SPAWNED_PARTIAL" else "SPAWNED"
end

return PetCompanionSpawnService
