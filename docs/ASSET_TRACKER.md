# Pet Kingdoms — Asset Tracker

> Status: planning inventory. No production assets are currently marked DONE.

## Acceptance rule

A concept image is a visual reference, not a shippable Roblox asset. Mark an item DONE only after its source asset is in the repository, its provenance/license is documented, and it has been imported and verified in Roblox Studio.

## Pets — MVP target: 20

| Pet | Biome / theme | Concept | Model | Rig | Animations | Studio check |
|---|---|---|---|---|---|---|
| Bunny | Green Valley | Planned | REAL CREATOR STORE MESH CANDIDATE INTEGRATED (Asset 92070521355583; 3,050 tris / 5 MeshParts); Studio visual review pending | STATIC IMPORTED MESH; RIG NOT YET DONE | FOLLOW SUPPORT INTEGRATED; CUSTOM MESH ANIMATIONS NOT DONE | THIRD-PARTY ASSET SETTING + STUDIO CHECK PENDING |
| Green Slime | Green Valley | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Forest Cat | Green Valley | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Leaf Fox | Green Valley | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Ice Bunny | Frostpeak | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Snow Wolf | Frostpeak | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Frost Owl | Frostpeak | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Crystal Bear | Frostpeak | Planned | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 09 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 10 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 11 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 12 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 13 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 14 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 15 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 16 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 17 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 18 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 19 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |
| Pet 20 | TBD | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED | NOT STARTED |

A real Creator Store Bunny MeshPart model (asset 92070521355583) is now the server spawn source instead of the procedural Part blockout. It is integrated through AssetService:LoadAssetAsync and a safe loader; it is currently an unrigged static mesh candidate. Third-party asset loading must be enabled in Studio, then import, appearance, scale, pivot, and follow must be tested. Do not mark production art DONE until these checks pass. The server pet collection backend now grants a starter Bunny and persists owned/equipped IDs (runtime DataStore verification pending). Equipped Bunny models now replicate from the server and bind to the local follow controller; Studio lifecycle verification is pending. The eight named pets above are the current working list from project discussions. Confirm them against the complete original specification before treating the roster as final.

## Environment kits

| Asset group | Target use | Status |
|---|---|---|
| Green Valley terrain and island edges | Meadow and biome routes | NOT STARTED |
| Green Valley trees, foliage, flowers | Meadow / Deep Forest / Wildflower Hills | NOT STARTED |
| River, waterfall, creek props | Crystal Creek | NOT STARTED |
| Ancient ruins and puzzle props | Ancient Grove | NOT STARTED |
| Modular paths and bridges | Green Valley and island connections | NOT STARTED |
| Home-island terrain kit | Personal kingdom | BLOCKOUT CODE ONLY — production art NOT STARTED |
| Main House, Pet House | Starter Island | RUNTIME BLOCKOUT MODELS ONLY — production art NOT STARTED |
| Stone Path, Garden Lantern, Flower Bed, Wooden Fence | Starter Island decor | RUNTIME BLOCKOUT MODELS ONLY — production art NOT STARTED |
| Farm, Workshop, Laboratory, Market, Garden | Starter Island | NOT STARTED |
| Resource nodes: wood, stone, berries, crystals | Gathering and production | NOT STARTED |

## UI assets

| Asset group | Status |
|---|---|
| Core navigation and HUD | NOT STARTED |
| Pet collection cards and silhouettes | CODE-BUILT FIRST-PASS UI; ART POLISH AND STUDIO CHECK PENDING |
| Pet collection data backend | SERVER MODULE + DATASTORE PROTOTYPE COMMITTED; STUDIO VERIFICATION PENDING |
| Pet collection UI | RUSSIAN CLIENT UI + SEARCH/PREVIEW/EQUIP CONTROLS COMMITTED; STUDIO/DEVICE CHECK PENDING |
| Equipped pet world runtime | SERVER REPLICATION + CLIENT FOLLOW BINDING COMMITTED; STUDIO LIFECYCLE CHECK PENDING |
| Pet details / progression panels | NOT STARTED |
| Building catalogue and placement controls | NOT STARTED |
| Quest and reward panels | NOT STARTED |
| Mobile control layout | NOT STARTED |

## External asset provenance

| Asset | Creator Store ID | Creator | Technical listing data | Runtime status |
|---|---:|---|---|---|
| Bunny candidate | `92070521355583` | `@letscreate19` | 3,050 triangles, 4,713 vertices, 5 MeshParts, 1 Decal | Integrated; third-party setting and Studio visual check pending |


For every non-original asset, record:
- Exact asset URL or Roblox asset ID.
- Creator / publisher.
- License and permitted use.
- Required attribution.
- Modifications made.
- Date reviewed.

Do not import an asset if its rights or source cannot be established.
