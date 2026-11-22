--!strict
-- Kingdom Bond is currently a visible island-development track.
-- Score is derived from the saved layout, so it cannot be farmed by rebuild loops.
-- Thresholds are provisional and must be playtested before economy/progression approval.
local KingdomBond = {}

KingdomBond.POINTS_PER_BUILDING = 10
KingdomBond.STAGES = {
	{ id = "quiet", name = "Тихий остров", minimumPoints = 0 },
	{ id = "cozy", name = "Уютное королевство", minimumPoints = 10 },
	{ id = "blooming", name = "Цветущее королевство", minimumPoints = 30 },
	{ id = "thriving", name = "Процветающее королевство", minimumPoints = 60 },
}

function KingdomBond.calculate(profile: any): any
	if type(profile) ~= "table" or type(profile.buildings) ~= "table" then
		return nil
	end
	local count = 0
	for _, record in ipairs(profile.buildings) do
		if type(record) == "table" and type(record.catalogId) == "string"
			and record.catalogId ~= "main_house" then
			count += 1
		end
	end
	local points = count * KingdomBond.POINTS_PER_BUILDING
	local stage = KingdomBond.STAGES[1]
	local nextStage = nil
	for index, candidate in ipairs(KingdomBond.STAGES) do
		if points >= candidate.minimumPoints then
			stage = candidate
			nextStage = KingdomBond.STAGES[index + 1]
		else
			break
		end
	end
	return {
		points = points,
		buildingCount = count,
		stageId = stage.id,
		stageName = stage.name,
		nextStagePoints = if nextStage then nextStage.minimumPoints else nil,
	}
end

return KingdomBond
