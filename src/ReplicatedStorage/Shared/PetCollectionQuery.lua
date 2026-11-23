--!strict
-- Pure collection filtering and sorting. Keeps query behavior deterministic
-- and independently testable without constructing Roblox UI instances.

local PetCollectionQuery = {}

export type PetRecord = {
	petId: string,
	speciesId: string,
	acquiredAt: number,
	bondXp: number?,
	bondLevel: number?,
	isLocked: boolean?,
	isFavorite: boolean?,
}

export type FilterMode = "all" | "team" | "favorites"
export type SortMode = "newest" | "name" | "bond"

local function getSearchName(
	speciesId: string,
	normalizedNames: { [string]: string }
): string
	local cached = normalizedNames[speciesId]
	if cached then return cached end
	local displayName = if speciesId == "bunny" then "Зайчик" else speciesId
	local normalized = string.lower(displayName)
	normalizedNames[speciesId] = normalized
	return normalized
end

function PetCollectionQuery.Build(
	owned: { PetRecord },
	equipped: { string },
	query: string,
	filterMode: FilterMode,
	sortMode: SortMode,
	normalizedNames: { [string]: string }
): { PetRecord }
	local normalizedQuery = string.lower(query)
	local equippedSet: { [string]: boolean } = {}
	for _, petId in ipairs(equipped) do
		equippedSet[petId] = true
	end

	local searchNames: { [string]: string } = {}
	local filtered: { PetRecord } = {}
	for _, record in ipairs(owned) do
		local searchName = getSearchName(record.speciesId, normalizedNames)
		searchNames[record.petId] = searchName
		local matchesSearch = normalizedQuery == ""
			or string.find(searchName, normalizedQuery, 1, true) ~= nil
		local matchesFilter = filterMode == "all"
			or (filterMode == "team" and equippedSet[record.petId] == true)
			or (filterMode == "favorites" and record.isFavorite == true)
		if matchesSearch and matchesFilter then
			table.insert(filtered, record)
		end
	end

	table.sort(filtered, function(a, b)
		if (a.isFavorite == true) ~= (b.isFavorite == true) then
			return a.isFavorite == true
		end
		if sortMode == "name" then
			local aName = searchNames[a.petId] or getSearchName(a.speciesId, normalizedNames)
			local bName = searchNames[b.petId] or getSearchName(b.speciesId, normalizedNames)
			if aName ~= bName then return aName < bName end
		elseif sortMode == "bond" then
			local aBond = a.bondLevel or 1
			local bBond = b.bondLevel or 1
			if aBond ~= bBond then return aBond > bBond end
			local aXp = a.bondXp or 0
			local bXp = b.bondXp or 0
			if aXp ~= bXp then return aXp > bXp end
		end
		if a.acquiredAt ~= b.acquiredAt then return a.acquiredAt > b.acquiredAt end
		return a.petId < b.petId
	end)

	return filtered
end

return table.freeze(PetCollectionQuery)
