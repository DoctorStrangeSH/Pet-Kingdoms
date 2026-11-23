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

-- Selection resolves against the authoritative owned list, not the filtered
-- subset, so a pet remains selected while hidden by Team/Favorites/search.
local selectedRecord, selectedId = PetCollectionQuery.ResolveSelection(owned, "pet-123")
expect("selection keeps the requested pet even when query filters would hide it", selectedId == "pet-123" and selectedRecord ~= nil and selectedRecord.petId == "pet-123")

local selectedIsFavorite = false
for _, record in ipairs(favorites) do
	if record.petId == "pet-123" then selectedIsFavorite = true break end
end
expect("fixture hides selected pet from Favorites filter", not selectedIsFavorite)
expect("selection remains stable when selected pet is hidden by Favorites", PetCollectionQuery.ResolveSelection(owned, selectedId) == selectedRecord)

local selectedIsEquipped = false
for _, record in ipairs(team) do
	if record.petId == "pet-123" then selectedIsEquipped = true break end
end
expect("fixture hides selected pet from Team filter", not selectedIsEquipped)
expect("selection remains stable when selected pet is hidden by Team", PetCollectionQuery.ResolveSelection(owned, selectedId) == selectedRecord)

local changedFavoriteOwned = {}
for _, record in ipairs(owned) do
	local copy = table.clone(record)
	if copy.petId == selectedId then copy.isFavorite = true end
	table.insert(changedFavoriteOwned, copy)
end
local selectedFavoriteResults = PetCollectionQuery.Build(changedFavoriteOwned, equipped, "", "favorites", "newest", normalizedNames)
local selectedAppearsAsFavorite = false
for _, record in ipairs(selectedFavoriteResults) do
	if record.petId == selectedId then selectedAppearsAsFavorite = true break end
end
expect("favorite update inserts selected pet into active Favorites filter", selectedAppearsAsFavorite)
expect("favorite update keeps selected identity", PetCollectionQuery.ResolveSelection(changedFavoriteOwned, selectedId) == changedFavoriteOwned[123])

local removedFavoriteOwned = {}
for _, record in ipairs(changedFavoriteOwned) do
	local copy = table.clone(record)
	if copy.petId == selectedId then copy.isFavorite = false end
	table.insert(removedFavoriteOwned, copy)
end
local removedFavoriteResults = PetCollectionQuery.Build(removedFavoriteOwned, equipped, "", "favorites", "newest", normalizedNames)
local selectedRemainsFavorite = false
for _, record in ipairs(removedFavoriteResults) do
	if record.petId == selectedId then selectedRemainsFavorite = true break end
end
expect("removing favorite removes selected pet from active Favorites filter", not selectedRemainsFavorite)
local _, afterFavoriteRemovalId = PetCollectionQuery.ResolveSelection(removedFavoriteOwned, selectedId)
expect("removing favorite does not clear selected pet identity", afterFavoriteRemovalId == selectedId)

local equippedAfterToggle = table.clone(equipped)
table.insert(equippedAfterToggle, selectedId)
local selectedTeamResults = PetCollectionQuery.Build(owned, equippedAfterToggle, "", "team", "newest", normalizedNames)
local selectedAppearsOnTeam = false
for _, record in ipairs(selectedTeamResults) do
	if record.petId == selectedId then selectedAppearsOnTeam = true break end
end
expect("equip update inserts selected pet into active Team filter", selectedAppearsOnTeam)

table.remove(equippedAfterToggle, table.find(equippedAfterToggle, selectedId))
local removedTeamResults = PetCollectionQuery.Build(owned, equippedAfterToggle, "", "team", "newest", normalizedNames)
local selectedRemainsOnTeam = false
for _, record in ipairs(removedTeamResults) do
	if record.petId == selectedId then selectedRemainsOnTeam = true break end
end
expect("unequip update removes selected pet from active Team filter", not selectedRemainsOnTeam)
local _, afterUnequipId = PetCollectionQuery.ResolveSelection(owned, selectedId)
expect("unequip update does not clear selected pet identity", afterUnequipId == selectedId)

local fallbackRecord, fallbackId = PetCollectionQuery.ResolveSelection(owned, "pet-no-longer-owned")
expect("selection falls back only when the pet is no longer owned", fallbackId == owned[1].petId and fallbackRecord == owned[1])

local emptySelection, emptySelectionId = PetCollectionQuery.ResolveSelection({}, "pet-123")
expect("empty collection clears stale selection", emptySelection == nil and emptySelectionId == nil)

local cacheHasLocalizedBunny = normalizedNames.bunny == string.lower("Зайчик")
expect("species display names are cached", cacheHasLocalizedBunny)

print("[PetKingdoms Test] PetCollection query tests completed.")
