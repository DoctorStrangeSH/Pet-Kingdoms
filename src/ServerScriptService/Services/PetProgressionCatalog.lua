--!strict
-- Versioned, server-owned pet XP progression curves used by durable reward recovery.
-- Keep this registry empty until the owner approves the actual XP balance.
local PetProgressionCatalog = {}

local VERSIONS: { [number]: { number } } = {
	-- [1] = { ... exactly 50 strictly increasing lifetime XP thresholds ... },
}

function PetProgressionCatalog.getThresholds(version: any): ({ number }?, string)
	if type(version) ~= "number" or version < 1 or version ~= math.floor(version) then
		return nil, "INVALID_PROGRESSION_VERSION"
	end
	local thresholds = VERSIONS[version]
	if thresholds == nil then
		return nil, "PROGRESSION_VERSION_NOT_CONFIGURED"
	end
	return table.clone(thresholds), "CONFIGURED"
end

function PetProgressionCatalog.getConfiguredVersions(): { number }
	local versions = {}
	for version in pairs(VERSIONS) do
		table.insert(versions, version)
	end
	table.sort(versions)
	return versions
end

return PetProgressionCatalog
