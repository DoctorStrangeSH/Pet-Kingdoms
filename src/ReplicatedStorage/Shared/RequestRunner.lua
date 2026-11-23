--!strict
-- Bounded client wait for RemoteFunction calls.
-- A timeout does NOT cancel the server invocation; callers must only retry safely
-- (read-only calls, or mutations protected by server-side idempotency keys).

local RequestRunner = {}

export type Result<T> = {
	ok: boolean,
	value: T?,
	errorCode: string?,
}

function RequestRunner.Invoke<T>(callback: () -> T, timeoutSeconds: number?): Result<T>
	local timeout = math.clamp(timeoutSeconds or 12, 2, 30)
	local signal = Instance.new("BindableEvent")
	local settled = false
	local result: Result<T>? = nil

	task.spawn(function()
		local ok, value = pcall(callback)
		if settled then return end
		settled = true
		result = {
			ok = ok,
			value = if ok then value else nil,
			errorCode = if ok then nil else "REMOTE_ERROR",
		}
		signal:Fire()
	end)

	task.delay(timeout, function()
		if settled then return end
		settled = true
		result = {
			ok = false,
			value = nil,
			errorCode = "TIMEOUT",
		}
		signal:Fire()
	end)

	signal.Event:Wait()
	signal:Destroy()
	return result :: Result<T>
end

return table.freeze(RequestRunner)
