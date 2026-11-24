# Pet collection persistence testing

This checklist separates safe Studio contract tests from DataStore integration tests. The collection uses the dedicated `PetKingdoms_PetCollections_v1` DataStore and a writer-generation token. It is separate from the island profile store.

## 1. Safe Studio contract checks

1. Open the Pet Kingdoms place in Roblox Studio.
2. Start a local server test with **Test → Start** and keep Server Output visible.
3. Confirm `PetCollectionDataTests.server.lua` and `PetCollectionSessionDataTests.server.lua` print their completion messages.
4. These tests exercise validation, collection mutations, receipts, equipped-pet constraints, and pure session fencing. They do not write DataStore records.

## 2. DataStore round-trip test — dedicated test universe only

`PetCollectionStoreTests.server.lua` writes a synthetic profile to `PetKingdoms_PetCollections_v1`. It is disabled by default.

Only run it in a separate Roblox test universe/place with no production player saves:

1. Publish the test place to the dedicated test universe.
2. In that universe only, enable **Game Settings → Security → Enable Studio Access to API Services**.
3. In the test place's Workspace properties, set the boolean attribute `RunPetCollectionStoreIntegrationTests = true`.
4. Start a Studio server test and inspect Server Output for `Pet collection DataStore integration completed`.
5. When finished, remove the attribute or set it to false.

The test first checks that its randomly generated synthetic key is empty. It then claims a collection session, reserves and grants a test pet, changes bond/XP/protection state, equips the pet, reloads the profile, and verifies that the full snapshot and acquisition receipt survive. It also claims a newer writer generation and verifies that the previous writer cannot overwrite it.

The test removes its synthetic key after success or assertion failure. If cleanup fails, the test fails explicitly. Never enable this flag in the production universe or run the test against production player data.

## 3. Manual player journey

After automated checks pass, test with a dedicated account in the test universe:

1. Join and confirm the starter Bunny appears in the collection and is equipped.
2. Acquire another pet through the real game flow when that flow is available; do not use a test grant in a normal player session.
3. Equip and unequip pets, then leave and rejoin. Confirm the same pet IDs and equipped order return.
4. Mark a pet as favorite and locked, then rejoin. Confirm both flags remain.
5. Interact with a pet and earn XP through normal gameplay; rejoin and confirm bond XP, bond level, XP and level remain.
6. Confirm a pending hatch/acquisition is not duplicated after a retry or reconnect.
7. Test a second server session and confirm a stale server cannot replace the latest collection.
8. Repeat on a second join to catch one-time migration and loading-order issues.

## Expected persistence contract

- Stable pet IDs, species, rarity and acquisition timestamps.
- Pet level and XP.
- Bond XP, bond level and last interaction timestamp.
- Favorite and lock flags.
- Equipped pet IDs and their order.
- Acquisition reservations and durable acquisition receipts.
- XP reward receipts and acknowledgement timestamps.
- Collection revision, session generation and session token.

A successful Rojo build proves only that the place file can be assembled. It does not execute Studio tests or prove DataStore behavior, pet spawning, UI state, or mobile interaction.
## 4. Client companion follow test — Studio only

`CompanionFollowControllerTests.client.lua` is a client-side smoke/regression test. It is disabled unless the Workspace boolean attribute `RunPetKingdomsStudioTests` is set to `true`.

1. Use a dedicated Roblox Studio test place. Do not enable test flags in the production universe.
2. In Workspace properties, add boolean attribute `RunPetKingdomsStudioTests = true`.
3. Start **Test → Start** with at least one client. Keep both Server Output and the selected client's Output visible.
4. Confirm the client Output reports the `CompanionFollowController smoke tests completed` message and PASS lines for formation slots, idle personality, player reactions, resource inspection, catch-up recovery, obstacle detour clearance, and ground alignment.
5. Remove the attribute or set it to false after testing.

The test creates and removes a temporary floor and wall in Workspace. It does not write DataStores or grant pets to a player. It validates a single wall detour fixture only; it does not replace the manual test around actual island buildings, fences, bridges, ramps, slopes, streaming and mobile performance.
