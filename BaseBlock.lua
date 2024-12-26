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

--- @class Hash
local Hash = {}
function Hash.toString(input)
    if type(input) == "string" then
        return input
    elseif type(input) == "number" then
        return tostring(input)
    elseif type(input) == "table" then
        local str = ""
        for k, v in pairs(input) do
            str = str .. Hash.toString(k) .. Hash.toString(v)
        end
        return str
    else
        Logger.error("Unsupported type: " .. type(input))
    end
end

function Hash.fastHash(input)
    local str = Hash.toString(input)
    local hash = 0x811C9DC5
    local prime = 0x01000193

    for i = 1, #str do
        hash = hash ~ string.byte(str, i)
        hash = (hash * prime) & 0xFFFFFFFF
    end
    return hash
end

--- @class Vector
--- @field x number
--- @field y number
--- @field z number
local Vector = {}
Vector.__index = Vector
function Vector.new(x, y, z)
    if not (x and y and z) then
        Logger.error("The parameter cannot be nil.")
        return nil
    end
    local self = setmetatable({}, Vector)
    self.x = x
    self.y = y
    self.z = z
    return self
end

function Vector.fromProtoVector()

end

function Vector:toProtoVector()
    ---@diagnostic disable-next-line: param-type-mismatch
    return GlobalAPI.vector3(self.x, self.y, self.z)
end

function Vector:zoom(scale)
    return Vector.new(self.x * scale, self.y * scale, self.z * scale)
end

function Vector:__add(v)
    return Vector.new(self.x + v.x, self.y + v.y, self.z + v.z)
end

function Vector:__sub(v)
    return Vector.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

function Vector:dot(v)
    return self.x * v.x + self.y * v.y + self.z * v.z
end

function Vector:cross(v)
    return Vector.new(
        self.y * v.z - self.z * v.y,
        self.z * v.x - self.x * v.z,
        self.x * v.y - self.y * v.x
    )
end

function Vector:update(x, y, z)
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

function Vector:toQuaternion()
    ---@diagnostic disable-next-line: undefined-field
    return math.Quaternion(self.x, self.y, self.z)
end

function Vector:__tostring()
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

-- TODO: Camp
--- @class Camp
--- @field associativePlayerList table
local Camp = {}
Camp.__index = Camp

function Camp.new()
    local self = setmetatable({}, Camp)
    return self
end

-- Do not return this class
--- @class PlayerMetaInfo
local PlayerMetaInfo = {
    presetTotalPlayerNum = 0,
    originalPlayerNum = 0,
    globalPlayerList = {},
    campList = {}
}



--- @class PlayerManager


--- @enum ObjectType
local ObjectType = {
    COMPONENT = 0,
    TRIGGER = 1,
    LOGIC = 2,
    EFFECT = 3
}



--- @class ObjectRaw
--- @field presetID number
--- @field objectType ObjectType
--- @field position Vector
--- @field rotation Vector
--- @field scale Vector
--- @field player any
--- @field effectOffset Vector
local ObjectRaw = {}
ObjectRaw.__index = ObjectRaw
function ObjectRaw.new()
    local self = setmetatable({}, ObjectRaw)
    return self
end

--- @class Object
--- @field raw ObjectRaw
--- @field protoInstance Unit
local Object = {}
Object.__index = Object
function Object.new(objectRaw, objectInstance)
    local self = setmetatable({}, Object)
    self.raw = objectRaw
    self.protoInstance = objectInstance
    return self
end

function Object:getObjectType()
    return self.raw.objectType
end

function Object:getObjectPosition()
    local retVector = Vector.new()
end

-- GameAPI.create_obstacle(_u_key, _pos, _rotation, _scale, _role)
--- @class Generator
local Generator = {}
--- @param presetID number
--- @param position Vector
--- @param rotation Vector
--- @param scale Vector
function Generator.createComponent(presetID, position, rotation, scale, player)
    --- @diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_obstacle(presetID, position:toProtoVector(), rotation:toQuaternion(), scale:toProtoVector(),
        player)
end

function Generator.createTriggerSpace(presetID, position, rotation, scale, player)
    --- @diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_customtriggerspace(presetID, position:toProtoVector(), rotation:toQuaternion(),
        scale:toProtoVector(), player)
end

function Generator.createLogicSpace(presetID, position, rotation, scale, player)
    --- @diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_triggerspace(presetID, position:toProtoVector(), rotation:toQuaternion(), scale:toProtoVector(),
        player)
end

function Generator.createEffect(presetID, position, rotation, scale, modelSocket, player)
    if modelSocket then
        GameAPI.create_sfx_with_socket_offset()
    end
end

--- @param objectRaw ObjectRaw
function Generator.create(objectRaw)
    if objectRaw.objectType == ObjectType.COMPONENT then
        Generator.createComponent(objectRaw.presetID, objectRaw.position, objectRaw.rotation, objectRaw.scale,
            objectRaw.player)
    end
end

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
