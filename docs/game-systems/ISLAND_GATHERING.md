# Island Gathering — MVP Resource Nodes

> Status: server-spawned personal-island wood/stone nodes and server-authoritative ProximityPrompt rewards are implemented. Live Studio playtest and UI feedback verification remain pending.

## Current MVP node set

Each spawned personal island receives four resource nodes inside its own `ResourceNodes` folder:
- 2 Wood nodes: each grants 3 Wood.
- 2 Stone nodes: each grants 2 Stone.
- Each node becomes unavailable after a successful gather and respawns after 60 seconds.

These quantities and timer reuse the provisional baseline in the project specification. They are not final economy balance.

## Interaction

- Uses Roblox ProximityPrompt; keyboard E, gamepad ButtonX, and Roblox touch prompt are supported.
- Resource nodes show a floating label with the resource name and exact reward (+3 wood / +2 stone). The prompt explicitly says Срубить дерево or Добыть камень.
- A first-gather hint appears in the resource HUD while the player's wood balance is zero.
- Prompts are server-observed through ProximityPromptService.
- The server validates resource ID, integer reward, player ownership, node ancestry, island ownership, character root, and interaction distance.
- Reward values are node attributes assigned by server-owned island generation, never accepted from the client.
- A node is marked busy before the grant call to prevent duplicate concurrent awards.
- The node is hidden and its prompt disabled only after a successful wallet grant.
- If the wallet grant fails, the node remains available.
- The node returns after 60 seconds; cooldown is in-memory and resets if the server shuts down.

## Wallet integration

Rewards call `IslandResourceService.grant`, which mutates the server-owned profile and marks it dirty. DataStore persistence remains handled by the existing autosave/session lifecycle.

## Explicit limitations

- Nodes currently use temporary procedural blockout geometry, not approved production art. Floating markers improve discovery but do not replace final tree/ore meshes.
- There is no inventory HUD/toast or gathering animation yet.
- No tools, stamina, skill checks, node tiers, or biome-specific drops.
- Respawn timers are server-memory timers and are not persisted across server shutdown.
- No Studio/live DataStore playtest has been recorded yet.

## Studio verification checklist

- [ ] Join with two players; verify each sees and can gather only their own island's nodes.
- [ ] Gather one Wood node: Wood increases by exactly 3 and prompt disables.
- [ ] Gather one Stone node: Stone increases by exactly 2 and prompt disables.
- [ ] Attempt repeated/rapid triggers; only one reward is granted per node cooldown.
- [ ] Attempt to trigger another player's node; no reward is granted.
- [ ] Wait 60 seconds; node becomes visible and interactable again.
- [ ] Leave/rejoin; balances persist after autosave.
- [ ] Simulate non-writable session; reward is rejected and node remains available.
- [ ] Test E and gamepad interaction; verify prompt readability on mobile touch devices.


## Gathering discoverability pass (2026-11-22)

- [x] Add readable floating resource markers above each active wood/stone node, showing exact resource yield.
- [x] Make the wood prompt explicitly say Срубить дерево and show the wood reward; stone prompt shows its reward too.
- [x] Hide floating markers while the node is on cooldown and restore them on respawn.
- [x] Show a HUD hint directing new players to a wood node while their wood balance is zero.
- [ ] Verify marker distance, readability, ProximityPrompt touch behavior, and first-gather flow in Roblox Studio/mobile.
- [ ] Replace procedural resource blockouts with approved production art assets.

## Replaceable resource art templates (2026-11-22)

- The renderer now checks `ServerStorage/ResourceNodeModels/wood` and `ServerStorage/ResourceNodeModels/stone` for approved **Model** objects. These are optional: if absent, existing procedural tree/ore blockouts remain functional.
- A resource Model must be authored with a sensible pivot at the ground-level centre of the node. The renderer clones it at the node's canonical grid location, anchors all BaseParts, removes all LuaSourceContainer descendants, and removes template-provided ProximityPrompts and BillboardGuis.
- All gameplay prompts are **created by the server** on a separate invisible `GatherAnchor`. The server owns reward value, resource ID, distance validation and cooldown regardless of asset contents. The existing resource marker attaches to the custom model's PrimaryPart (or first BasePart).
- Transparency of each visual BasePart is recorded in `GatherBaseTransparency` and restored after cooldown, so translucent mesh details and the invisible prompt anchor stay transparent after node respawn.
- No third-party assets have been imported or approved. Keep visual asset provenance and studio review in `docs/ASSET_TRACKER.md`; do not put executable code inside source models.
- A Studio-only world integration test constructs a temporary resource Model, checks that the scripted payload is stripped and that the trusted prompt anchor exists, then removes the fixture. Studio execution is still pending.

## Prompt origin and rejoin checks (2026-11-22)

- On gather, the server accepts only its named `GatherPrompt` directly under the trusted `GatherAnchor` inside a node Model belonging to `ResourceNodes`. Other prompts are ignored.
- Studio world integration tests now model a persisted cooldown on a second player's island and assert the hidden prompt, transparent anchor and saved custom-mesh base transparency. Actual post-delay respawn still requires runtime testing.

## Repeatable resource visibility tests (2026-11-22)

The shared `ResourceNodeVisibility.setVisible` now owns cooldown hide/restore behavior and is covered by a Studio-only test fixture. The fixture checks alpha-preserving restoration of a partially transparent model, permanently invisible `GatherAnchor`, disabled prompt/marker during cooldown, re-enabled cues on respawn, and a second hide/restore cycle. Run in Studio before claiming resource respawn behavior fully verified.
