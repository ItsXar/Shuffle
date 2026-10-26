--!strict
--[[
	Builds an Instance in one expression: properties, children, then the parent (set last, so the
	instance is complete before it appears).

	    local frame: Frame = Make("Frame", { Size = UDim2.fromScale(1, 1), Parent = gui }, {
	        Make("UICorner", { CornerRadius = UDim.new(0, 8) }),
	    })
]]

local function Make(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance: any = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				instance[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

return Make
