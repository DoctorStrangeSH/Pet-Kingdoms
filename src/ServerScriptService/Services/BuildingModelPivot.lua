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

export type FootprintFit = {
	fits: boolean,
	overhangX: number,
	overhangZ: number,
	expectedWidth: number,
	expectedDepth: number,
}

-- A small tolerance absorbs floating-point and tiny bevel/trim differences.
-- This is diagnostic only: oversized art is reported, never silently rescaled.
function BuildingModelPivot.checkFootprintFit(
	bounds: Bounds,
	footprintWidth: number,
	footprintDepth: number,
	cellSize: number,
	tolerance: number?
): FootprintFit?
	if type(footprintWidth) ~= "number" or footprintWidth <= 0
		or type(footprintDepth) ~= "number" or footprintDepth <= 0
		or type(cellSize) ~= "number" or cellSize <= 0
		or cellSize ~= cellSize or cellSize == math.huge or cellSize == -math.huge
	then
		return nil
	end

	local allowedOverhang = tolerance or cellSize * 0.05
	if type(allowedOverhang) ~= "number" or allowedOverhang < 0
		or allowedOverhang ~= allowedOverhang or allowedOverhang == math.huge
	then
		return nil
	end

	local expectedWidth = footprintWidth * cellSize
	local expectedDepth = footprintDepth * cellSize
	local overhangX = math.max(0, bounds.width - expectedWidth)
	local overhangZ = math.max(0, bounds.depth - expectedDepth)
	return {
		fits = overhangX <= allowedOverhang and overhangZ <= allowedOverhang,
		overhangX = overhangX,
		overhangZ = overhangZ,
		expectedWidth = expectedWidth,
		expectedDepth = expectedDepth,
	}
end

export type PhysicsPreparation = {
	partCount: number,
	anchoredCount: number,
	touchDisabledCount: number,
}

-- Imported templates may contain unanchored pieces or touch-enabled decoration.
-- Anchor every physical part before the model enters the live island, disable
-- touch events for predictable performance, and preserve CanCollide/CanQuery.
function BuildingModelPivot.prepareForWorld(model: Model): PhysicsPreparation
	local partCount = 0
	local anchoredCount = 0
	local touchDisabledCount = 0

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			partCount += 1
			if not descendant.Anchored then
				descendant.Anchored = true
				anchoredCount += 1
			end
			if descendant.CanTouch then
				descendant.CanTouch = false
				touchDisabledCount += 1
			end
		end
	end

	return {
		partCount = partCount,
		anchoredCount = anchoredCount,
		touchDisabledCount = touchDisabledCount,
	}
end

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
