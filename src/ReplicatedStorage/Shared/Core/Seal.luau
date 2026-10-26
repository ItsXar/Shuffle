--!strict

local Log = require(script.Parent.Log)

local TAG = "Config"

local function isList(value: { [any]: any }): boolean
	local count = 0
	for key in value do
		if type(key) ~= "number" then
			return false
		end
		count += 1
	end
	return count > 0 and count == #value
end

-- Named keys are strict (a typo is an error). Records inside a list are plain data that may
-- leave optional fields out, so they (and everything under them) are only frozen.
local function seal(value: any, path: string, strict: boolean): any
	if type(value) ~= "table" then
		return value
	end

	local list = isList(value)
	local sealed = {}
	for key, child in value do
		sealed[key] = seal(child, `{path}.{key}`, strict and not list)
	end

	if strict and not list then
		setmetatable(sealed, {
			__index = function(_, key)
				Log.Error(TAG, `{path}: "{key}" does not exist`, 2)
			end,
		})
	end
	return table.freeze(sealed)
end

local function Seal<T>(source: Instance, data: T): T
	local path = string.gsub(source:GetFullName(), "^.-Config%.", "Config.")
	return seal(data, path, true)
end

return Seal
