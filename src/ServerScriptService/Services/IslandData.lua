--!strict
-- Versioned, serializable island profile helpers.
-- This module does not call DataStoreService and does not spawn Instances.
-- Bounds are supplied by the server's island/plot configuration; no world size is invented here.

local GridMath = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Building")
	:WaitForChild("GridMath"))
local IslandHatchLedgerData = require(script.Parent:WaitForChild("IslandHatchLedgerData"))
local IslandResources = require(script.Parent:WaitForChild("IslandResources"))
local IslandBuildingJournalData = require(script.Parent:WaitForChild("IslandBuildingJournalData"))
local IslandResourceNodeData = require(script.Parent:WaitForChild("IslandResourceNodeData"))
local IslandExpansion = require(script.Parent:WaitForChild("IslandExpansion"))
local QuestProgressData = require(script.Parent:WaitForChild("QuestProgressData"))

local IslandData = {}

IslandData.SCHEMA_VERSION = 1
IslandData.MAX_BUILDINGS_PER_ISLAND = 256
local MAX_BUILDINGS_PER_ISLAND = IslandData.MAX_BUILDINGS_PER_ISLAND

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
	resources: { [string]: number },
	buildingOperations: { any },
	resourceNodes: { any },
	revision: number,
	sessionGeneration: number?,
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
		expansionLevel = 0,
		buildings = {},
		unlockedBuildingIds = {},
		resources = { wood = 2, stone = 1, gold = 0, gems = 0 },
		hatchTransactions = {},
		buildingOperations = {},
		resourceNodes = {},
		questProgress = QuestProgressData.create(),
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
		or (profile.sessionGeneration ~= nil and (not isInteger(profile.sessionGeneration) or profile.sessionGeneration < 0))
	then
		return false, "INVALID_PROFILE_METADATA"
	end

	if profile.expansionLevel ~= nil and not IslandExpansion.isValidLevel(profile.expansionLevel) then
		return false, "INVALID_EXPANSION_LEVEL"
	end

	if type(profile.buildings) ~= "table" or type(profile.unlockedBuildingIds) ~= "table" then
		return false, "INVALID_PROFILE_COLLECTIONS"
	end

	-- Legacy schema-v1 profiles may not contain a resource wallet yet.
	-- IslandStore normalizes them during load/claim; validation accepts nil
	-- only so the migration can be applied without discarding existing islands.
	if profile.resources ~= nil then
		-- Keep saved-profile validation aligned with the live wallet's resource
		-- IDs, integer precision and maximum balance. Divergent rules could let
		-- a profile load successfully but make every later wallet mutation fail.
		local validWallet, walletReason = IslandResources.validate(profile.resources)
		if not validWallet then return false, walletReason end
	end

	if profile.hatchTransactions ~= nil then
		local validLedger, ledgerReason = IslandHatchLedgerData.validateLedger(profile.hatchTransactions)
		if not validLedger then
			return false, "INVALID_HATCH_LEDGER:" .. ledgerReason
		end
	end

	-- Older schema-v1 profiles predate durable building-operation receipts.
	if profile.buildingOperations ~= nil then
		local validBuildingLedger, buildingLedgerReason =
			IslandBuildingJournalData.validateLedger(profile.buildingOperations)
		if not validBuildingLedger then
			return false, "INVALID_BUILDING_LEDGER:" .. buildingLedgerReason
		end
		for _, receipt in ipairs(profile.buildingOperations) do
			if receipt.revision > profile.revision then
				return false, "INVALID_BUILDING_LEDGER:REVISION_AHEAD"
			end
		end
	end

	-- Legacy schema-v1 profiles predate introductory quest progress.
	if profile.questProgress ~= nil then
		local validQuests, questReason = QuestProgressData.validate(profile.questProgress)
		if not validQuests then return false, "INVALID_QUEST_PROGRESS:" .. questReason end
	end

	-- Legacy schema-v1 profiles predate persisted resource-node cooldowns.
	if profile.resourceNodes ~= nil then
		local validNodes, nodeReason = IslandResourceNodeData.validate(profile.resourceNodes)
		if not validNodes then
			return false, "INVALID_RESOURCE_NODES:" .. nodeReason
		end
	end

	local buildingCount = 0
	local highestBuildingIndex = 0
	for key in pairs(profile.buildings) do
		if not isInteger(key) or key < 1 then
			return false, "INVALID_BUILDING_LIST"
		end
		buildingCount += 1
		highestBuildingIndex = math.max(highestBuildingIndex, key)
	end
	if buildingCount > MAX_BUILDINGS_PER_ISLAND then
		return false, "TOO_MANY_BUILDINGS"
	end
	if highestBuildingIndex ~= buildingCount then
		return false, "INVALID_BUILDING_LIST"
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
