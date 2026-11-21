# Pet Kingdoms — Asset Tracker

> Status: planning inventory. No production assets are currently marked DONE.

## Acceptance rule

A concept image is a visual reference, not a shippable Roblox asset. Mark an item DONE only after its source asset is in the repository, its provenance/license is documented, and it has been imported and verified in Roblox Studio.

## Pets — MVP target: 20

| Pet | Biome / theme | Concept | Model | Rig | Animations | Studio check |
|---|---|---|---|---|---|---|
| Bunny | Green Valley | Planned | ORIGINAL PROJECT MESH COMMITTED: 15,332 vertices / 30,194 triangles / 13 mesh objects / 9 materials; Studio import + art review pending | BLENDER RIG SCRIPT COMMITTED; SOURCE/SYNTAX CI PASS; FULL BLENDER BUILD CI PENDING | IDLE/WALK/HOP/HAPPY ACTIONS DEFINED IN SCRIPT; NOT GENERATED / NOT VERIFIED | STUDIO IMPORT / PUBLISH / VISUAL CHECK PENDING |
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

The unsuitable Creator Store Bunny (asset 92070521355583) is REJECTED and removed from the catalog. An original project-owned OBJ mesh and MTL were committed under `assets/pets/bunny/`. A Blender rig/export script and RIG_PIPELINE.md were added; the script defines a 10-bone first-pass rig and Idle/Walk/Hop/Happy actions. GitHub Actions source validation and Python syntax check pass (run #1). A full Blender build is now running in GitHub Actions; generated .blend/.fbx will be attached as a 30-day artifact if successful. Studio import and visual approval remain pending. Studio import, deformation review, animation review, and runtime publishing remain pending. The runtime catalog intentionally has no asset ID until the project-owned mesh is imported and published. Do not mark production art DONE yet. The server pet collection backend now grants a starter Bunny and persists owned/equipped IDs (runtime DataStore verification pending). Equipped Bunny models now replicate from the server and bind to the local follow controller; Studio lifecycle verification is pending. The eight named pets above are the current working list from project discussions. Confirm them against the complete original specification before treating the roster as final.

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
| Rejected Bunny candidate | `92070521355583` | `@letscreate19` | 3,050 triangles, 5 MeshParts | REJECTED — not used in project |
| Original Bunny mesh | Project-owned | Pet Kingdoms | 15,332 vertices, 30,194 triangles, 13 objects, 9 material groups | OBJ/MTL committed; Studio import and visual approval pending |


For every non-original asset, record:
- Exact asset URL or Roblox asset ID.
- Creator / publisher.
- License and permitted use.
- Required attribution.
- Modifications made.
- Date reviewed.

Do not import an asset if its rights or source cannot be established.
