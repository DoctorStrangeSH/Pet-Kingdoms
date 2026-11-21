--!strict
-- Server-side placement validation. This module validates a proposal only:
-- it does not charge resources, create Instances, mutate island data, or save.
-- Those operations must be added in a server-owned transaction layer.

local GridMath = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared")
	:WaitForChild("Building")
	:WaitForChild("GridMath"))

local PlacementValidator = {}

type BuildingDefinition = {
	id: string,
	footprintWidth: number,
	footprintDepth: number,
	allowedRotations: { [number]: boolean },
	defaultUnlocked: boolean,
}

type ExistingBuilding = {
	instanceId: string,
	catalogId: string,
	x: number,
	z: number,
	rotation: number,
}

type IslandState = {
	ownerUserId: number,
	boundsWidth: number,
	boundsDepth: number,
	buildings: { ExistingBuilding },
	unlockedBuildingIds: { [string]: boolean }?,
}

type PlacementRequest = {
	catalogId: string,
	x: number,
	z: number,
	rotation: number,
	movingInstanceId: string?,
}

type ValidationResult = {
	ok: boolean,
	code: string,
	catalogId: string?,
	x: number?,
	z: number?,
	rotation: number?,
	footprintWidth: number?,
	footprintDepth: number?,
}

local function failure(code: string): ValidationResult
	return {
		ok = false,
		code = code,
	}
end

local function isInteger(value: any): boolean
	return type(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

local function isValidDefinition(definition: any): boolean
	return type(definition) == "table"
		and type(definition.id) == "string"
		and isInteger(definition.footprintWidth)
		and isInteger(definition.footprintDepth)
		and definition.footprintWidth > 0
		and definition.footprintDepth > 0
		and type(definition.allowedRotations) == "table"
		and type(definition.defaultUnlocked) == "boolean"
end

local function findBuilding(buildings: { ExistingBuilding }, instanceId: string): ExistingBuilding?
	for _, building in ipairs(buildings) do
		if type(building) == "table" and building.instanceId == instanceId then
			return building
		end
	end
	return nil
end

function PlacementValidator.validate(
	playerUserId: number,
	request: any,
	island: IslandState,
	catalog: { [string]: BuildingDefinition }
): ValidationResult
	if not isInteger(playerUserId) or playerUserId <= 0 then
		return failure("INVALID_PLAYER")
	end

	if type(island) ~= "table"
		or not isInteger(island.ownerUserId)
		or island.ownerUserId ~= playerUserId
		or not isInteger(island.boundsWidth)
		or not isInteger(island.boundsDepth)
		or island.boundsWidth <= 0
		or island.boundsDepth <= 0
		or type(island.buildings) ~= "table"
		or (island.unlockedBuildingIds ~= nil and type(island.unlockedBuildingIds) ~= "table")
	then
		return failure("INVALID_OR_UNOWNED_ISLAND")
	end

	if type(catalog) ~= "table" then
		return failure("INVALID_CATALOG")
	end

	if type(request) ~= "table"
		or type(request.catalogId) ~= "string"
		or not isInteger(request.x)
		or not isInteger(request.z)
		or not isInteger(request.rotation)
	then
		return failure("INVALID_REQUEST")
	end

	local definition = catalog[request.catalogId]
	if not isValidDefinition(definition) or definition.id ~= request.catalogId then
		return failure("UNKNOWN_BUILDING")
	end

	if definition.defaultUnlocked ~= true
		and (island.unlockedBuildingIds == nil or island.unlockedBuildingIds[request.catalogId] ~= true)
	then
		return failure("BUILDING_LOCKED")
	end

	local rotation = request.rotation % 360
	if definition.allowedRotations[rotation] ~= true then
		return failure("ROTATION_NOT_ALLOWED")
	end

	local width, depth = GridMath.getRotatedFootprint(
		definition.footprintWidth,
		definition.footprintDepth,
		rotation
	)
	if width == nil or depth == nil then
		return failure("INVALID_FOOTPRINT")
	end

	local movingInstanceId = request.movingInstanceId
	if movingInstanceId ~= nil then
		if type(movingInstanceId) ~= "string" or movingInstanceId == "" then
			return failure("INVALID_MOVE_TARGET")
		end

		local existing = findBuilding(island.buildings, movingInstanceId)
		if existing == nil or existing.catalogId ~= request.catalogId then
			return failure("MOVE_TARGET_NOT_FOUND")
		end
	end

	local candidate = {
		x = request.x,
		z = request.z,
		width = width,
		depth = depth,
	}

	if not GridMath.isWithinBounds(candidate, island.boundsWidth, island.boundsDepth) then
		return failure("OUT_OF_BOUNDS")
	end

	local seenInstanceIds: { [string]: boolean } = {}
	for _, existing in ipairs(island.buildings) do
		if type(existing) ~= "table"
			or type(existing.instanceId) ~= "string"
			or existing.instanceId == ""
			or seenInstanceIds[existing.instanceId] == true
		then
			return failure("ISLAND_STATE_INVALID")
		end
		seenInstanceIds[existing.instanceId] = true

		local existingDefinition = catalog[existing.catalogId]
		if not isValidDefinition(existingDefinition) or existingDefinition.id ~= existing.catalogId then
			return failure("ISLAND_STATE_INVALID")
		end

		if not isInteger(existing.x)
			or not isInteger(existing.z)
			or not isInteger(existing.rotation)
		then
			return failure("ISLAND_STATE_INVALID")
		end

		local existingRotation = existing.rotation % 360
		if existingDefinition.allowedRotations[existingRotation] ~= true then
			return failure("ISLAND_STATE_INVALID")
		end

		local existingWidth, existingDepth = GridMath.getRotatedFootprint(
			existingDefinition.footprintWidth,
			existingDefinition.footprintDepth,
			existingRotation
		)
		if existingWidth == nil or existingDepth == nil then
			return failure("ISLAND_STATE_INVALID")
		end

		local occupied = {
			x = existing.x,
			z = existing.z,
			width = existingWidth,
			depth = existingDepth,
		}
		if not GridMath.isWithinBounds(occupied, island.boundsWidth, island.boundsDepth) then
			return failure("ISLAND_STATE_INVALID")
		end

		if existing.instanceId ~= movingInstanceId then
			if not isValidDefinition(existingDefinition) or existingDefinition.id ~= existing.catalogId then
				return failure("ISLAND_STATE_INVALID")
			end

			if not isInteger(existing.x)
				or not isInteger(existing.z)
				or not isInteger(existing.rotation)
				or type(existing.instanceId) ~= "string"
			then
				return failure("ISLAND_STATE_INVALID")
			end

			local existingRotation = existing.rotation % 360
			if existingDefinition.allowedRotations[existingRotation] ~= true then
				return failure("ISLAND_STATE_INVALID")
			end

			local existingWidth, existingDepth = GridMath.getRotatedFootprint(
				existingDefinition.footprintWidth,
				existingDefinition.footprintDepth,
				existingRotation
			)
			if existingWidth == nil or existingDepth == nil then
				return failure("ISLAND_STATE_INVALID")
			end

			local occupied = {
				x = existing.x,
				z = existing.z,
				width = existingWidth,
				depth = existingDepth,
			}
			if not GridMath.isWithinBounds(occupied, island.boundsWidth, island.boundsDepth) then
				return failure("ISLAND_STATE_INVALID")
			end

			if GridMath.footprintsOverlap(candidate, occupied) then
				return failure("FOOTPRINT_OVERLAP")
			end
		end
	end

	return {
		ok = true,
		code = "VALID",
		catalogId = request.catalogId,
		x = request.x,
		z = request.z,
		rotation = rotation,
		footprintWidth = width,
		footprintDepth = depth,
	}
end

return PlacementValidator
