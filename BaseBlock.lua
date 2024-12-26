local BaseBlock = {
    VERSION = "0.0.1_20241226-Beta",
    LOGICAL_FRAME_RATE = 30,
    LOGICAL_FRAME_INTERVAL = 0.033333333
}

-- Do not return this class.
--- @class UpdateSequence
local UpdateSequence = {
    frameworkFixedUpdateSequence = {},
    frameworkLateUpdateSequence = {},
    fixedUpdateSequence = {},
    lateUpdateSequence = {}
}

function UpdateSequence.preHandlerWrapper()
    for key, value in pairs(UpdateSequence.frameworkFixedUpdateSequence) do
        value()
    end
    for key, value in pairs(UpdateSequence.fixedUpdateSequence) do
        value()
    end
end

function UpdateSequence.lateHandlerWrapper()
    for key, value in pairs(UpdateSequence.frameworkLateUpdateSequence) do
        value()
    end
    for key, value in pairs(UpdateSequence.lateUpdateSequence) do
        value()
    end
end

function UpdateSequence.init()
    LuaAPI.set_tick_handler(UpdateSequence.preHandlerWrapper, UpdateSequence.lateHandlerWrapper)
end

--- @class Update
local Update = {}
function Update.getFixedUpdateFunctionSequence()
    return UpdateSequence.fixedUpdateSequence
end

function Update.getLateUpdateFunctionSequence()
    return UpdateSequence.lateUpdateSequence
end

--- @enum LogLevel
local LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

--- @class Logger
--- @field minLogLevel LogLevel
--- @field logTimeFrameCount any
--- @field initialized boolean
local Logger = {
    minLogLevel = LogLevel.DEBUG,
    ---@enum LogLevelNames
    LogLevelNames = {
        [LogLevel.DEBUG] = "D",
        [LogLevel.INFO] = "I",
        [LogLevel.WARN] = "W",
        [LogLevel.ERROR] = "E",
        [LogLevel.FATAL] = "F"
    },
    logTimeFrameCount = "WAITING INIT",
    initialized = false
}
function Logger.init()
    if Logger.initialized then
        Logger.error("Logger has been initialized.")
        return
    end
    Logger.initialized = true
    Logger.logTimeFrameCount = 0
    UpdateSequence.frameworkFixedUpdateSequence.loggerTimer = function()
        Logger.logTimeFrameCount = Logger.logTimeFrameCount + 1
    end
end

function Logger.setLogLevel(minLogLevel)
    Logger.minLogLevel = minLogLevel or LogLevel.DEBUG
end

function Logger.log(level, message)
    if level >= Logger.minLogLevel then
        local levelName = Logger.LogLevelNames[level]
        local logTime = Logger.logTimeFrameCount
        if Logger.initialized then
            logTime = Logger.logTimeFrameCount / BaseBlock.LOGICAL_FRAME_RATE
        end
        if level <= LogLevel.INFO then
            print(string.format("[ %s ] [ %s ] %s", logTime, levelName, message))
        elseif level == LogLevel.WARN then
            ---@diagnostic disable-next-line: param-type-mismatch
            GlobalAPI.warning(string.format("[ %s ] [ %s ] %s", logTime, levelName, message))
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            GlobalAPI.error(string.format("[ %s ] [ %s ] %s", logTime, levelName, message))
        end
    end
end

function Logger.debug(message)
    Logger.log(LogLevel.DEBUG, message)
end

function Logger.info(message)
    Logger.log(LogLevel.INFO, message)
end

function Logger.warn(message)
    Logger.log(LogLevel.WARN, message)
end

function Logger.error(message)
    Logger.log(LogLevel.ERROR, message)
end

function Logger.fatal(message)
    Logger.log(LogLevel.FATAL, message)
end

function Logger.getMinLogLevelName()
    return Logger.LogLevelNames[Logger.minLogLevel]
end

--- @class Triplet
--- @field x number
--- @field y number
--- @field z number
local Triplet = {}
Triplet.__index = Triplet
function Triplet.new(x, y, z)
    if not (x and y and z) then
        Logger.error("The parameter cannot be nil.")
        return nil
    end
    local self = setmetatable({}, Triplet)
    self.x = x
    self.y = y
    self.z = z
    return self
end

function Triplet:toVector3()
    ---@diagnostic disable-next-line: param-type-mismatch
    return GlobalAPI.vector3(self.x, self.y, self.z)
end

function Triplet:zoom(scale)
    return Triplet.new(self.x * scale, self.y * scale, self.z * scale)
end

function Triplet:__add(v2)
    return Triplet.new(self.x + v2.x, self.y + v2.y, self.z + v2.z)
end

function Triplet:__sub(v2)
    return Triplet.new(self.x - v2.x, self.y - v2.y, self.z - v2.z)
end

function Triplet:dot(v2)
    return self.x * v2.x + self.y * v2.y + self.z * v2.z
end

function Triplet:cross(v2)
    return Triplet.new(
        self.y * v2.z - self.z * v2.y,
        self.z * v2.x - self.x * v2.z,
        self.x * v2.y - self.y * v2.x
    )
end

function Triplet:update(x, y, z)
    if not (x and y and z) then
        Logger.error("The parameter cannot be nil.")
        return self
    else
        self.x = x
        self.y = y
        self.z = z
        return self
    end
end

function Triplet:toQuaternion()
    ---@diagnostic disable-next-line: undefined-field
    return math.Quaternion(self.x, self.y, self.z)
end

function Triplet:__tostring()
    return string.format("(%d, %d, %d)", self.x, self.y, self.z)
end

--- 随机数生成器类
--- @class Random
--- @field seed number
--- @field state number
local Random = {}
Random.__index = Random

function Random.new(seed)
    local self = setmetatable({}, Random)
    self.seed = seed or 61
    self.state = seed
    return self
end

function Random:nextInt(bound)
    local xstate = self.state
    xstate = xstate ~ (xstate << 21)
    xstate = xstate ~ (xstate >> 35)
    xstate = xstate ~ (xstate << 4)
    self.state = xstate
    local rand = xstate * 2685821657736338717 % (2 ^ 32)
    if bound then
        return rand % bound
    else
        return rand
    end
end

function Random:nextBoolean()
    return self:nextInt() % 2 == 0
end

function Random:nextFloat()
    return self:nextInt() / 2 ^ 32
end

--- @class Timer
--- @field interval number
--- @field count number
--- @field currentCount number
--- @field immediate boolean
--- @field task function
--- @field enabled boolean
--- @field destroyed boolean
--- @field wrappedCallback function
local Timer = {
    interval = 1.0,
    count = 1,
    currentCount = 0,
    immediate = false,
    task = function() end,
    enabled = false,
    destroyed = false,
    wrappedCallback = function() end,
}
Timer.__index = Timer

function Timer.new(interval, count, immediate, task)
    local self = setmetatable({}, Timer)
    self.interval = interval + 0.0 or 1.0
    self.count = count or 1
    self.currentCount = 0
    self.immediate = immediate or false
    self.task = task
    self.enabled = false
    self.destroyed = false
    self.wrappedCallback = function()
        if self.currentCount < self.count and self.enabled then
            self.currentCount = self.currentCount + 1
            LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
            self.task()
        else
            self.enabled = false
            self.destroyed = true
        end
    end
    return self
end

function Timer:run()
    if self.enabled then
        Logger.error("The timer is running and cannot be enabled repeatedly.")
        return
    elseif self.destroyed then
        Logger.error("The timer has run out.")
        return
    end
    if self.count == 0 then
        return
    end
    self.enabled = true
    if self.immediate then
        self.currentCount = self.currentCount + 1
        LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
        self.task()
    else
        LuaAPI.call_delay_time(self.interval, self.wrappedCallback)
    end
end

function Timer:destroy()
    self.enabled = false
    self.destroyed = true
end

--- @class FrameTimer
--- @field intervalFrames number
--- @field count number
--- @field currentCount number
--- @field immediate boolean
--- @field task function
--- @field enabled boolean
--- @field destroyed boolean
--- @field wrappedCallback function
local FrameTimer = {
    intervalFrames = 1,
    count = 1,
    currentCount = 0,
    immediate = false,
    task = function() end,
    enabled = false,
    destroyed = false,
    wrappedCallback = function() end
}
FrameTimer.__index = FrameTimer

function FrameTimer.new(intervalFrames, count, immediate, task)
    local self = setmetatable({}, FrameTimer)
    self.intervalFrames = intervalFrames or 1
    self.count = count or 1
    self.currentCount = 0
    self.immediate = immediate or false
    self.task = task
    self.enabled = false
    self.destroyed = false
    self.wrappedCallback = function()
        if self.currentCount < self.count and self.enabled then
            self.currentCount = self.currentCount + 1
            LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
            self.task()
        else
            self.enabled = false
            self.destroyed = true
        end
    end
    return self
end

function FrameTimer:run()
    if self.enabled then
        Logger.error("The timer is running and cannot be enabled repeatedly.")
        return
    elseif self.destroyed then
        Logger.error("The timer has run out.")
        return
    end
    if self.count == 0 then
        return
    end
    self.enabled = true
    if self.immediate then
        self.currentCount = self.currentCount + 1
        LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
        self.task()
    else
        LuaAPI.call_delay_frame(self.intervalFrames, self.wrappedCallback)
    end
end

function FrameTimer:destroy()
    self.enabled = false
    self.destroyed = true
end

--- @class 




-- module initialize
-- Do not return this function.
local function init()
    local logo = ">> >> >> BASEBLOCK << << <<\n=======================\nVersion: " .. BaseBlock.VERSION
    print(logo)
    Logger.info(string.format("The initialization log level is [ %s ]", Logger.getMinLogLevelName()))

    UpdateSequence.init()
    Logger.info("Initialize queue of the frame update callback function.")

    Logger.init()
    Logger.info("Log service initialization is complete.")
end

init()
return BaseBlock
