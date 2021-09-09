local module = {}

--items
module.items = {}
module.items.seeds = 0
module.items.sticks = 1
module.items.notSticks = 2
module.items.any = 3

--commands
local nextCommandId = 0

module.commands = {}
module.commands.wait = nextCommandId nextCommandId=nextCommandId+1
module.commands.move = nextCommandId nextCommandId=nextCommandId+1
module.commands.suck = nextCommandId nextCommandId=nextCommandId+1
module.commands.resuply = nextCommandId nextCommandId=nextCommandId+1
module.commands.drop = nextCommandId nextCommandId=nextCommandId+1
module.commands.use = nextCommandId nextCommandId=nextCommandId+1
module.commands.useDown = nextCommandId nextCommandId=nextCommandId+1
module.commands.breakIt = nextCommandId nextCommandId=nextCommandId+1

--turns
module.turns = {}
module.turns.front = 0
module.turns.frontLetter = "F"

module.turns.right = 1
module.turns.rightLetter = "R"

module.turns.back = 2
module.turns.backLetter = "B"

module.turns.left = 3
module.turns.leftLetter = "L"

module.turns.letterToNumDict = {}
module.turns.letterToNumDict[module.turns.frontLetter] = module.turns.front
module.turns.letterToNumDict[module.turns.rightLetter] = module.turns.right
module.turns.letterToNumDict[module.turns.backLetter] = module.turns.back
module.turns.letterToNumDict[module.turns.leftLetter] = module.turns.left

--pos
module.poses = {}
module.poses.left = 0
module.poses.leftLetter = "L"

module.poses.middle = 1
module.poses.middleLetter = "M"

module.poses.right = 2
module.poses.rightLetter = "R"

module.poses.letterToNum = {}
module.poses.letterToNum[module.poses.leftLetter] = module.poses.left
module.poses.letterToNum[module.poses.middleLetter] = module.poses.middle
module.poses.letterToNum[module.poses.rightLetter] = module.poses.right

--не уверен, зачем это компьютеру, ыхых

function module.isSeed(name)

	return string.match(string.lower(name), "seed") ~= nil
end

function module.isCropStick(name)

	return name == "AgriCraft:cropsItem"
end

return module