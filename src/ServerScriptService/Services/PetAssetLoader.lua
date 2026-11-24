--!strict
-- Loads project-owned pet models after they have been imported and published to this experience.
-- Asset IDs remain unset until the matching original source is approved in Studio.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetAssetCatalog = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetAssetCatalog")
)

local PetAssetLoader = {}

local function removeExecutableContent(model: Model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		end
	end
end

function PetAssetLoader.create(speciesId: string, scale: number?): (Model?, string)
	local entry = PetAssetCatalog[speciesId]
	if entry == nil or type(entry.assetId) ~= "number" then
		return nil, "ASSET_NOT_CONFIGURED"
	end

	local requestedScale = scale or 1
	if type(requestedScale) ~= "number" or requestedScale <= 0 or requestedScale > 3 then
		return nil, "INVALID_SCALE"
	end

	local ok, loaded = pcall(function()
		return AssetService:LoadAssetAsync(entry.assetId)
	end)
	if not ok or loaded == nil or not loaded:IsA("Model") then
		warn("[PetKingdoms] Published project pet asset could not be loaded:", speciesId, loaded)
		return nil, "PUBLISHED_ASSET_LOAD_FAILED"
	end

	local model = loaded
	local meshParts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			table.insert(meshParts, descendant)
		end
	end
	if #meshParts == 0 then
		model:Destroy()
		return nil, "ASSET_HAS_NO_MESH_PARTS"
	end

	removeExecutableContent(model)
	model.Name = "Pet_" .. speciesId
	model:SetAttribute("SpeciesId", speciesId)
	model:SetAttribute("IsExternalMeshPet", true)
	model:SetAttribute("IsPetRigPrototype", false)
	model:SetAttribute("AssetId", entry.assetId)
	model:SetAttribute("Scale", requestedScale)

	local primary = meshParts[1]
	if primary == nil or not primary:IsDescendantOf(model) then
		primary = model:FindFirstChildWhichIsA("BasePart", true)
	end
	if primary == nil then
		model:Destroy()
		return nil, "ASSET_HAS_NO_ROOT_PART"
	end
	model.PrimaryPart = primary

	removeExecutableContent(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.Massless = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	local scaled, scaleError = pcall(function()
		model:ScaleTo(requestedScale)
	end)
	if not scaled then
		warn("[PetKingdoms] Could not scale published project pet:", speciesId, scaleError)
		model:Destroy()
		return nil, "ASSET_SCALE_FAILED"
	end

	local boundsCFrame, boundsSize = model:GetBoundingBox()
	local oldPivot = model:GetPivot()
	local moveToGround = CFrame.new(0, boundsSize.Y / 2, 0) * boundsCFrame:Inverse()
	model:PivotTo(moveToGround * oldPivot)
	model:SetAttribute("VisualHeight", boundsSize.Y)
	model:SetAttribute("GroundOffset", math.clamp(boundsSize.Y * 0.025, 0.08, 0.28))

	return model, "CREATED"
end

return PetAssetLoader
