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
	local completed = false
	local result: Result<T>? = nil

	task.spawn(function()
		local ok, value = pcall(callback)
		if completed then return end
		completed = true
		result = {
			ok = ok,
			value = if ok then value else nil,
			errorCode = if ok then nil else "REMOTE_ERROR",
		}
	end)

	local deadline = os.clock() + timeout
	while not completed and os.clock() < deadline do
		task.wait(0.05)
	end

	if not completed then
		completed = true
		return {
			ok = false,
			value = nil,
			errorCode = "TIMEOUT",
		}
	end

	return result :: Result<T>
end

return table.freeze(RequestRunner)
