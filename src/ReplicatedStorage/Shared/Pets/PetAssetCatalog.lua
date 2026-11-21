--!strict
-- Project-owned pet mesh catalog. Asset IDs stay unset until the matching source mesh
-- is imported and published from this experience in Roblox Studio.
local PetAssetCatalog = {
	bunny = {
		assetId = nil,
		sourcePath = "assets/pets/bunny/bunny.obj",
		sourceMaterialPath = "assets/pets/bunny/bunny.mtl",
		creator = "Pet Kingdoms original asset",
		license = "Project-created original mesh",
		vertexCount = 15332,
		triangleCount = 30194,
		meshObjectCount = 13,
		materialCount = 9,
		assetKind = "Original triangulated OBJ mesh",
		visualReview = "PENDING_ROBLOX_STUDIO_IMPORT",
		rigStatus = "BLENDER_BUILD_CI_PENDING",
		status = "SOURCE_COMMITTED_BLENDER_BUILD_PENDING",
	},
}

return PetAssetCatalog
