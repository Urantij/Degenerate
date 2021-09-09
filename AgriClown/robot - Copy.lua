shell = require("shell")
term = require("term")
robot = require("robot")
component = require("component")
event = require("event")

common_knowledge = require("commonknowledge")
commandsReq = require("commands")

redstone = component.redstone
robotComponent = component.robot
--

local appArgs, ops = shell.parse(...)

local debugValues = {}
local debugging = ops.debug == true

function printD(msg)
	term.clear()
	if (debugging) then
	
		term.write(tostring(msg) .. " values: " .. table.concat(debugValues, "; ") .. "\n")
	end
end

function printI(msg)
	term.clear()
	term.write(tostring(msg) .. "\n")
end

if (debugging) then
	printI("debug")
end

local controller = {}
controller.robot = robot
controller.robotComponent = robotComponent
controller.inventory_controller = component.inventory_controller

--state.commandsCount how many commands are queued
--state.commands commands queue
--state.current current command
--state.ignoreNextRedstone
--state.run
local state = nil

local locationInfo = {}
--3 possible positions, again middle, left or right грядки
-- [][][]
-- LLMMRR
locationInfo.posNum = common_knowledge.middlePosNum
--"F" is faced to грядки, "L" is faced from middle position to left грядки, same for "R"
--"B" is faced from грядки
-- [][][]
-- ______
-- < = left ^ = front > = right v = back
locationInfo.turnNum = common_knowledge.frontTurnNum

--this function command robot to take specific pos and turn
function controller.moveRobot(posNum, turnNum)
	
	if (locationInfo.posNum == posNum) then
		if (locationInfo.turnNum == turnNum) then
			return
		else
			controller.turnRobot(turnNum)
			return
		end
	else
		
		local diff = posNum - locationInfo.posNum
		
		if (diff < 0) then
			controller.turnRobot(common_knowledge.leftTurnNum)
		else
			controller.turnRobot(common_knowledge.rightTurnNum)
		end
		
		if (diff < 0) then
			diff = diff * -1
		end
		
		while (diff > 0) do
			
			controller.robot.forward()
			diff = diff - 1
		end
		
		locationInfo.posNum = posNum
		controller.turnRobot(turnNum)
	end
end

function controller.turnRobot(turnNum)

	if (locationInfo.turnNum == turnNum) then
		return
	end
	
	local movePoints = turnNum - locationInfo.turnNum
	
	while (movePoints ~= 0) do
	
		if (movePoints > 0) then
			controller.robot.turnRight()
			movePoints = movePoints - 1
		else
			controller.robot.turnLeft()
			movePoints = movePoints + 1
		end
	end
	
	locationInfo.turnNum = turnNum
end

function process()
	
	while (true) do
		
		if (state.current == nil) then
			
			if (#state.commands == 0) then
				printD("Finished process")
				state = nil
				redstone.setOutput(sides.bottom, 1)
				redstone.setOutput(sides.bottom, 0)
				return
			end
		
			state.current = table.remove(state.commands, 1)
		end
		
		printD("Processing command with id " .. tostring(state.current.command) .. " " .. tostring(#state.commands) .. " commands left")
		state.current:process(controller)
		
		if (state.current.finish) then
			printD("Finish command...")
			state.current = nil
		end
	end
end

function processRedstoneCallback(newValue, dontIgnore)

	if (state ~= nil) then
		
		if (state.run) then
			printD("redstoneCallback already run")
			return
		end
		
		local ignore = state.ignoreNextRedstone
		
		state.ignoreNextRedstone = not state.ignoreNextRedstone
		
		if (ignore and not dontIgnore) then
			printD("Ignoring redstone")
			return
		end
	end
	
	if (debugging) then
		table.insert(debugValues, newValue)
	end
	printD("Reading signel, newValue is " .. tostring(newValue))
	
	if (state == nil) then
		state = {}
		state.commandsCount = newValue
		state.commands = {}
		state.ignoreNextRedstone = true
		
		printD("redstoneCallback, gonna have " .. tostring(newValue) .. " commands")
	else
		if (state.current == nil) then
			
			local CommandClass = commandsReq.commandsDict[newValue]
			
			local command = CommandClass:New()
			command.command = newValue
						
			printD("Creating command with id " .. tostring(command.command) .. ", .ready is " .. tostring(command.ready))
			
			if (command.ready) then
				table.insert(state.commands, command)
			else
				state.current = command
			end
		else
			
			state.current:read(newValue)
			
			printD("Reading command, .ready is " .. tostring(state.current.ready))
			
			if (state.current.ready) then
				table.insert(state.commands, state.current)
				state.current = nil
			end
		end	
	end
	
	if (#state.commands == state.commandsCount) then
		printD("Begin processing")
		state.run = true
		
		process()
	end
end

function redstoneCallback(eventName, address, side, oldValue, newValue)
	
	local okay, reason = pcall(function()
		processRedstoneCallback(newValue)
	end)
	
	if (not okay) then
		printD("redstoneCallback is not okay " .. tostring(reason))
	end
end

event.listen("redstone_changed", redstoneCallback)

local wentOkay, isItReally = pcall(function ()

while (true) do
	local readStr = term.read()
	
	if (readStr == nil) then
		return
	end
	
	print(readstr)
	
	if (readStr == "E\n") then
		return
	end
	
	local readLength = string.len(readStr)
	readStr = string.sub(readStr, 0, readLength - 1)
	
	local iter = string.gmatch(readStr, "[^%s]+")
	
	local command = string.lower(iter() or "")
	local commandArgs = {}
	
	while (true) do
		local word = iter()
		if (word == nil) then
			break
		end
		
		table.insert(commandArgs, word)
	end
	
	if (command == "turn" and #commandArgs > 0) then
		local t = string.upper(commandArgs[0])
		controller.turnRobot(t)
	elseif (command == "move" and #commandArgs > 1) then
		local m = string.upper(commandArgs[0])
		local t = string.upper(commandArgs[1])
		controller.moveRobot(m, t)
	elseif (command == "call") then
		
		for i, v in ipairs(commandArgs) do
		
			local value = tonumber(v)
			processRedstoneCallback(value, true)
		end
	else
		printI("huh? turn move call")
	end
end
end)

if (not wentOkay) then
	print("read loop crashed " .. tostring(isItReally))
end

event.ignore("redstone_changed", redstoneCallback)