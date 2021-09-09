local monitorName = "monitor_1"
local bloodName = "right"

local monitor = peripheral.wrap(monitorName)
local blood = peripheral.wrap(bloodName)

local timer = nil

monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setBackgroundColor(colors.black)
monitor.setTextColor(colors.white)
monitor.setTextScale(5)

function Draw(text) 
	
	monitor.clear()
	monitor.setCursorPos(1, 1)
	
	monitor.write(text)
end

function Do()

	local info = blood.getInfo()
	
	local amount = tostring(info.contents.amount)
	
	Draw(amount)
	
	timer = os.startTimer(0.3)
end

print("Press any key to finish")

Do()
while (true) do

	local event, timerID = os.pullEvent()
	
	if (timerID == timer) then
			
		Do()
	elseif event == "key" then
	
		break
	end
end

