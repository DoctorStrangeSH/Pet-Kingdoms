--!strict
-- Client-side modal coordinator. Owns exclusivity between top-level Pet Kingdoms windows.
-- Nested dialogs remain owned by their parent window and are not registered here.

local ModalManager = {}

type CloseHandler = (reason: string) -> ()

local handlers: { [string]: CloseHandler } = {}
local activeWindow: string? = nil
local opening = false

function ModalManager.Register(name: string, closeHandler: CloseHandler)
	assert(name ~= "", "Modal name cannot be empty")
	assert(type(closeHandler) == "function", "Modal close handler must be a function")
	handlers[name] = closeHandler
end

function ModalManager.Unregister(name: string)
	handlers[name] = nil
	if activeWindow == name then
		activeWindow = nil
	end
end

function ModalManager.Open(name: string)
	if opening then return end
	if handlers[name] == nil then
		warn("[PetKingdomsUI] Attempted to open an unregistered modal: " .. name)
		return
	end
	opening = true
	-- Close all other top-level windows before assigning focus to the new one.
	for otherName, closeHandler in pairs(handlers) do
		if otherName ~= name and otherName == activeWindow then
			local ok, err = pcall(closeHandler, "switch")
			if not ok then warn("[PetKingdomsUI] Failed to close " .. otherName .. ": " .. tostring(err)) end
		end
	end
	activeWindow = name
	opening = false
end

function ModalManager.Close(name: string)
	if activeWindow == name then
		activeWindow = nil
	end
end

function ModalManager.GetActive(): string?
	return activeWindow
end

function ModalManager.CloseAll()
	local current = activeWindow
	if current == nil then return end
	local handler = handlers[current]
	activeWindow = nil
	if handler then
		local ok, err = pcall(handler, "close_all")
		if not ok then warn("[PetKingdomsUI] Failed to close " .. current .. ": " .. tostring(err)) end
	end
end

return ModalManager
