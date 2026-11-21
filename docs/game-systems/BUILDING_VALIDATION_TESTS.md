# Building Placement Validation — Test Plan

 > The validator is a server-side pure decision module. A Studio-only smoke-test script is committed at `src/ServerScriptService/Tests/PlacementValidatorTests.server.lua`, with grid helper checks in `src/ServerScriptService/Tests/GridMathTests.server.lua`. These are acceptance tests; they have not yet been executed in Roblox Studio.

## Setup

Use the server catalog and a test island:
- ownerUserId: 1001
- bounds: 10 × 10 cells
- buildings: empty
- test catalog entry: main_house (3 × 3; rotations 0/90/180/270)

## Required cases

| Case | Input / setup | Expected result |
|---|---|---|
| Valid initial placement | main_house at (0, 0), rotation 0 | VALID |
| Exact boundary fit | 3 × 3 building at (7, 7) | VALID |
| Out of bounds | 3 × 3 building at (8, 7) | OUT_OF_BOUNDS |
| Negative coordinate | x = -1 | OUT_OF_BOUNDS |
| Fractional coordinate | x = 1.5 | INVALID_REQUEST |
| Unsupported rotation | rotation = 45 | ROTATION_NOT_ALLOWED |
| Quarter-turn | 3 × 3 at rotation 90 | VALID, footprint 3 × 3 |
| Overlap | second 3 × 3 at (2, 2) when first is at (0, 0) | FOOTPRINT_OVERLAP |
| Edge adjacency | second 3 × 3 at (3, 0) | VALID |
| Wrong owner | playerUserId differs from island.ownerUserId | INVALID_OR_UNOWNED_ISLAND |
| Unknown catalog ID | catalogId not in server catalog | UNKNOWN_BUILDING |
| Move existing building | same instanceId, same catalogId; ignore its old footprint | VALID if new cells are free |
| Spoofed move target | unknown instanceId | MOVE_TARGET_NOT_FOUND |
| Malformed existing state | invalid saved rotation or coordinates, including the record being moved | ISLAND_STATE_INVALID |
| Locked catalog item | item is not default-unlocked and island has no unlock flag | BUILDING_LOCKED |
| Rotated rectangular footprint | unlocked 2 × 3 item at 90 degrees | VALID, footprint 3 × 2 |
| Duplicate instance IDs | two saved records share an instanceId | ISLAND_STATE_INVALID |
| Non-finite coordinate | x = NaN | INVALID_REQUEST |

## Security review

- Client cannot supply footprint width/depth.
- Client cannot supply price or refund amount.
- Client cannot choose island owner.
- Server resolves catalog definition and existing building records.
- Validator does not charge resources or mutate state; do not expose it as a trusted client-side API.

## Remaining integration work

- Add a server transaction service that calls this validator.
- Add server-owned currency/resource charging and rollback-safe mutation.
- Add remotes with rate limits and request validation.
- Add idempotency to prevent duplicate placement charges on retries.
- Add save/load and recovery only after the transaction behavior is established.
- Execute both Studio smoke-test scripts and record their Output results.
- Execute these cases in an automated Luau test runner when CI/toolchain is established.


## Island profile validation

Studio smoke test: `src/ServerScriptService/Tests/IslandDataTests.server.lua`.

Coverage:
- Profile creation rejects invalid owner IDs and bounds.
- Empty profile validates for its owner.
- Owner mismatch is rejected.
- Valid building records are accepted.
- Overlapping saved buildings are rejected.
- Duplicate building IDs are rejected.
- Unsupported schema versions are rejected.

The helper is pure with respect to persistence: it does not call DataStoreService, save data, or spawn Instances. Studio execution is still pending.
