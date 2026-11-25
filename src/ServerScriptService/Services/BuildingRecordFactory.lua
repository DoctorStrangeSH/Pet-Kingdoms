--!strict
-- Pure constructors for persisted building records.
-- Keep identity and progression when a building changes grid position.
local BuildingRecordFactory = {}

function BuildingRecordFactory.moved(existing: any, validation: any): any
	assert(type(existing) == "table", "existing building record is required")
	assert(type(validation) == "table" and validation.ok == true, "successful placement validation is required")

	return {
		instanceId = existing.instanceId,
		catalogId = existing.catalogId,
		x = validation.x,
		z = validation.z,
		rotation = validation.rotation,
		upgradeLevel = existing.upgradeLevel,
	}
end

return BuildingRecordFactory
