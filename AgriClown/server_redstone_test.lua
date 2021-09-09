component = require("component")
shell = require("shell")

local redstone = component.redstone

local args, ops = shell.parse(...)

--Робот воспринимает только НОВОЕ значение редстоуна
--то есть значение долнжо меняться
--Чтобы можно было юзать два одинаковых значения подряд
--Робот пропускает каждое второе значение
--И значит, каждое второе значение должно отличаться от текущего и от следующего
--Иначе оно не будет новым после того, как поставили первое, или оно будет совпадать со следующим
function set(value, nextValue)
	redstone.setOutput(1, value)
	
	if (nextValue ~= nil) then
	
		local resetValue = nil
		--здесь была попытка сделать через логику, но я сломался
		for i=0, 16, 1 do
			if (i ~= value and i ~= nextValue) then
				resetValue = i
				break
			end
		end
		
		redstone.setOutput(1, resetValue)
	else 
		redstone.setOutput(1, 0)
	end
end

for i = 1, #args, 1 do
	
	local value = tonumber(args[i])
	local nextValue = tonumber(args[i+1])
	
	print("Set " .. tostring(value))
	set(value, nextValue)
end

print("over")