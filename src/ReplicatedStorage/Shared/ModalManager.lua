--!strict
-- Client-side coordinator for mutually exclusive top-level windows.
-- Nested confirmations remain owned by their parent window.

local ModalManager = {}

type CloseHandler = (reason: string) -> ()

local handlers: { [string]: CloseHandler } = {}
local activeWindow: string? = nil
local opening = false

local function getRegisteredNames(): { string }
	local names = {}
	for name in pairs(handlers) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

local function invokeClose(name: string, reason: string)
	local handler = handlers[name]
	if handler == nil then return end
	local ok, err = pcall(handler, reason)
	if not ok then
		warn("[PetKingdomsUI] Failed to close " .. name .. ": " .. tostring(err))
	end
end

function ModalManager.Register(name: string, closeHandler: CloseHandler)
	assert(name ~= "", "Modal name cannot be empty")
	assert(type(closeHandler) == "function", "Modal close handler must be a function")
	handlers[name] = closeHandler
end

function ModalManager.Unregister(name: string)
	if activeWindow == name then
		-- A controller can be removed while its window is visible (for example,
		-- during a respawn/rebind). Clear focus and invoke its cleanup before
		-- dropping the handler so its panel and input-blocking shade cannot linger.
		activeWindow = nil
		invokeClose(name, "unregister")
	end
	handlers[name] = nil
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
end

function ModalManager.Close(name: string)
	if activeWindow == name then
		activeWindow = nil
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
end

return table.freeze(ModalManager)
