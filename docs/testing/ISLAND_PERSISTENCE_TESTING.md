# Island persistence testing

This checklist separates safe Studio contract tests from DataStore integration tests.

## 1. Safe Studio checks

1. Open the Pet Kingdoms place in Roblox Studio.
2. Start a local server test with **Test → Start** (or Play with server Output visible).
3. Watch the Server Output for `[PetKingdoms Test]` messages.
4. The pure data, wallet, economy, building-world and cooldown-rendering checks run in Studio and do not require live player data.
5. Confirm the island-world tests clean up their synthetic world models and restore any Workspace attributes they temporarily change.

## 2. DataStore round-trip test — dedicated test universe only

The `IslandStoreTests.server.lua` integration scenario writes synthetic profiles to the `PetKingdoms_Islands_v1` DataStore. It is deliberately disabled by default.

Only run it in a separate Roblox test universe/place that contains no production player saves:

1. Publish the test place to the dedicated test universe.
2. In that universe only, enable **Game Settings → Security → Enable Studio Access to API Services**.
3. In the test place's Workspace properties, set the boolean attribute `RunIslandStoreIntegrationTests = true`.
4. Start a Studio server test and inspect Server Output for the `IslandStore contract tests completed` message.
5. When finished, remove the attribute or set it to false.

Do not enable this flag in the production universe or in a local copy connected to production DataStores. The integration test intentionally uses a synthetic user key and must never target a real player's profile.

## 3. Manual player journey

After automated checks pass, test the complete flow with a dedicated test account:

1. Join a fresh island and note the resource HUD balances.
2. Gather one wood node and one stone node; confirm the HUD and reward toast update.
3. Build the pet house and one inexpensive decoration; note the exact remaining balances.
4. Expand the island if the test account has the required progression/unlock.
5. Leave the server and rejoin.
6. Confirm the buildings return at the same world positions and rotations, the expanded bounds remain, and resource balances are unchanged.
7. If a resource node was recently gathered, confirm its prompt remains disabled until the saved `AvailableAt` time, then becomes available again.
8. Repeat with a second rejoin to catch one-time migration or session-generation problems.

## Expected persistence contract

- Building records: catalog ID, instance ID, grid X/Z and rotation.
- Resource wallet: wood, stone, gold and gems.
- Island expansion level and bounds.
- Resource-node cooldown timestamps.
- Building operation receipts used to prevent duplicate mutations.
- Profile revision and DataStore session generation.

A successful Rojo/GitHub Actions build proves the place file can be assembled; it does not replace Studio execution or a real leave/rejoin test.
