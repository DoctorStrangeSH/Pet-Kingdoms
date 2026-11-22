--!strict
-- Versioned, server-owned pet XP progression curves used by durable reward recovery.
-- Keep this registry empty until the owner approves the actual XP balance.
local PetProgressionData = require(game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets"):WaitForChild("PetProgressionData"))

local PetProgressionCatalog = {}

local VERSIONS: { [number]: { number } } = {
	-- [1] = { ... exactly 50 strictly increasing lifetime XP thresholds ... },
}

function PetProgressionCatalog.getThresholds(version: any): ({ number }?, string)
	if type(version) ~= "number" or version ~= version
		or version == math.huge or version == -math.huge
		or version < 1 or version > PetProgressionData.MAX_SAFE_INTEGER
		or version ~= math.floor(version) then
		return nil, "INVALID_PROGRESSION_VERSION"
	end
	local thresholds = VERSIONS[version]
	if thresholds == nil then
		return nil, "PROGRESSION_VERSION_NOT_CONFIGURED"
	end
	local valid, reason = PetProgressionData.validateThresholds(thresholds)
	if not valid then
		return nil, "INVALID_CONFIGURED_THRESHOLDS:" .. reason
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
