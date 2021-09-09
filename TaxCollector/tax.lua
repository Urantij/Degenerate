component = require("component")
term = require("term")
computer = component.computer

local deconsPairs = component.list("container_decontable")

local decons = {}

for id, desc in pairs(deconsPairs) do

	local decon = component.proxy(id)
	
	table.insert(decons, decon)
end

while (true) do

	local withItems = 0
	local ready = 0
	local aspectTable = {}
	for index, decon in ipairs(decons) do
		
		if (decon.hasItem()) then
			withItems = withItems + 1
		end
		
		local aspect = decon.getAspect()
		
		if (aspect ~= nil) then
			ready = ready + 1
			
			local aspectsCount = aspectTable[aspect]
			if (aspectsCount == nil) then
				aspectTable[aspect] = 1
			else
				aspectTable[aspect] = aspectsCount + 1
			end
		end
	end
	
	if (ready == #decons) then
		computer.beep()
	end
	
	local aspectStrArray = {}
	for key, value in pairs(aspectTable) do
		
		local str = key .. ": " .. tostring(value)
		table.insert(aspectStrArray, str)
	end
	
	local aspectResult = "(" .. table.concat(aspectStrArray, "; ") .. ")"
	
	term.clear()
	term.write("With Items: " .. tostring(withItems) .. "\n")
	term.write("Ready: " .. tostring(ready) .. "/" .. tostring(#decons) .. " " .. aspectResult)
	os.sleep(1)
end