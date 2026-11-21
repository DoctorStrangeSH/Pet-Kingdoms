--!strict
-- Versioned, serializable island profile helpers.
-- This module does not call DataStoreService and does not spawn Instances.
-- Bounds are supplied by the server's island/plot configuration; no world size is invented here.

local GridMath = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Building")
	:WaitForChild("GridMath"))

local IslandData = {}

IslandData.SCHEMA_VERSION = 1

export type BuildingRecord = {
	instanceId: string,
	catalogId: string,
	x: number,
	z: number,
	rotation: number,
}

export type IslandProfile = {
	schemaVersion: number,
	ownerUserId: number,
	boundsWidth: number,
	boundsDepth: number,
	buildings: { BuildingRecord },
	unlockedBuildingIds: { [string]: boolean },
	revision: number,
}

local function isInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

local function isValidCatalogItem(catalog: any, catalogId: any): boolean
	if type(catalogId) ~= "string" or type(catalog) ~= "table" then
		return false
	end

	local definition = catalog[catalogId]
	return type(definition) == "table"
		and definition.id == catalogId
		and isInteger(definition.footprintWidth)
		and isInteger(definition.footprintDepth)
		and definition.footprintWidth > 0
		and definition.footprintDepth > 0
		and type(definition.allowedRotations) == "table"
end

function IslandData.create(ownerUserId: number, boundsWidth: number, boundsDepth: number): IslandProfile?
	if not isInteger(ownerUserId) or ownerUserId <= 0
		or not isInteger(boundsWidth) or boundsWidth <= 0
		or not isInteger(boundsDepth) or boundsDepth <= 0
	then
		return nil
	end

	return {
		schemaVersion = IslandData.SCHEMA_VERSION,
		ownerUserId = ownerUserId,
		boundsWidth = boundsWidth,
		boundsDepth = boundsDepth,
		buildings = {},
		unlockedBuildingIds = {},
		revision = 0,
	}
end

function IslandData.validate(profile: any, expectedOwnerUserId: number, catalog: any): (boolean, string)
	if type(profile) ~= "table" then
		return false, "PROFILE_NOT_TABLE"
	end

	if profile.schemaVersion ~= IslandData.SCHEMA_VERSION then
		return false, "UNSUPPORTED_SCHEMA_VERSION"
	end

	if not isInteger(expectedOwnerUserId)
		or expectedOwnerUserId <= 0
		or profile.ownerUserId ~= expectedOwnerUserId
	then
		return false, "OWNER_MISMATCH"
	end

	if not isInteger(profile.boundsWidth) or profile.boundsWidth <= 0
		or not isInteger(profile.boundsDepth) or profile.boundsDepth <= 0
		or not isInteger(profile.revision) or profile.revision < 0
	then
		return false, "INVALID_PROFILE_METADATA"
	end

	if type(profile.buildings) ~= "table" or type(profile.unlockedBuildingIds) ~= "table" then
		return false, "INVALID_PROFILE_COLLECTIONS"
	end

	for catalogId, unlocked in pairs(profile.unlockedBuildingIds) do
		if type(catalogId) ~= "string" or type(unlocked) ~= "boolean"
			or type(catalog[catalogId]) ~= "table"
			or catalog[catalogId].id ~= catalogId
		then
			return false, "INVALID_UNLOCK_RECORD"
		end
	end

	local seenIds: { [string]: boolean } = {}
	local occupied = {}

	for _, record in ipairs(profile.buildings) do
		if type(record) ~= "table"
			or type(record.instanceId) ~= "string"
			or record.instanceId == ""
			or seenIds[record.instanceId] == true
			or not isValidCatalogItem(catalog, record.catalogId)
			or not isInteger(record.x)
			or not isInteger(record.z)
			or not isInteger(record.rotation)
		then
			return false, "INVALID_BUILDING_RECORD"
		end

		seenIds[record.instanceId] = true
		local definition = catalog[record.catalogId]
		local rotation = record.rotation % 360
		if definition.allowedRotations[rotation] ~= true then
			return false, "INVALID_BUILDING_ROTATION"
		end

		local width, depth = GridMath.getRotatedFootprint(
			definition.footprintWidth,
			definition.footprintDepth,
			rotation
		)
		if width == nil or depth == nil then
			return false, "INVALID_BUILDING_FOOTPRINT"
		end

		local footprint = {
			x = record.x,
			z = record.z,
			width = width,
			depth = depth,
		}
		if not GridMath.isWithinBounds(footprint, profile.boundsWidth, profile.boundsDepth) then
			return false, "BUILDING_OUT_OF_BOUNDS"
		end

		for _, other in ipairs(occupied) do
			if GridMath.footprintsOverlap(footprint, other) then
				return false, "BUILDINGS_OVERLAP"
			end
		end
		table.insert(occupied, footprint)
	end

	return true, "VALID"
end

return IslandData
