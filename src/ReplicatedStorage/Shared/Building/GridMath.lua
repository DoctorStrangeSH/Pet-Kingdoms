--!strict
-- Pure grid/footprint helpers. No Instances, remotes, or client authority.
-- Coordinates represent the minimum X/Z cell of a footprint.

local GridMath = {}

export type Footprint = {
	x: number,
	z: number,
	width: number,
	depth: number,
}

local function isInteger(value: number): boolean
	return value == value
		and value ~= math.huge
		and value ~= -math.huge
		and value == math.floor(value)
end

function GridMath.snapWorldToGrid(worldCoordinate: number, gridSize: number, origin: number?): number?
	if not isInteger(gridSize) or gridSize <= 0
		or type(worldCoordinate) ~= "number"
		or worldCoordinate ~= worldCoordinate
		or worldCoordinate == math.huge
		or worldCoordinate == -math.huge
	then
		return nil
	end

	local gridOrigin = origin or 0
	if type(gridOrigin) ~= "number"
		or gridOrigin ~= gridOrigin
		or gridOrigin == math.huge
		or gridOrigin == -math.huge
	then
		return nil
	end
	local cell = math.floor(((worldCoordinate - gridOrigin) / gridSize) + 0.5)
	return gridOrigin + cell * gridSize
end

function GridMath.getRotatedFootprint(width: number, depth: number, rotationDegrees: number): (number?, number?)
	if width <= 0 or depth <= 0 or not isInteger(width) or not isInteger(depth) then
		return nil, nil
	end

	local normalizedRotation = rotationDegrees % 360
	if normalizedRotation == 0 or normalizedRotation == 180 then
		return width, depth
	elseif normalizedRotation == 90 or normalizedRotation == 270 then
		return depth, width
	end

	return nil, nil
end

function GridMath.isWithinBounds(footprint: Footprint, boundsWidth: number, boundsDepth: number): boolean
	if not isInteger(footprint.x) or not isInteger(footprint.z)
		or not isInteger(footprint.width) or not isInteger(footprint.depth)
		or footprint.width <= 0 or footprint.depth <= 0
		or not isInteger(boundsWidth) or not isInteger(boundsDepth)
		or boundsWidth <= 0 or boundsDepth <= 0
	then
		return false
	end

	return footprint.x >= 0
		and footprint.z >= 0
		and footprint.x + footprint.width <= boundsWidth
		and footprint.z + footprint.depth <= boundsDepth
end

function GridMath.footprintsOverlap(a: Footprint, b: Footprint): boolean
	local aRight = a.x + a.width
	local aBack = a.z + a.depth
	local bRight = b.x + b.width
	local bBack = b.z + b.depth

	return a.x < bRight
		and aRight > b.x
		and a.z < bBack
		and aBack > b.z
end

return GridMath
