--!strict
-- Pure query/filter/sort regression tests for large pet collections.

local RunService = game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("RunPetKingdomsStudioTests") ~= true then
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetCollectionQuery = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetCollectionQuery"))

local function expect(name: string, condition: boolean)
	assert(condition, name .. " failed")
	print("[PetKingdoms Test] PASS:", name)
end

local owned = {}
local equipped = {}
for index = 1, 500 do
	local speciesId = if index % 3 == 0 then "bunny" elseif index % 3 == 1 then "fox" else "cat"
	table.insert(owned, {
		petId = string.format("pet-%03d", index),
		speciesId = speciesId,
		acquiredAt = math.floor(index / 5),
		bondLevel = (index % 8) + 1,
		bondXp = index % 100,
		isFavorite = index % 10 == 0,
		isLocked = index % 17 == 0,
	})
	if index % 4 == 0 then table.insert(equipped, string.format("pet-%03d", index)) end
end

local normalizedNames = {}
local allNewest = PetCollectionQuery.Build(owned, equipped, "", "all", "newest", normalizedNames)
expect("500 records remain available in all filter", #allNewest == 500)
expect("favorites sort before non-favorites", allNewest[1].isFavorite == true)
expect("newest sorting is deterministic", allNewest[1].acquiredAt >= allNewest[#allNewest].acquiredAt)

local team = PetCollectionQuery.Build(owned, equipped, "", "team", "newest", normalizedNames)
expect("team filter contains exactly equipped pets", #team == #equipped)
local equippedLookup = {}
for _, petId in ipairs(equipped) do equippedLookup[petId] = true end
local teamCorrect = true
for _, record in ipairs(team) do
	if not equippedLookup[record.petId] then teamCorrect = false break end
end
expect("team filter contains no unequipped pets", teamCorrect)

local favorites = PetCollectionQuery.Build(owned, equipped, "", "favorites", "newest", normalizedNames)
expect("favorite filter returns only favorites", #favorites == 50)
local favoriteCorrect = true
for _, record in ipairs(favorites) do
	if record.isFavorite ~= true then favoriteCorrect = false break end
end
expect("favorite filter has no false positives", favoriteCorrect)

local bunnySearch = PetCollectionQuery.Build(owned, equipped, "ЗАЙ", "all", "name", normalizedNames)
expect("search is case-insensitive and uses localized bunny name", #bunnySearch > 0)
local bunnyOnly = true
for _, record in ipairs(bunnySearch) do
	if record.speciesId ~= "bunny" then bunnyOnly = false break end
end
expect("localized bunny search returns only bunny records", bunnyOnly)

local noMatch = PetCollectionQuery.Build(owned, equipped, "no-such-pet", "all", "newest", normalizedNames)
expect("unmatched search returns empty results", #noMatch == 0)

local bond = PetCollectionQuery.Build(owned, equipped, "", "all", "bond", normalizedNames)
local bondSorted = true
for index = 2, #bond do
	local previous = bond[index - 1]
	local current = bond[index]
	if previous.isFavorite ~= current.isFavorite then
		if previous.isFavorite ~= true then bondSorted = false break end
	elseif (previous.bondLevel or 1) < (current.bondLevel or 1) then
		bondSorted = false
		break
	elseif (previous.bondLevel or 1) == (current.bondLevel or 1) and (previous.bondXp or 0) < (current.bondXp or 0) then
		bondSorted = false
		break
	end
end
expect("bond sort prioritizes favorites, level, and XP", bondSorted)

local empty = PetCollectionQuery.Build({}, {}, "", "all", "newest", normalizedNames)
expect("empty collection produces empty results", #empty == 0)

local cacheHasLocalizedBunny = normalizedNames.bunny == string.lower("Зайчик")
expect("species display names are cached", cacheHasLocalizedBunny)

print("[PetKingdoms Test] PetCollection query tests completed.")
