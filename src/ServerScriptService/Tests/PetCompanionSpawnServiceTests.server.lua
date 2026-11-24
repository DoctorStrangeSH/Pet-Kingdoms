--!strict
-- Studio-only tests for server-side companion creation and respawn cleanup.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local sharedPets = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets")
local PetCollectionData = require(sharedPets:WaitForChild("PetCollectionData"))
local PetModelFactory = require(sharedPets:WaitForChild("PetModelFactory"))
local PetCompanionSpawnService = require(
	ServerScriptService:WaitForChild("Services"):WaitForChild("PetCompanionSpawnService")
)

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local ownerUserId = 900_000_000 + math.random(1, 90_000_000)
local profile = PetCollectionData.createDefault(ownerUserId)
assert(profile ~= nil)

local added, addStatus, withSecondPet = PetCollectionData.addPet(
	profile,
	"spawn-test-bunny",
	"bunny",
	2,
	100
)
expect("test pet can be added to a valid collection", added and addStatus == "UPDATED" and withSecondPet ~= nil)
assert(withSecondPet ~= nil)

local equipped, equipStatus, equippedProfile = PetCollectionData.setEquipped(
	withSecondPet,
	{ "starter-bunny", "spawn-test-bunny" }
)
expect("two owned pets can be equipped in order", equipped and equipStatus == "UPDATED" and equippedProfile ~= nil)
assert(equippedProfile ~= nil)

local character = Instance.new("Model")
character.Name = "PetCompanionSpawnTestCharacter"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Anchored = true
root.CanCollide = false
root.CFrame = CFrame.new(12, 5, 18)
root.Parent = character
character.PrimaryPart = root
character.Parent = Workspace

local active = true
local function isCurrent(): boolean
	return active and character.Parent ~= nil
end
local function createPrototype(speciesId: string, scale: number?)
	return PetModelFactory.create(speciesId, scale)
end

local spawned, spawnStatus = PetCompanionSpawnService.spawn(
	ownerUserId,
	character,
	equippedProfile,
	createPrototype,
	isCurrent
)
expect("equipped companions spawn from the injected Studio prototype factory",
	spawned == 2 and spawnStatus == "SPAWNED")

local rootFolder = Workspace:FindFirstChild("PlayerPets")
local playerFolder = rootFolder and rootFolder:FindFirstChild(tostring(ownerUserId))
expect("owner-specific companion folder is created", playerFolder ~= nil and playerFolder:IsA("Folder"))
assert(playerFolder ~= nil and playerFolder:IsA("Folder"))

local first = playerFolder:FindFirstChild("starter-bunny")
local second = playerFolder:FindFirstChild("spawn-test-bunny")
expect("both stable pet IDs become model names", first ~= nil and second ~= nil)
expect("owner and pet identity attributes are server assigned",
	first ~= nil and first:GetAttribute("OwnerUserId") == ownerUserId
	and first:GetAttribute("PetId") == "starter-bunny")
expect("formation slots preserve equipped order",
	first ~= nil and first:GetAttribute("FormationSlot") == 1
	and second ~= nil and second:GetAttribute("FormationSlot") == 2)

local firstPosition = first and (first :: Model):GetPivot().Position
local expectedFirstPosition = root.CFrame * CFrame.new(-2.4, 0, 4.5)
expect("first companion is positioned relative to the character root",
	firstPosition ~= nil and (firstPosition - expectedFirstPosition.Position).Magnitude < 0.01)

local oldFirst = first
local oldSecond = second
local rebuilt, rebuildStatus = PetCompanionSpawnService.spawn(
	ownerUserId,
	character,
	equippedProfile,
	createPrototype,
	isCurrent
)
expect("rebuilding a formation does not duplicate companions",
	rebuilt == 2 and rebuildStatus == "SPAWNED" and #playerFolder:GetChildren() == 2)
expect("previous formation models are destroyed before replacement",
	oldFirst ~= nil and oldFirst.Parent == nil and oldSecond ~= nil and oldSecond.Parent == nil)

local invalidProfile = PetCollectionData.clone(equippedProfile)
invalidProfile.ownerUserId += 1
local invalidCount, invalidStatus = PetCompanionSpawnService.spawn(
	ownerUserId,
	character,
	invalidProfile,
	createPrototype,
	isCurrent
)
expect("foreign collection cannot spawn companions",
	invalidCount == 0 and string.sub(invalidStatus, 1, 15) == "INVALID_PROFILE")
expect("invalid profile does not destroy the current valid formation", #playerFolder:GetChildren() == 2)

local factoryCalls = 0
local cancelledCount, cancelledStatus = PetCompanionSpawnService.spawn(
	ownerUserId,
	character,
	equippedProfile,
	function(speciesId: string, scale: number?)
		factoryCalls += 1
		local model, status = PetModelFactory.create(speciesId, scale)
		if factoryCalls == 2 then active = false end
		return model, status
	end,
	isCurrent
)
expect("stale spawn is cancelled between pet creations",
	cancelledCount == 0 and cancelledStatus == "SPAWN_CANCELLED")
expect("cancelled spawn removes only models created by its own attempt",
	#playerFolder:GetChildren() == 0)

active = true
local gatedCount, gatedStatus = PetCompanionSpawnService.spawn(
	ownerUserId,
	character,
	equippedProfile,
	function()
		return nil, "ASSET_NOT_CONFIGURED"
	end,
	isCurrent
)
expect("unapproved external assets remain blocked without fake pets",
	gatedCount == 0 and gatedStatus == "NO_PETS_CREATED" and #playerFolder:GetChildren() == 0)

local removed, clearStatus = PetCompanionSpawnService.clear(ownerUserId)
expect("owner cleanup is safe and idempotent", clearStatus == "CLEARED" and removed == 0)
local missingRemoved, missingStatus = PetCompanionSpawnService.clear(ownerUserId + 1)
expect("cleanup of an absent owner folder is harmless", missingRemoved == 0 and missingStatus == "NOT_FOUND")

character:Destroy()
PetCompanionSpawnService.clear(ownerUserId)
print("[PetKingdoms Test] PetCompanionSpawnService tests completed.")
