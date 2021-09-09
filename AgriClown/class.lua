--MyClass = [}
--BaseClass:inherit(MyClass)
--function MyClass.SetDefaults(obj) obj.field = 5 end
--function MyClass:test() print("test " .. obj.field) end
--instance = MyClass:new()
--instance:test()

local BaseClass = {}

function BaseClass:New()

	local obj = {}
	
	setmetatable(obj, { __index = self })
	
	classMetatable = getmetatable(self)
	if (classMetatable ~= nil) then
		obj.super = classMetatable.__index
	end
	
	self.SetDefaults(obj)
	
	return obj
end

function BaseClass:Inherit(class)
	
	setmetatable(class, { __index = self })
end

function BaseClass.SetDefaults(obj)
end

return BaseClass