--!strict
-- Pure server-side authorization rules for building demolition.
local BuildingDemolitionRules = {}

function BuildingDemolitionRules.validate(record: any, catalog: any): (boolean, string)
	if type(record) ~= "table"
		or type(record.instanceId) ~= "string"
		or record.instanceId == ""
		or type(record.catalogId) ~= "string"
	then
		return false, "INVALID_BUILDING_RECORD"
	end

	if type(catalog) ~= "table" or type(catalog[record.catalogId]) ~= "table" then
		return false, "UNKNOWN_BUILDING"
	end

	if record.catalogId == "main_house" then
		return false, "MAIN_HOUSE_PROTECTED"
	end

	return true, "DEMOLITION_ALLOWED"
end

return BuildingDemolitionRules
