--!strict
-- Gate test: the rejected Creator Store bunny must never load.
-- The original project-owned OBJ must first be imported and published from Roblox Studio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetAssetCatalog"))
local loader = require(ServerScriptService:WaitForChild("Services"):WaitForChild("PetAssetLoader"))

assert(catalog.bunny.assetId == nil, "Do not restore the rejected Creator Store Bunny asset ID.")
assert(catalog.bunny.sourcePath == "assets/pets/bunny/bunny.obj", "Runtime source must point to the original project-owned Bunny mesh.")
assert(catalog.bunny.status == "SOURCE_COMMITTED_BLENDER_BUILD_PENDING", "Bunny must remain gated until Studio import and publish.")

local model, status = loader.create("bunny", 1)
assert(model == nil, "Bunny must not spawn an unapproved third-party replacement.")
assert(status == "ASSET_NOT_CONFIGURED", "Expected Studio import/publish gate, got: " .. status)

print("[PetKingdoms] Rejected asset is blocked; original Bunny mesh awaits Studio import.")
