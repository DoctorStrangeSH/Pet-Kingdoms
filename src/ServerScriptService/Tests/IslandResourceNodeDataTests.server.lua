--!strict
-- Studio-only contract tests for persistent island resource node cooldowns.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local services = script.Parent.Parent:WaitForChild("Services")
local NodeData = require(services:WaitForChild("IslandResourceNodeData"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local now = os.time()
local states = {}
local firstStates, firstAvailableAt, firstCode = NodeData.recordGather(states, "WoodNode_A", now)
expect("first gathering records cooldown", firstStates ~= nil and firstCode == "RECORDED"
	and firstAvailableAt == now + 60)
states = firstStates or {}

local blockedStates, blockedAt, blockedCode = NodeData.recordGather(states, "WoodNode_A", now + 30)
expect("node cannot be gathered during cooldown", blockedStates == nil
	and blockedAt == now + 60 and blockedCode == "NODE_COOLDOWN")

local otherNodeStates, _, otherNodeCode = NodeData.recordGather(states, "StoneNode_A", now + 30)
expect("different resource nodes have independent cooldowns",
	otherNodeStates ~= nil and otherNodeCode == "RECORDED")

local recoveredStates, recoveredAt, recoveredCode = NodeData.recordGather(states, "WoodNode_A", now + 60)
expect("node can be gathered again after cooldown", recoveredStates ~= nil
	and recoveredCode == "RECORDED" and recoveredAt == now + 120)

local unknownStates, _, unknownCode = NodeData.recordGather(states, "GoldNode_A", now + 60)
expect("unknown node IDs are rejected", unknownStates == nil and unknownCode == "UNKNOWN_NODE")

local duplicateValid = NodeData.validate({
	{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = now, availableAt = now + 60 },
	{ nodeId = "WoodNode_A", resourceId = "wood", lastGatheredAt = now, availableAt = now + 60 },
})
expect("duplicate node state records are rejected", not duplicateValid)

local wrongResourceValid = NodeData.validate({
	{ nodeId = "WoodNode_A", resourceId = "stone", lastGatheredAt = now, availableAt = now + 60 },
})
expect("resource ID cannot be changed by saved node state", not wrongResourceValid)

local overlongCooldownValid = NodeData.validate({
	{ nodeId = "StoneNode_A", resourceId = "stone", lastGatheredAt = now, availableAt = now + 61 },
})
expect("cooldown longer than server policy is rejected", not overlongCooldownValid)

print("[PetKingdoms Test] IslandResourceNodeData tests completed.")
