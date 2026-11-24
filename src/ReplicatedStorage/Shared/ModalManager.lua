--!strict
-- Client-side coordinator for mutually exclusive top-level windows.
-- Nested confirmations remain owned by their parent window.

local ModalManager = {}

type CloseHandler = (reason: string) -> ()

local handlers: { [string]: CloseHandler } = {}
local activeWindow: string? = nil
local opening = false
local activeChanged = Instance.new("BindableEvent")

local function getRegisteredNames(): { string }
	local names = {}
	for name in pairs(handlers) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function invokeHandler(name: string, handler: CloseHandler, reason: string)
	local ok, err = pcall(handler, reason)
	if not ok then
		warn("[PetKingdomsUI] Failed to close " .. name .. ": " .. tostring(err))
	end
end

local function invokeClose(name: string, reason: string)
	local handler = handlers[name]
	if handler == nil then return end
	invokeHandler(name, handler, reason)
end

function ModalManager.Register(name: string, closeHandler: CloseHandler)
	assert(name ~= "", "Modal name cannot be empty")
	assert(type(closeHandler) == "function", "Modal close handler must be a function")

	-- A LocalScript can be rebound while its old controller still owns a visible
	-- panel. Remove the old registration before invoking cleanup so callbacks
	-- cannot recursively unregister themselves or leave stale focus behind.
	local previousHandler = handlers[name]
	if previousHandler ~= nil then
		handlers[name] = nil
		if activeWindow == name then
			activeWindow = nil
			activeChanged:Fire(nil)
		end
		invokeHandler(name, previousHandler, "reregister")
	end

	-- A cleanup callback may have deliberately installed a newer controller.
	-- Do not overwrite that registration with an older caller's callback.
	if handlers[name] == nil then
		handlers[name] = closeHandler
	end
end

function ModalManager.Unregister(name: string)
	-- Clean up even when focus bookkeeping was lost: a stale panel or
	-- input-blocking shade must not survive controller teardown.
	local previousHandler = handlers[name]
	handlers[name] = nil
	if activeWindow == name then
		activeWindow = nil
		activeChanged:Fire(nil)
	end
	if previousHandler ~= nil then
		invokeHandler(name, previousHandler, "unregister")
	end
end

function ModalManager.Open(name: string)
	if opening then return end
	if handlers[name] == nil then
		warn("[PetKingdomsUI] Attempted to open an unregistered modal: " .. name)
		return
	end

	opening = true
	-- Clear the previous focus before closing peers. Close callbacks may call Close().
	activeWindow = nil
	for _, otherName in ipairs(getRegisteredNames()) do
		if otherName ~= name then
			invokeClose(otherName, "switch")
		end
	end
	activeWindow = name
	opening = false
	activeChanged:Fire(name)
end

function ModalManager.Close(name: string)
	if activeWindow == name then
		activeWindow = nil
		activeChanged:Fire(nil)
	end
end

function ModalManager.IsActive(name: string): boolean
	return activeWindow == name
end

function ModalManager.GetActive(): string?
	return activeWindow
end

function ModalManager.CloseAll()
	if opening then return end
	opening = true
	activeWindow = nil
	-- Close every registered window, not just the last focused one. This repairs
	-- visibility drift after interrupted transitions or a stale active-window ref.
	for _, name in ipairs(getRegisteredNames()) do
		invokeClose(name, "close_all")
	end
	activeWindow = nil
	opening = false
	activeChanged:Fire(nil)
end

ModalManager.ActiveChanged = activeChanged.Event

return table.freeze(ModalManager)
