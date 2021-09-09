common_knowledge = require("commonknowledge")

local module = {}

function module.init(redstone, activeSide)
	module.redstone = redstone
	module.activeSide = activeSide
	
	if (redstone == nil) then
		error("Cant find redstone")
	end
	
	redstone.setOutput(module.activeSide, 0)
end

local function formCommand(array, ...)
	
	array.commands = (array.commands or 0) + 1
	
	local args = {...}
	
	for i, value in ipairs(args) do
		table.insert(array, value)
	end
end

--Робот воспринимает только НОВОЕ значение редстоуна
--то есть значение долнжо меняться
--Чтобы можно было юзать два одинаковых значения подряд
--Робот пропускает каждое второе значение
--И значит, каждое второе значение должно отличаться от текущего и от следующего
--Иначе оно не будет новым после того, как поставили первое, или оно будет совпадать со следующим
local function setRedstone(value, nextValue)
	module.redstone.setOutput(module.activeSide, value)
	
	if (nextValue ~= nil) then
	
		local resetValue = nil
		--здесь была попытка сделать через логику, но я сломался
		for i=0, 16, 1 do
			if (i ~= value and i ~= nextValue) then
				resetValue = i
				break
			end
		end
		
		module.redstone.setOutput(module.activeSide, resetValue)
	else 
		module.redstone.setOutput(module.activeSide, 0)
	end
end

function module.run(c)
	
	c[0] = c.commands
	
	for i=0, #c, 1 do
	
		local value = c[i]
		local nextValue = c[i+1]
		
		setRedstone(value, nextValue)
	end
end

--странные команды, некоторые абстрактные, некоторые конкретные

function module.returnPlease(c)
	
	formCommand(c, common_knowledge.commands.move, 
				common_knowledge.poses.middle,
				common_knowledge.turns.front)
end

function module.setDoubleCropsMiddle(c)
	
	formCommand(c, common_knowledge.commands.move, 
				common_knowledge.poses.middle,
				common_knowledge.turns.front)
				
	formCommand(c, common_knowledge.commands.useDown,
				common_knowledge.items.sticks)
				
	formCommand(c, common_knowledge.commands.use,
				common_knowledge.items.sticks)
end

function module.resuply(c, count)

	--интересно конечно, какой тут скоуп
	local count = count or 1

	formCommand(c, common_knowledge.commands.move, 
				common_knowledge.poses.right,
				common_knowledge.turns.back)
				
	formCommand(c, common_knowledge.commands.resuply,
				common_knowledge.items.sticks,
				count)
end

function module.breakPlease(c, pos)

	formCommand(c, common_knowledge.commands.move, 
				pos,
				common_knowledge.turns.front)
				
	formCommand(c, common_knowledge.commands.breakIt,
				common_knowledge.items.sticks)
end

function module.drop(c, pos, turn, item, spam)

	formCommand(c, common_knowledge.commands.move, 
				pos,
				turn)
				
	formCommand(c, common_knowledge.commands.drop, 
				item,
				spam)
end

function module.setCrops(c, pos)

	formCommand(c, common_knowledge.commands.move, 
				pos,
				common_knowledge.turns.front)
				
	formCommand(c, common_knowledge.commands.useDown,
				common_knowledge.items.sticks)
end

function module.getSeedsFromAnalyzer(c)
	
	formCommand(c, common_knowledge.commands.move, 
				common_knowledge.poses.left,
				common_knowledge.turns.back)
				
	formCommand(c, common_knowledge.commands.suck, 
				common_knowledge.items.notSticks)
end

function module.placeSeeds(c, pos)

	formCommand(c, common_knowledge.commands.move, 
				pos,
				common_knowledge.turns.front)
				
	formCommand(c, common_knowledge.commands.use,
				common_knowledge.items.notSticks)
end

return module