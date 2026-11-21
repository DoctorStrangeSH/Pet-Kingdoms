--!strict
-- Studio integration smoke test for the first real Creator Store pet mesh.
-- Requires Experience Settings > Security > Allow Loading Third Party Assets.
local ServerScriptService = game:GetService("ServerScriptService")
local loader = require(ServerScriptService:WaitForChild("Services"):WaitForChild("PetAssetLoader"))

local model, status = loader.create("bunny", 1)
assert(model ~= nil, "Bunny Creator Store mesh failed to load: " .. status)
assert(model:GetAttribute("IsExternalMeshPet") == true, "Bunny must use the external mesh path")
assert(model:GetAttribute("IsPetRigPrototype") == false, "Bunny must not be marked as the procedural rig prototype")
assert(model.PrimaryPart ~= nil, "Imported Bunny needs a PrimaryPart")

local meshCount = 0
for _, descendant in ipairs(model:GetDescendants()) do
	if descendant:IsA("MeshPart") then
		meshCount += 1
	end
	assert(not descendant:IsA("Script") and not descendant:IsA("LocalScript") and not descendant:IsA("ModuleScript"),
		"Third-party executable content must be removed")
	if descendant:IsA("BasePart") then
		assert(descendant.Anchored, "Imported mesh parts must be anchored for PivotTo follow")
		assert(not descendant.CanCollide, "Imported mesh parts must not collide with players")
	end
end
assert(meshCount > 0, "Imported Bunny must contain real MeshParts")

model:Destroy()
print("[PetKingdoms] Creator Store Bunny mesh smoke test passed.")
