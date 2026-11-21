# Temporary Starter Building Blockouts

> Status: runtime fallback Models are implemented for `main_house` and `pet_house`. These are functional placeholders only, not production art.

## Why this exists

The placement transaction previously required a Model under `ServerStorage/BuildingModels/<catalogId>`. With no imported Models, a valid first-time build would be rejected. The fallback path lets the building loop be exercised in Studio before final meshes are authored.

## Resolution order

1. If `ServerStorage/BuildingModels/<catalogId>` exists and is a Model, clone that approved template.
2. Otherwise, create a temporary model from simple Parts for the two starter IDs.
3. Unknown IDs still fail; the fallback does not bypass the server catalog.

## Current fallback shapes

- `main_house`: foundation, warm walls, purple roof, door, two blue windows.
- `pet_house`: warm wooden body, blue roof, door, small sign.

Fallback Models carry `IsFallbackBlockout = true`. They are server-created, anchored, and use the catalog footprint/cell size. They are deliberately simple and must not be treated as finished visual assets.

## Replacing with production art

Import a Model under `ServerStorage/BuildingModels` using the exact catalog ID. Author its PrimaryPart/pivot at the ground-level center of its footprint, test all four rotations, and verify collision geometry. The production template automatically takes precedence over the fallback without changing saved profile records.

## Acceptance

- A new profile can place both starter buildings without manually importing Models.
- Placed fallback Models appear on the island and survive rejoin through profile restoration.
- A supplied production Model takes precedence over its fallback.
- Unknown catalog IDs remain rejected.
- Fallbacks are never marked as production assets in `ASSET_TRACKER.md`.
