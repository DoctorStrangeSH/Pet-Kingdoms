--!strict
-- Normalizes imported building models so their pivot is the center of the
-- footprint at ground level. Placement code can then target the same point
-- used by the grid preview, regardless of how an asset was authored.
local BuildingModelPivot = {}

export type Bounds = {
	width: number,
	height: number,
	depth: number,
}

function BuildingModelPivot.normalizeToGroundCenter(model: Model): Bounds?
	-- Cloned templates are intentionally normalized before parenting so their
	-- pivot is correct before the placement transform is applied.
	local currentPivot = model:GetPivot()
	local boundsCFrame, boundsSize = model:GetBoundingBox()
	if boundsSize.X <= 0 or boundsSize.Y <= 0 or boundsSize.Z <= 0 then
		return nil
	end

	local groundCenterWorld = boundsCFrame.Position - boundsCFrame.UpVector * (boundsSize.Y / 2)
	local groundCenterLocal = currentPivot:PointToObjectSpace(groundCenterWorld)
	model:PivotTo(currentPivot * CFrame.new(groundCenterLocal))

	return {
		width = boundsSize.X,
		height = boundsSize.Y,
		depth = boundsSize.Z,
	}
end

return BuildingModelPivot
