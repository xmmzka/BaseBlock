local Enums = require("Enums")
local Core = require("Core")
local ConfigLoader = require("ConfigLoader")
local Logger = require("Logger")
local FrameTimer = require("FrameTimer")
local Frame = require("Frame")
local Test = require("Test")
local Timer = require("Timer")
local Util = require("Util")
local Random = require("Random")

local BaseBlock = {}
--Load logic
local title = string.format("BaseBlock Framework\n>>> V%s\n", Core.CORE_VERSION)
print(title)

local configStatus = ConfigLoader.loadConfig("config")
if configStatus then
    Logger.info(string.format("Profiles found, total number of configurations: %s, loaded: %s, skipped: %s.", configStatus.total, configStatus.loaded, configStatus.skipped))
else
    Logger.info("No profile found, default value used.")
end

Logger.info("Log level has been set to " .. ConfigLoader.config.logLevel .. ".")
Core.init()

Core.loadTestFunctionList("test")
FrameTimer.new(ConfigLoader.config.runTestFrameOffset, 1, false, function ()
    Core.runTest()
end):run()



BaseBlock.LogLevel = Enums.LogLevel
BaseBlock.ObjectType = Enums.ObjectType
BaseBlock.Frame = Frame
BaseBlock.FrameTimer = FrameTimer
BaseBlock.Logger = Logger
BaseBlock.Test = Test
BaseBlock.Timer = Timer
BaseBlock.Util = Util
BaseBlock.Random = Random

return BaseBlock