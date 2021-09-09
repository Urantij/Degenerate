BaseClass = require("class")
common_knowledge = require("commonknowledge")
sides = require("sides")

local module = {}

local Command = {}
local dict = {}
BaseClass:Inherit(Command)
module.Command = Command
module.commandsDict = dict

function Command.MakeSearchFunc(itemId)
	
	if (itemId == common_knowledge.items.seeds) then
		return function(stack) return stack ~= nil and 
								stack.name ~= nil and 
								common_knowledge.isSeed(stack.name) 
								end
		
	elseif (itemId == common_knowledge.items.sticks) then
		return function(stack) return stack ~= nil and 
								stack.name ~= nil and 
								common_knowledge.isCropStick(stack.name) 
								end
		
	elseif (itemId == common_knowledge.items.notSticks) then
		return function(stack) return stack ~= nil and 
								stack.name ~= nil and 
								not common_knowledge.isCropStick(stack.name) 
								end
		
	elseif (itemId == common_knowledge.items.any) then
		return function(stack) return stack ~= nil and 
								stack.name ~= nil 
								end
		
	else
		error("MakeSearchFunc Unknown item " .. tostring(itemId))
	end
end

function Command.FindRobotStack(controller, checkFunc, startIndex)

	local size = controller.robotComponent.inventorySize()
	
	if (startIndex == nil) then
		startIndex = 1
	end
	
	for i = startIndex, size, 1 do
		
		local stack = controller.inventory_controller.getStackInInternalSlot(i)
		
		if (checkFunc(stack)) then
			return i, stack
		end
	end
	
	return nil, nil
end

function Command.FindIterStack(controller, checkFunc)

	local iterator = controller.inventory_controller.getAllStacks(sides.front)

	local stack = iterator()
	local index = 1
	
	while (stack ~= nil) do
		
		if (checkFunc(stack)) then
			return index, stack
		end
		
		stack = iterator()
		index = index + 1
	end
	
	return nil, nil
end

function Command.SetDefaults(obj)

	obj.args = {}
	obj.ready = false
	obj.finish = false
end

function Command:read(value)
	error("Base read function called")
end

function Command:process(controller)
	error("Base process function called")
end

--
local WaitCommand = {}
dict[common_knowledge.commands.wait] = WaitCommand
Command:Inherit(WaitCommand)

function WaitCommand:read(value)

	if (self.args.time == nil) then
	
		self.args.time = value
		self.ready = true
	end
end

function WaitCommand:process(controller)

	os.sleep(self.args.time / 4)
	self.finish = true
end

--
local MoveCommand = {}
dict[common_knowledge.commands.move] = MoveCommand
Command:Inherit(MoveCommand)

function MoveCommand:read(value)

	if (self.args.placeNum == nil) then
	
		self.args.placeNum = value
	elseif (self.args.turnNum == nil) then
	
		self.args.turnNum = value
		self.ready = true
	end
end

function MoveCommand:process(controller)

	controller.moveRobot(self.args.placeNum, self.args.turnNum)
	self.finish = true
end

--
local SuckCommand = {}
dict[common_knowledge.commands.suck] = SuckCommand
Command:Inherit(SuckCommand)

function SuckCommand:read(value)
	if (self.args.item == nil) then
		self.args.item = value
		self.ready = true
	end
end

function SuckCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.item)
	
	local inventoryIndex, inventoryStack = Command.FindIterStack(controller, checkFunc)
	
	if (inventoryIndex == nil) then
	
		self.finish = true
		return
	end
	
	local selectedIndex = controller.robot.select()
	
	local robotIndex, robotStack = Command.FindRobotStack(controller, checkFunc)
	
	if (robotIndex ~= nil) then
	
		controller.robot.select(robotIndex)
	end
	
	controller.inventory_controller.suckFromSlot(sides.front, inventoryIndex)
	
	if (robotIndex ~= nil) then
	
		controller.robot.select(selectedIndex)
	end
	
	self.finish = true
end

--
local ResuplyCommand = {}
dict[common_knowledge.commands.resuply] = ResuplyCommand
Command:Inherit(ResuplyCommand)

function ResuplyCommand:read(value)
	if (self.args.item == nil) then
		self.args.item = value
	elseif (self.args.stacksCount == nil) then
		--Сколько стаков мы хотим видеть у робота
		self.args.stacksCount = value
		self.ready = true
	end
end

function ResuplyCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.item)
	
	--Сколько стаков есть
	local haveStacks = 0
	local searchIndex = 1
	
	while (haveStacks < self.args.stacksCount) do
	
		--Ищем стак у робота
		local robotItemIndex, robotItemStack = Command.FindRobotStack(controller, checkFunc, searchIndex)
		--Ищем стак в сундуке
		local chestItemIndex, chestItemStack = Command.FindIterStack(controller, checkFunc)
		
		if (chestItemIndex == nil) then
			--В сундуке нет суплаев, мы проиграли.
			self.finish = true
			return
		end
		
		if (robotItemIndex == nil) then
			--У робота вообще этого нет
			
			local selectedIndex = controller.robot.select()
			
			controller.robot.select(robotItemIndex)
			controller.inventory_controller.suckFromSlot(sides.front, chestItemIndex)
			controller.robot.select(selectedIndex)
		else
			--Тэк тэк тэк, мы нашли стак. Нужно определить, полный ли он
			
			local emptySpace = robotItemStack.maxSize - robotItemStack.size
			
			if (emptySpace <= 0) then
				--Этот стак полный, значит, мы просто едем дальше
				haveStacks = haveStacks + 1
				searchIndex = robotItemIndex + 1
			else
				--В стаке ещё есть место
				
				local selectedIndex = controller.robot.select()
				
				local toTakeCount = math.min(emptySpace, chestItemStack.size)
				controller.robot.select(robotItemIndex)
				controller.inventory_controller.suckFromSlot(sides.front, chestItemIndex, toTakeCount)
				controller.robot.select(selectedIndex)
				
				searchIndex = robotItemIndex
			end
		end
	end
		
	self.finish = true
end

--
local DropCommand = {}
dict[common_knowledge.commands.drop] = DropCommand
Command:Inherit(DropCommand)

function DropCommand:read(value)
	if (self.args.item == nil) then
		self.args.item = value
	elseif (self.args.spam == nil) then
		--0 try to throw first item, give up if didnt drop
		--1 try to throw one item, dont give up if didnt drop
		--2 try to throw all items, dont give up if didnt drop
		self.args.spam = value
		self.ready = true
	end
end

function DropCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.item)
	
	local selectedIndex = controller.robot.select()
	
	local searchIndex = 1
	local size = controller.robotComponent.inventorySize()
	
	while (searchIndex <= size) do
	
		local itemIndex, itemStack = Command.FindRobotStack(controller, checkFunc, searchIndex)
	
		if (itemIndex == nil) then
			self.finish = true
			return
		end
		
		controller.robot.select(itemIndex)
		local dropped = controller.robot.drop()

		if (self.args.spam == 0) then
			break
		elseif (self.args.spam == 1) then
			
			if (dropped) then
				break
			end
		elseif (self.args.spam == 2) then			
		end
	end
	
	controller.robot.select(selectedIndex)
	
	self.finish = true
end

--
local UseCommand = {}
dict[common_knowledge.commands.use] = UseCommand
Command:Inherit(UseCommand)

function UseCommand:read(value)

	if (self.args.item == nil) then
		self.args.item = value
		self.ready = true
	end
end

function UseCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.item)
	
	local itemIndex, itemStack = Command.FindRobotStack(controller, checkFunc)
	
	if (itemIndex == nil) then
		self.finish = true
		return
	end
	
	local selectedIndex = controller.robot.select()
	
	controller.robot.select(itemIndex)
	controller.inventory_controller.equip()
	
	controller.robot.use(sides.front)
	
	controller.inventory_controller.equip()
	controller.robot.select(selectedIndex)
	
	self.finish = true
end

--
local UseDownCommand = {}
dict[common_knowledge.commands.useDown] = UseDownCommand
Command:Inherit(UseDownCommand)

function UseDownCommand:read(value)

	if (self.args.item == nil) then
		self.args.item = value
		self.ready = true
	end
end

function UseDownCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.item)
	
	local itemIndex, itemStack = Command.FindRobotStack(controller, checkFunc)
	
	if (itemIndex == nil) then
		self.finish = true
		return
	end
	
	local selectedIndex = controller.robot.select()
	
	controller.robot.select(itemIndex)
	controller.inventory_controller.equip()
	
	controller.robot.up()
	controller.robot.forward()
	
	controller.robot.useDown(sides.bottom)
	
	controller.robot.back()
	controller.robot.down()
	
	controller.inventory_controller.equip()
	controller.robot.select(selectedIndex)
	
	self.finish = true
end

--
local BreakCommand = {}
dict[common_knowledge.commands.breakIt] = BreakCommand
Command:Inherit(BreakCommand)

function BreakCommand:read(value)

	if (self.args.selectItem == nil) then
		self.args.selectItem = value
		self.ready = true
	end
end

function BreakCommand:process(controller)

	local checkFunc = Command.MakeSearchFunc(self.args.selectItem)
	
	local itemIndex, itemStack = Command.FindRobotStack(controller, checkFunc)
	
	local selectedIndex = controller.robot.select()
	
	if (itemIndex ~= nil) then
		controller.robot.select(itemIndex)
	end
	
	controller.robot.swing()
	
	if (itemIndex ~= nil) then
		controller.robot.select(selectedIndex)
	end
	
	self.finish = true
end

return module