--!strict
-- Studio-only contract tests for versioned pet progression configuration.
local services = game:GetService("ServerScriptService"):WaitForChild("Services")
local PetProgressionCatalog = require(services:WaitForChild("PetProgressionCatalog"))

local passed = 0
local failed = 0

local function expect(name: string, condition: boolean)
	if condition then
		passed += 1
		print("[PASS] " .. name)
	else
		failed += 1
		warn("[FAIL] " .. name)
	end
end

local invalid, invalidCode = PetProgressionCatalog.getThresholds(0)
expect("zero progression version is rejected", invalid == nil and invalidCode == "INVALID_PROGRESSION_VERSION")

local fractional, fractionalCode = PetProgressionCatalog.getThresholds(1.5)
expect("fractional progression version is rejected", fractional == nil and fractionalCode == "INVALID_PROGRESSION_VERSION")

local unknown, unknownCode = PetProgressionCatalog.getThresholds(2147483000)
expect("unknown progression version fails closed", unknown == nil and unknownCode == "PROGRESSION_VERSION_NOT_CONFIGURED")

local versions = PetProgressionCatalog.getConfiguredVersions()
local previous = 0
local ordered = true
for _, version in ipairs(versions) do
	if version <= previous then ordered = false end
	previous = version
end
expect("configured progression versions are unique and sorted", ordered)

print(string.format("[PetProgressionCatalogTests] %d passed, %d failed", passed, failed))
assert(failed == 0, "Pet progression catalog contract tests failed")
