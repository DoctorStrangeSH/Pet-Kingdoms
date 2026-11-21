-- Pet Kingdoms — Roblox Studio Bunny import inspection
-- Usage: import bunny_rigged.fbx with the 3D Importer, select the resulting
-- Model in Explorer, then run this script in the Studio Command Bar.
-- Read-only: this script does not publish, modify, or replace the selected model.

local Selection = game:GetService("Selection")
local selected = Selection:Get()
assert(#selected == 1 and selected[1]:IsA("Model"),
    "[PetKingdoms] Select exactly one imported Bunny Model in Explorer.")

local model = selected[1]
local counts = {
    descendants = 0,
    meshParts = 0,
    bones = 0,
    motors = 0,
    animationControllers = 0,
    animators = 0,
    humanoids = 0,
    scripts = 0,
    materials = {},
    anchoredParts = 0,
    unanchoredParts = 0,
}
local boneNames = {}
local meshNames = {}

for _, item in ipairs(model:GetDescendants()) do
    counts.descendants += 1

    if item:IsA("MeshPart") then
        counts.meshParts += 1
        table.insert(meshNames, item:GetFullName())
        local materialName = tostring(item.Material)
        counts.materials[materialName] = (counts.materials[materialName] or 0) + 1
    elseif item:IsA("Bone") then
        counts.bones += 1
        table.insert(boneNames, item:GetFullName())
    elseif item:IsA("Motor6D") then
        counts.motors += 1
    elseif item:IsA("AnimationController") then
        counts.animationControllers += 1
    elseif item:IsA("Animator") then
        counts.animators += 1
    elseif item:IsA("Humanoid") then
        counts.humanoids += 1
    elseif item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
        counts.scripts += 1
    end

    if item:IsA("BasePart") then
        if item.Anchored then
            counts.anchoredParts += 1
        else
            counts.unanchoredParts += 1
        end
    end
end

table.sort(boneNames)
table.sort(meshNames)

local pivot = model:GetPivot()
local boundsCFrame, boundsSize = model:GetBoundingBox()

print("========== PET KINGDOMS / BUNNY IMPORT REPORT ==========")
print("Model:", model:GetFullName())
print("Descendants:", counts.descendants)
print("MeshParts:", counts.meshParts)
print("Bones:", counts.bones)
print("Motor6D:", counts.motors)
print("AnimationControllers:", counts.animationControllers)
print("Animators:", counts.animators)
print("Humanoids:", counts.humanoids)
print("Unexpected scripts/modules:", counts.scripts)
print("Anchored BaseParts:", counts.anchoredParts)
print("Unanchored BaseParts:", counts.unanchoredParts)
print("Bounding box (studs):", boundsSize)
print("Pivot position:", pivot.Position)
print("Bounding box center:", boundsCFrame.Position)

print("--- Imported bone hierarchy ---")
for _, name in ipairs(boneNames) do
    print(name)
end

print("--- Imported MeshParts ---")
for _, name in ipairs(meshNames) do
    print(name)
end

print("--- MeshPart material enum counts (not texture/material fidelity) ---")
for material, count in pairs(counts.materials) do
    print(material .. ":", count)
end

print("--- Automated structural checks ---")
local checks = {
    { "At least one MeshPart", counts.meshParts > 0 },
    { "At least one skinned Bone", counts.bones > 0 },
    { "No unexpected executable content", counts.scripts == 0 },
    { "No Humanoid required for AnimationController-based pet", counts.humanoids == 0 },
}
local passed = 0
for _, check in ipairs(checks) do
    print((check[2] and "PASS" or "REVIEW") .. " — " .. check[1])
    if check[2] then
        passed += 1
    end
end

print(("Structural checks: %d/%d passed"):format(passed, #checks))
print("IMPORTANT: This is an import report, not visual or animation approval.")
print("Inspect silhouette, materials/textures, scale, pivot, skin deformation, and every animation in Studio.")
print("========================================================")
