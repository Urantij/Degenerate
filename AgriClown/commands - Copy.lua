BaseClass = require("class")
common_knowledge = require("commonknowledge")
sides = require("sides")

local module = {}

local Command = {}
BaseClass:Inherit(Command)
module.Command = Command

function Command.GetSlotIndex(controller, checkFunc)

	local size = controller.robotComponent.inventorySize()
	
	for i=1, size, 1 do
		
		local stack = controller.inventory_controller.getStackInInternalSlot(i)
		
		if (stack ~= nil) then
			
			if (checkFunc(stack)) then
				return i
			end
		end
	end
	
	return nil
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
PlaceCropSticksCommand = {}
Command:Inherit(PlaceCropSticksCommand)
module.PlaceCropSticksCommand = PlaceCropSticksCommand

function PlaceCropSticksCommand:read(value)

	if (self.args.placeNum == nil) then
		self.args.placeNum = value
	elseif (self.args.count == nil) then
		self.args.count = value
		self.ready = true
	end
end

function PlaceCropSticksCommand:process(controller)

	local checkFunc = function(stack) return common_knowledge.isCropStick(stack.name) end
	local cropStickIndex = Command.GetSlotIndex(controller, checkFunc)
	
	if (cropStickIndex == nil) then
		error("PlaceCropSticksCommand Cant process command, cant find cropsticks")
	end
	
	controller.moveRobot(self.args.placeNum, common_knowledge.frontTurnNum)
	local size = controller.robotComponent.inventorySize()	
	
	controller.robot.select(cropStickIndex)
	controller.inventory_controller.equip()
	
	controller.robot.up()
	controller.robot.forward()
	
	for i=1, self.args.count, 1 do
		controller.robot.useDown(sides.bottom)
	end
	
	controller.robot.back()
	controller.robot.down()
	
	controller.inventory_controller.equip()
	self.finish = true
end

--
PlaceSeedsCommand = {}
Command:Inherit(PlaceSeedsCommand)
module.PlaceSeedsCommand = PlaceSeedsCommand

function PlaceSeedsCommand:read(value)

	if (self.args.placeNum == nil) then
		self.args.placeNum = value
		self.ready = true
	end
end

function PlaceSeedsCommand:process(controller)

	controller.moveRobot(self.args.placeNum, common_knowledge.frontTurnNum)
	local size = controller.robotComponent.inventorySize()
	
	local seedsIndex = nil
	
	for i=1, size, 1 do
		
		stack = controller.inventory_controller.getStackInInternalSlot(i)
		
		if (stack ~= nil) then
			
			if (common_knowledge.isSeed(stack.name)) then
				seedsIndex = i
				break
			end
		end
	end
	
	if (seedsIndex == nil) then
		error("PlaceSeedsCommand Cant process command, cant find seeds")
	end
	
	controller.robot.select(seedsIndex)
	controller.inventory_controller.equip()
	
	controller.robot.use(sides.front)
	
	controller.inventory_controller.equip()
	self.finish = true
end

--
PutSeedsCommand = {}
Command:Inherit(PutSeedsCommand)
module.PutSeedsCommand = PutSeedsCommand

function PutSeedsCommand:read(value)
	
	if (self.args.placeNum == nil) then
		self.args.placeNum = value
		self.ready = true
	end
end

function PutSeedsCommand:process(controller)

	local checkFunc = function(stack) return common_knowledge.isSeed(stack.name) end

	local slotIndex = Command.GetSlotIndex(controller, checkFunc)
	
	if (slotIndex == nil) then
		error("PutSeedsCommand Cant process command, cant find seeds")
	end
	
	controller.moveRobot(self.args.placeNum, common_knowledge.backTurnNum)
	
	controller.robot.select(seedsIndex)
	
	controller.robot.drop()
	
	self.finish = true
end

--
module.commandsDict = {
	[common_knowledge.commands.comeback] = nil,
	[common_knowledge.commands.resuply] = nil,
	[common_knowledge.commands.placeCropSticks] = PlaceCropSticksCommand,
	[common_knowledge.commands.placeSeeds] = PlaceSeedsCommand,
	[common_knowledge.commands.putSeeds] = PutSeedsCommand
}

return module