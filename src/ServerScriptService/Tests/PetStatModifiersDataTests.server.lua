--!strict
-- Studio-only pure tests for declarative pet stat modifier records.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Pets = game:GetService("ReplicatedStorage")
	:WaitForChild("Shared"):WaitForChild("Pets")
local PetStatModifiersData = require(Pets:WaitForChild("PetStatModifiersData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local validModifier = {
	id = "iron_charm_health",
	sourceType = "equipment",
	sourceId = "iron_charm",
	stat = "health",
	operation = "flat",
	value = 12,
}

local valid, status = PetStatModifiersData.validateModifier(validModifier)
expect("valid equipment modifier is accepted", valid and status == "VALID")

local skillModifier = table.clone(validModifier)
skillModifier.id = "skill_attack_boost"
skillModifier.sourceType = "skill"
skillModifier.sourceId = "skill_attack_boost"
skillModifier.stat = "attack"
skillModifier.operation = "percent"
skillModifier.value = 5
expect("skill percent modifier is accepted as data", PetStatModifiersData.validateModifier(skillModifier))

local abilityModifier = table.clone(validModifier)
abilityModifier.id = "ability_speed_boost"
abilityModifier.sourceType = "ability"
abilityModifier.sourceId = "ability_speed_boost"
abilityModifier.stat = "speed"
expect("ability modifier source is accepted", PetStatModifiersData.validateModifier(abilityModifier))

local unknownField = table.clone(validModifier)
unknownField.ownerUserId = 123
local unknownFieldValid, unknownFieldStatus = PetStatModifiersData.validateModifier(unknownField)
expect("unknown modifier fields are rejected", not unknownFieldValid and unknownFieldStatus == "UNKNOWN_MODIFIER_FIELD")

local badStat = table.clone(validModifier)
badStat.stat = "mana"
expect("unknown stat is rejected", not PetStatModifiersData.validateModifier(badStat))

local badSource = table.clone(validModifier)
badSource.sourceType = "client"
expect("unknown source type is rejected", not PetStatModifiersData.validateModifier(badSource))

local badOperation = table.clone(validModifier)
badOperation.operation = "multiply"
expect("unknown operation is rejected", not PetStatModifiersData.validateModifier(badOperation))

local nanValue = table.clone(validModifier)
nanValue.value = 0 / 0
expect("NaN modifier value is rejected", not PetStatModifiersData.validateModifier(nanValue))

local infiniteValue = table.clone(validModifier)
infiniteValue.value = math.huge
expect("infinite modifier value is rejected", not PetStatModifiersData.validateModifier(infiniteValue))

local negativeModifier = table.clone(validModifier)
negativeModifier.value = -5
expect("negative modifier values are retained for future penalty rules", PetStatModifiersData.validateModifier(negativeModifier))

local validList = {
	validModifier,
	skillModifier,
	abilityModifier,
}
local validListResult, validListStatus = PetStatModifiersData.validateList(validList)
expect("mixed modifier list is accepted", validListResult and validListStatus == "VALID")

local duplicateList = {
	validModifier,
	table.clone(validModifier),
}
local duplicateResult, duplicateStatus = PetStatModifiersData.validateList(duplicateList)
expect("duplicate modifier IDs are rejected", not duplicateResult and duplicateStatus == "DUPLICATE_MODIFIER_ID")

local sparseList = {
	[1] = validModifier,
	[3] = skillModifier,
}
local sparseResult = PetStatModifiersData.validateList(sparseList)
expect("sparse modifier lists are rejected", not sparseResult)

local invalidListKey = {
	validModifier,
}
invalidListKey.extra = skillModifier
expect("non-array modifier list keys are rejected", not PetStatModifiersData.validateList(invalidListKey))

local cloned, cloneReason = PetStatModifiersData.cloneList(validList)
assert(cloned ~= nil, tostring(cloneReason))
cloned[1].value = 999
expect("cloned modifier list does not mutate source", validList[1].value == 12)

local nilClone, nilCloneReason = PetStatModifiersData.cloneList(nil)
expect("nil modifier list clone fails safely", nilClone == nil and nilCloneReason == "INVALID_MODIFIER_LIST")

print("[PetKingdoms Test] PetStatModifiersData smoke tests completed.")
