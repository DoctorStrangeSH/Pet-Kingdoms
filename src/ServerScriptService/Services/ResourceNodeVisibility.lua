--!strict
-- Restores source visual alpha after a resource cooldown without revealing
-- the invisible server-owned gathering anchor or making imported art collidable.
local ResourceNodeVisibility = {}

function ResourceNodeVisibility.setVisible(node: Model, visible: boolean)
	for _, descendant in ipairs(node:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local base = descendant:GetAttribute("GatherBaseTransparency")
			if type(base) ~= "number" then
				base = descendant.Transparency
				descendant:SetAttribute("GatherBaseTransparency", base)
			end
			descendant.Transparency = if visible then base else 1
			descendant.CanCollide = false
			descendant.CanTouch = false
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("BillboardGui") then
			descendant.Enabled = visible
		end
	end
end

return ResourceNodeVisibility
