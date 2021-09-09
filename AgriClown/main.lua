component = require("component")
fs = require("filesystem")
term = require("term")
shell = require("shell")
event = require("event")
sides = require("sides")

common_knowledge = require("commonknowledge")
tasks = require("server_tasks")

redstone = component.redstone
--

tasks.init(redstone, sides.top)

local faceSide = "NORTH"
local oppositeSide = "SOUTH"

local appArgs, ops = shell.parse(...)

local debugging = ops.debug == true

function printD(msg)
	if (debugging) then
		term.write(tostring(msg) .. "\n")
	end
end

local agriPairs = component.list("agricraft_peripheral")
local agriObj = {}
local agriAnalyzer = nil

local configLoaded = false

if (fs.exists("config")) then

	local file = fs.open("config", "r")
	
	local configStr = file:read(1488)
	file:close()
	
	local words = {}
	
	local iter = string.gmatch(configStr, "[^%s]+")
	
	local leftAddress = iter()
	local middleAddress = iter()
	local rightAddress = iter()
	local analyzeAddress = iter()
	
	if (leftAddress and middleAddress and rightAddress and analyzeAddress) then
		
		--нужно ещё следить, чтобы они были того типа, но мне впадлу
		agriObj.left = component.proxy(leftAddress)
		agriObj.middle = component.proxy(middleAddress)
		agriObj.right = component.proxy(rightAddress)
		agriAnalyzer = component.proxy(analyzeAddress)
		
		if (agriObj.left and agriObj.middle and agriObj.right and agriAnalyzer) then
		
			configLoaded = true
		end
	end
end

if (not configLoaded) then
	
	for k,v in pairs(agriPairs) do
		
		while (true) do
			agri = component.proxy(k)
			
			cross = agri.isCrossCrop(oppositeSide)
			
			print("Agri. Cross? " .. tostring(cross) .. " (L)eft (R)ight (M)iddle (A)nalyzer (N)one")
			
			read = string.lower(term.read())
			
			if (read == "l\n") then
				agriObj.left = agri
				break
			elseif (read == "r\n") then
				agriObj.right = agri
				break
			elseif (read == "m\n") then
				agriObj.middle = agri
				break
			elseif (read == "a\n") then
				agriAnalyzer = agri
				break
			elseif (read == "n\n") then
				break
			end		
		end
	end
	
	if (agriObj.left == nil) then
		print("Left Agri isnt set")
		return
	end
	if (agriObj.right == nil) then
		print("Right Agri isnt set")
		return
	end
	if (agriObj.middle == nil) then
		print("Middle Agri isnt set")
		return
	end
	
	if (agriAnalyzer == nil) then

		for key, value in pairs(agriPairs) do

			if (agriObj.left.address ~= key and
				agriObj.right.address ~= key and
				agriObj.middle.address ~= key) then
				
				agriAnalyzer = component.proxy(key)
				break
			end
		end
	end
	
	
	if (agriAnalyzer == nil) then
		print("Cant find analyzer")
		return
	end
	
	if (fs.exists("config")) then
		fs.remove("config")
	end
	
	local file = fs.open("config", "w")
	
	file:write(agriObj.left.address .. " " .. agriObj.middle.address .. " " .. agriObj.right.address .. " " ..  agriAnalyzer.address)
	file:close()
end

function waitForSidePlants()

	while (true) do
	
		local m1 = agriObj.left.hasPlant(oppositeSide)
		local m2 = agriObj.right.hasPlant(oppositeSide)
		
		if (m1 and m2) then
			break
		else
			os.sleep(0.1)
		end
	end
end

function waitForMature()

	while (true) do
	
		local m1 = agriObj.left.isMature(oppositeSide)
		local m2 = agriObj.right.isMature(oppositeSide)
		
		if (m1 and m2) then
			break
		else
			os.sleep(0.1)
		end
	end
end

function waitForMiddleSpawn()

	while (true) do
	
		local m = agriObj.middle.hasPlant(oppositeSide)
		
		if (m) then
			break
		else
			os.sleep(0.1)
		end
	end
end

function waitForRobotSignal()

	while (true) do
		local _, address, side, oldValue, newValue = event.pull("redstone_changed")
		
		if (newValue == 1 and redstone.address == address and sides.top == side) then
			return
		end
	end
end

function waitForAnalyzerFinish()

	while (true) do
	
		local m = agriAnalyzer.isAnalyzed()
		
		if (m) then
			break
		else
			os.sleep(0.1)
		end
	end
end

--
function getSidePlantStats(obj)

	local stat1, stat2, stat3 = obj.getSpecimenStats(oppositeSide)
	--Если не знаем статы, предположим, что это 1 1 1
	if (stat1 == nil) then
		stat1 = 1
		stat2 = 1
		stat3 = 1
	end
	
	return stat1, stat2, stat3
end

function statsAreBetter(stats1, stats2)

	return stats1.score > stats2.score and 
			stats1.stat1 >= stats2.stat1 and
			stats1.stat2 >= stats2.stat2 and
			stats1.stat3 >= stats2.stat3
end

function findReplaceStats(analyzeStats, leftStats, rightStats)

	--нужно понять, с каким растением мы хотим менять
	--все статы нового семена должны быть выше или равны текущему
	--но и хотя бы один стат должен быть выше
	--при этом желательно заменить худшее текущее растение
	local lowStats = nil
	local highStats = nil
	
	local replaceStats = nil
	
	if (rightStats.score > leftStats.score) then
		lowStats = leftStats
		highStats = rightStats
	else
		lowStats = rightStats
		highStats = leftStats
	end
	
	if (statsAreBetter(analyzeStats, lowStats)) then
		
		replaceStats = lowStats
	elseif (statsAreBetter(analyzeStats, highStats)) then
	
		replaceStats = highStats
	end
	
	return replaceStats
end

print("What task?")

while (true) do 
	
	term.clear()
	print("Waiting for 2 side plants...")
	waitForSidePlants()
	
	local leftStats = {}
	leftStats.stat1, leftStats.stat2, leftStats.stat3 = getSidePlantStats(agriObj.left)
	leftStats.score = leftStats.stat1 + leftStats.stat2 + leftStats.stat3
	leftStats.pos = common_knowledge.poses.left
	
	local rightStats = {}
	rightStats.stat1, rightStats.stat2, rightStats.stat3 = getSidePlantStats(agriObj.right)
	rightStats.score = rightStats.stat1 + rightStats.stat2 + rightStats.stat3
	rightStats.pos = common_knowledge.poses.right
	
	print("Sending robot to get supplies...")
	
	local taskBuild = {}
	tasks.resuply(taskBuild, 2)
	tasks.returnPlease(taskBuild)
	
	tasks.run(taskBuild)
	waitForRobotSignal()
	
	print("Waiting for mature...")
	waitForMature()
	
	print("Sending command to robot to place 2 crop sticks in the middle")
	
	taskBuild = {}
	tasks.setDoubleCropsMiddle(taskBuild)
	tasks.resuply(taskBuild, 2)
	tasks.returnPlease(taskBuild)
	
	tasks.run(taskBuild)
	waitForRobotSignal()
	
	print("Waiting for middle...")
	waitForMiddleSpawn()
	
	print("Sending commands to break middle...")
	
	taskBuild = {}
	tasks.breakPlease(taskBuild, common_knowledge.poses.middle)
	tasks.drop(taskBuild, common_knowledge.poses.left, common_knowledge.turns.back, common_knowledge.items.notSticks, 1)
	tasks.drop(taskBuild, common_knowledge.poses.right, common_knowledge.turns.back, common_knowledge.items.notSticks, 2) --тута наверн нужен спам с неигнором обшибки но я панк
	tasks.resuply(taskBuild, 2)
	tasks.returnPlease(taskBuild)
	
	tasks.run(taskBuild)
	waitForRobotSignal()
	
	print("Analyzing seeds...")
	agriAnalyzer.analyze()
	waitForAnalyzerFinish()
	
	local analyzeStats = {}
	analyzeStats.stat1, analyzeStats.stat2, analyzeStats.stat3 = agriAnalyzer.getSpecimenStats()
	analyzeStats.score = analyzeStats.stat1 + analyzeStats.stat2 + analyzeStats.stat3
	
	if (analyzeStats.score == 30) then
		return
	end
	
	local replaceStats = findReplaceStats(analyzeStats, leftStats, rightStats)
	
	if (replaceStats ~= nil) then
		print("Seeds are better, sending robot to replace...")
		
		taskBuild = {}
		tasks.breakPlease(taskBuild, replaceStats.pos)
		tasks.setCrops(taskBuild, replaceStats.pos)
		tasks.drop(taskBuild, common_knowledge.poses.right, common_knowledge.turns.back, common_knowledge.items.notSticks, 2) --тута наверн нужен спам с неигнором обшибки но я панк
		tasks.getSeedsFromAnalyzer(taskBuild)
		tasks.placeSeeds(taskBuild, replaceStats.pos)
		tasks.returnPlease(taskBuild)
	
		tasks.run(taskBuild)
		waitForRobotSignal()
	else
	
		print("Seeds are meh, sending robot to trash...")
		
		taskBuild = {}
		tasks.getSeedsFromAnalyzer(taskBuild)
		tasks.drop(taskBuild, common_knowledge.poses.right, common_knowledge.turns.back, common_knowledge.items.notSticks, 0)
		tasks.returnPlease(taskBuild)
	
		tasks.run(taskBuild)
		waitForRobotSignal()
	end
end
