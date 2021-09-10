shell = require("shell")
term = require("term")
robot = require("robot")
component = require("component")
event = require("event")
fs = require("filesystem")
keyboard = require("keyboard")

common_knowledge = require("commonknowledge")
commandsReq = require("commands")

computer = component.computer
redstone = component.redstone
robotComponent = component.robot
--

local appArgs, ops = shell.parse(...)

local debugging = ops.debug == true

function printD(msg)
	if (debugging) then
	
		print(msg)
	end
end

function printI(msg)
	print(msg)
end

if (debugging) then
	printI("debug")
end

local controller = {}
controller.robot = robot
controller.robotComponent = robotComponent
controller.inventory_controller = component.inventory_controller

local waitColor = 0x00FF00
local readColor = 0xFF0000
local execColor = 0x0000FF

--state.commandsCount how many commands are queued
--state.commands commands queue
--state.current current command
--state.ignoreNextRedstone
--state.run
local state = nil

local locationInfo = {}
locationInfo.pos = common_knowledge.poses.middle
locationInfo.turn = common_knowledge.turns.front

function controller.tryExecuteRobot(func)
    
    local executed = false
    while (not executed) do
			executed = func()
			
			if (not executed) then
				computer.beep()
				os.sleep(1)
      end
    end
end

--this function command robot to take specific pos and turn
function controller.moveRobot(pos, turn)
	
	if (locationInfo.pos == pos) then
		controller.turnRobot(turn)
		return
	else
		
		local movePoints = pos - locationInfo.pos
		
		if (movePoints < 0) then
			controller.turnRobot(common_knowledge.turns.left)
		else
			controller.turnRobot(common_knowledge.turns.right)
		end
		
		--printD("moving from " .. tostring(locationInfo.pos) .. " to " .. tostring(pos) .. " (" .. tostring(movePoints) .. ")")
		
		if (movePoints < 0) then
			movePoints = movePoints * -1
		end
		
		while (movePoints > 0) do
			controller.tryExecuteRobot(controller.robot.forward)
			
			movePoints = movePoints - 1
		end
		
		locationInfo.pos = pos
		controller.turnRobot(turn)
	end
end

function controller.turnRobot(turn)

	if (locationInfo.turn == turn) then
		return
	end
	
	local movePoints = turn - locationInfo.turn
	--printD("turning from " .. tostring(locationInfo.turn) .. " to " .. tostring(turn) .. " (" .. tostring(movePoints) .. ")")
	
	if (movePoints == 3) then
		movePoints = -1
	elseif (movePoints == -3) then
		movePoints = 1
	end
	
	local turnFunc = nil
	if (movePoints > 0) then turnFunc = controller.robot.turnRight
	else turnFunc = controller.robot.turnLeft movePoints = movePoints * -1
	end
	
	for u = movePoints, 1, -1 do
		turnFunc()
	end
	
	locationInfo.turn = turn
end

function process()
	
	robotComponent.setLightColor(execColor)
	while (#state.commands > 0) do
		
		if (state.current == nil) then
			state.current = table.remove(state.commands, 1)
		end
		
		if (debugging) then
			
			local argArray = {}
			for key, value in pairs(state.current.args) do
				table.insert(argArray, tostring(key) .. ": " .. tostring(value))
			end
		
			printD("Processing command with id " .. tostring(state.current.command) .. " (" .. table.concat(argArray, "; ") .. ") " .. tostring(#state.commands) .. " commands left")
		end
		
		state.current:process(controller)
		
		if (state.current.finish) then
			printD("Finish command...")
			state.current = nil
    else
      return
		end
	end
  
  printD("Finished process")
				
  robotComponent.setLightColor(waitColor)
  
  state = nil
  redstone.setOutput(sides.bottom, 1)
  redstone.setOutput(sides.bottom, 0)
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
			--printD("Ignoring redstone")
			return
		end
	end
	
	--printD("Reading signal, newValue is " .. tostring(newValue))
	
	if (state == nil) then
	
		robotComponent.setLightColor(readColor)
		
		state = {}
		state.commandsCount = newValue
		state.commands = {}
		state.ignoreNextRedstone = true
		
		printD("redstoneCallback, gonna have " .. tostring(newValue) .. " commands")
	elseif (state.current == nil) then
			
			local CommandClass = commandsReq.commandsDict[newValue]
			
			local command = CommandClass:New()
			command.command = newValue
						
			--printD("Creating command with id " .. tostring(command.command) .. ", .ready is " .. tostring(command.ready))
			
			if (command.ready) then
				table.insert(state.commands, command)
			else
				state.current = command
			end
		
  else
    
      state.current:read(newValue)
      
      --printD("Reading command, .ready is " .. tostring(state.current.ready))
      
      if (state.current.ready) then
        table.insert(state.commands, state.current)
        state.current = nil
      end
	end
	
	if (#state.commands == state.commandsCount) then
		printD("Begin processing")
		state.run = true
		
		process()
	end
end

local okay, reason = pcall(function()

	robotComponent.setLightColor(waitColor)

	while (true) do
		_, address, side, oldValue, newValue = event.pull("redstone_changed")
		
		processRedstoneCallback(newValue)
	end
end)
if (not okay) then printD(reason) end

print("Finish")