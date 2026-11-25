--!strict
-- Pure geometry helpers for the temporary construction camera.
local ConstructionCameraMath = {}

function ConstructionCameraMath.clampPan(offset: Vector2, halfBounds: Vector2, margin: number): Vector2
	local safeMargin = math.max(0, margin)
	local maxX = math.max(0, halfBounds.X - safeMargin)
	local maxZ = math.max(0, halfBounds.Y - safeMargin)
	return Vector2.new(
		math.clamp(offset.X, -maxX, maxX),
		math.clamp(offset.Y, -maxZ, maxZ)
	)
end

function ConstructionCameraMath.zoomDistance(distance: number, wheelDelta: number, minimum: number, maximum: number): number
	if distance ~= distance or distance <= 0 then distance = minimum end
	local nextDistance = distance * math.pow(0.88, wheelDelta)
	return math.clamp(nextDistance, minimum, maximum)
end

function ConstructionCameraMath.getCameraCFrame(
	grassCFrame: CFrame,
	grassHeight: number,
	targetOffset: Vector2,
	distance: number,
	yaw: number,
	pitch: number
): CFrame
	local target = grassCFrame:PointToWorldSpace(Vector3.new(targetOffset.X, grassHeight * 0.5 + 2, targetOffset.Y))
	local horizontal = math.cos(pitch)
	local cameraOffset = Vector3.new(
		math.sin(yaw) * horizontal,
		math.sin(pitch),
		math.cos(yaw) * horizontal
	) * distance
	return CFrame.lookAt(target + cameraOffset, target)
end

function ConstructionCameraMath.getPanDelta(
	screenDelta: Vector2,
	distance: number,
	viewportHeight: number,
	fieldOfView: number,
	yaw: number,
	grassCFrame: CFrame
): Vector2
	if viewportHeight <= 0 then return Vector2.zero end
	local worldPerPixel = (2 * distance * math.tan(math.rad(fieldOfView) * 0.5)) / viewportHeight
	local right = Vector3.new(math.cos(yaw), 0, -math.sin(yaw))
	local forward = Vector3.new(-math.sin(yaw), 0, -math.cos(yaw))
	local worldDelta = right * (-screenDelta.X * worldPerPixel) + forward * (screenDelta.Y * worldPerPixel)
	local localDelta = grassCFrame:VectorToObjectSpace(worldDelta)
	return Vector2.new(localDelta.X, localDelta.Z)
end

return table.freeze(ConstructionCameraMath)
