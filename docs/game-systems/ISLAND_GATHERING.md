# Island Gathering — MVP Resource Nodes

> Status: server-spawned personal-island wood/stone nodes and server-authoritative ProximityPrompt rewards are implemented. Live Studio playtest and UI feedback verification remain pending.

## Current MVP node set

Each spawned personal island receives four resource nodes inside its own `ResourceNodes` folder:
- 2 Wood nodes: each grants 3 Wood.
- 2 Stone nodes: each grants 2 Stone.
- Each node becomes unavailable after a successful gather and respawns after 60 seconds.

These quantities and timer reuse the provisional baseline in the project specification. They are not final economy balance.

## Interaction

- Uses Roblox ProximityPrompt; keyboard E and gamepad ButtonX are configured.
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

- Nodes currently use temporary procedural blockout geometry, not approved production art.
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
