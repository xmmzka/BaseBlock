--[[
    File: BaseBlock.lua
    Description: Lua framework to simplify Eggy code API calls.
    Author: circute
    Date: 2024-12-23
    Version: 0.0.1_20241228-Alpha
]]


---@module "BaseBlock"
local BaseBlock = {
    VERSION = "0.0.1_20241228-Alpha",
    LOGICAL_FRAME_RATE = 30,
    LOGICAL_FRAME_INTERVAL = 0.033333333
}


---@class Util
local Util = {}

---@param table table
---@param elem any
---@return number|nil
function Util.indexOf(table, elem)
    if elem == nil then
        return nil
    end
    for index, value in ipairs(table) do
        if value == elem then
            return index
        end
    end
    return nil
end

function Util.contains(table, elem)
    for index, value in ipairs(table) do
        if value == elem then
            return true
        end
    end
    return false
end

-- function Util.copy(obj, copyCache)
--     if type(obj) ~= "table" then
--         return obj
--     end

--     if copyCache and copyCache[obj] then
--         return copyCache[obj]
--     end

--     local copy = {}
--     copyCache = copyCache or {}
--     copyCache[obj] = copy

--     for key, value in pairs(obj) do
--         copy[Util.copy(key, copyCache)] = Util.copy(value, copyCache)
--     end

--     return copy
-- end


-- Do not return this class.
---@class FrameMetaData
---@field framCount number
---@field frameworkFixedUpdateSequence table
---@field frameworkLateUpdateSequence table
---@field fixedUpdateSequence table
---@field lateUpdateSequence table
local FrameMetaData = {
    frameCount = 0,
    frameworkFixedUpdateSequence = {},
    frameworkLateUpdateSequence = {},
    fixedUpdateSequence = {},
    lateUpdateSequence = {}
}


function FrameMetaData.preHandlerWrapper()
    FrameMetaData.frameCount = FrameMetaData.frameCount + 1
    for key, value in pairs(FrameMetaData.frameworkFixedUpdateSequence) do
        value()
    end
    for key, value in pairs(FrameMetaData.fixedUpdateSequence) do
        value()
    end
end

function FrameMetaData.lateHandlerWrapper()
    for key, value in pairs(FrameMetaData.frameworkLateUpdateSequence) do
        value()
    end
    for key, value in pairs(FrameMetaData.lateUpdateSequence) do
        value()
    end
end

function FrameMetaData.init()
    LuaAPI.set_tick_handler(FrameMetaData.preHandlerWrapper, FrameMetaData.lateHandlerWrapper)
end

---@class Frame
local Frame = {}
function Frame.getFixedUpdateFunctionSequence()
    return FrameMetaData.fixedUpdateSequence
end

function Frame.getLateUpdateFunctionSequence()
    return FrameMetaData.lateUpdateSequence
end

function Frame.getFrameCount()
    return FrameMetaData.frameCount
end

---@enum LogLevel
local LogLevel = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

---@class Logger
---@field minLogLevel LogLevel
---@field initialized boolean
local Logger = {
    minLogLevel = LogLevel.DEBUG,
    ---@enum LogLevelNames
    LogLevelNames = {
        [LogLevel.DEBUG] = "D",
        [LogLevel.INFO] = "I",
        [LogLevel.WARN] = "W",
        [LogLevel.ERROR] = "E",
        [LogLevel.FATAL] = "F"
    }
}

---@param minLogLevel LogLevel
function Logger.setLogLevel(minLogLevel)
    Logger.minLogLevel = minLogLevel or LogLevel.DEBUG
end

---@param level LogLevel
---@param message string
function Logger.log(level, message)
    if level >= Logger.minLogLevel then
        local levelName = Logger.LogLevelNames[level]
        local logTime = Frame.getFrameCount() / BaseBlock.LOGICAL_FRAME_RATE
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

---@param message string
function Logger.debug(message)
    Logger.log(LogLevel.DEBUG, message)
end

---@param message string
function Logger.info(message)
    Logger.log(LogLevel.INFO, message)
end

---@param message string
function Logger.warn(message)
    Logger.log(LogLevel.WARN, message)
end

---@param message string
function Logger.error(message)
    Logger.log(LogLevel.ERROR, message)
end

---@param message string
function Logger.fatal(message)
    Logger.log(LogLevel.FATAL, message)
end

---@return string
function Logger.getMinLogLevelName()
    return Logger.LogLevelNames[Logger.minLogLevel]
end

---@class Hash
local Hash = {}

---@param input any
---@return string|nil
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
        return nil
    end
end

---@param input any
---@return integer|nil
function Hash.fastHash(input)
    local str = Hash.toString(input)
    if str == nil then
        return nil
    end
    local hash = 0x811C9DC5
    local prime = 0x01000193

    for i = 1, #str do
        hash = hash ~ string.byte(str, i)
        hash = (hash * prime) & 0xFFFFFFFF
    end
    return hash
end

---@class Test
---@field functionNum number
---@field functionList table
---@field result table
---@field success number
---@field failures number
local Test = {
    functionNum = 0,
    functionList = {},
    result = {},
    success = 0,
    failures = 0
}

function Test.init()
    Logger.info("Initialize unit test.")

    Test.functionNum = 0
    Test.functionList = {}
    Test.result = {}
    Test.success = 0
    Test.failures = 0

    local testFunctionList = require("Test")
    if testFunctionList then
        Logger.info("Locate test file in directory.")
        local testCount = 0
        for key, value in pairs(testFunctionList) do
            if type(value) == "function" then
                testCount = testCount + 1
                Test.functionList[key] = value
            end
        end
        Test.functionNum = testCount
    else
        Logger.info("Skip test.")
    end
end

function Test.test()
    for key, value in pairs(Test.functionList) do
        Test.result[key] = {
            status = nil,
            result = nil
        }
        local status, result = pcall(value)
        Test.result[key].status = status
        Test.result[key].result = result
        if status then
            Test.success = Test.success + 1
        else
            Test.failures = Test.failures + 1
        end
    end
end

function Test.output()
    local consoleOutputHead = string.format("[ UNIT TEST ]\nTimestamp: %s\nSuccess: %s\nFailures: %s\n\n", Frame.getFrameCount(), Test.success, Test.failures)
    local consoleOutputBody = ""
    for key, value in pairs(Test.result) do
        if value.status ~= true then
            consoleOutputBody = consoleOutputBody .. string.format("function: %s >>>>>>>>>>\ninfo: %s\n\n", key, value.result)
        end
    end
    local consoleOutputTail = ""
    if Test.success ~= Test.functionNum then
        consoleOutputTail = ">> FAILURE <<"
    else
        consoleOutputTail = ">> SUCCESS <<"
    end
    print(consoleOutputHead .. consoleOutputBody .. consoleOutputTail)
end

---@param expected any
---@param actual any
function Test.Assert(expected, actual)
    if expected ~= actual then
        error("Assert Failed! expected: " .. expected .. ", actual: " .. actual)
    end
end

---@class Vector
---@field x number
---@field y number
---@field z number
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

---@diagnostic disable-next-line: undefined-doc-name
---@param vector3 Vector3
---@return Vector|nil
function Vector.fromProtoVector(vector3)
---@diagnostic disable-next-line: undefined-field
    return Vector.new(vector3.x, vector3.y, vector3.z)
end

---@return Vector3
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
---@class Random
---@field seed number
---@field state number
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

---@class Timer
---@field interval number
---@field count number
---@field currentCount number
---@field immediate boolean
---@field task function
---@field enabled boolean
---@field destroyed boolean
---@field wrappedCallback function
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

---@class FrameTimer
---@field intervalFrames number
---@field count number
---@field currentCount number
---@field immediate boolean
---@field task function
---@field enabled boolean
---@field destroyed boolean
---@field wrappedCallback function
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

-- Do not return this class
---@class PlayerMetaInfo
local PlayerMetaInfo = {
    -- 进入游戏的初始玩家数
    originalPlayerNum = 0,
    -- 阵营计数
    campNum = 0,
    -- 原始类型的玩家索引表
    globalProtoPlayerList = {},
    -- 原始类型的阵营索引列表 key: index, value: protoCamp
    globalprotoCampList = {},
    -- 阵营Name索引表
    globalprotoCampNameList = {},
    -- 按阵营分组的玩家列表
    campPlayerGroupList = {},
    -- 按globalProtoPlayerList排序的原始类型角色列表 value: unit
    globalProtoRoleList = {},
}

function PlayerMetaInfo.init()
    local protoCampManager = GameAPI.get_camp_mgr()
    local tempProtoCampList = protoCampManager.get_all_camps()
    -- 初始化阵营表
    local campCount = 0
    for index, value in ipairs(tempProtoCampList) do
        campCount = campCount + 1
        PlayerMetaInfo.globalprotoCampList[campCount] = value
        PlayerMetaInfo.globalprotoCampNameList[campCount] = value.get_name()
    end
    PlayerMetaInfo.campNum = campCount
    -- 初始化角色表，玩家表
    local tempRoleList = GameAPI.get_map_characters()
    local indexCount = 0
    for index, value in ipairs(tempRoleList) do
        indexCount = indexCount + 1
        table.insert(PlayerMetaInfo.globalProtoRoleList, indexCount, value)
        table.insert(PlayerMetaInfo.globalProtoPlayerList, indexCount, value.get_ctrl_role())
    end
    -- 初始化阵营组索引表
    for index, player in ipairs(PlayerMetaInfo.globalProtoPlayerList) do
        local camp = player.get_camp()
        local campID = Util.indexOf(PlayerMetaInfo.globalprotoCampList, camp)
        if campID == nil then
            Logger.warn("Players with an unknown faction are automatically classified as [unknown].")
            if PlayerMetaInfo.campPlayerGroupList["unknown"] == nil then
                PlayerMetaInfo.campPlayerGroupList["unknown"] = {}
            end
            table.insert(PlayerMetaInfo.campPlayerGroupList["unknown"], Util.indexOf(PlayerMetaInfo.globalProtoPlayerList(player)))
        else
            if PlayerMetaInfo.campPlayerGroupList[campID] == nil then
                PlayerMetaInfo.campPlayerGroupList[campID] = {}
            end
            table.insert(PlayerMetaInfo.campPlayerGroupList[campID], Util.indexOf(PlayerMetaInfo.globalProtoPlayerList, player))
        end
    end
end

---@class PlayerManager
local PlayerManager = {}

function PlayerManager.getPlayerIndexByProto(player)
    local playerIndex = Util.indexOf(PlayerMetaInfo.globalProtoPlayerList, player)
    if playerIndex then
        return playerIndex
    else
        Logger.error("The player for the query does not exist.")
        return nil
    end
end

function PlayerManager.getProtoPlayerByIndex(playerIndex)
    if playerIndex == nil then
        return nil
    end
    if playerIndex > PlayerMetaInfo.originalPlayerNum then
        Logger.error("The player index for the query does not exist.")
        return nil
    else
        if PlayerMetaInfo.globalProtoPlayerList[playerIndex] == nil then
            Logger.warn("The index points to a player with a null value.")
        end
        return PlayerMetaInfo.globalProtoPlayerList[playerIndex]
    end
end

function PlayerManager.getFrameworkPlayerMetaData()
    return PlayerMetaInfo
end

function PlayerManager.getPlayerNameByIndex(playerIndex)
    local player = PlayerManager.getProtoPlayerByIndex(playerIndex)
    if player then
        return string(player.get_name())
    else
        return nil
    end
end

---@enum ObjectType
local ObjectType = {
    COMPONENT = 0,
    TRIGGER = 1,
    LOGIC = 2,
    EFFECT = 3
}



---@class ObjectRaw
---@field presetID number
---@field objectType ObjectType
---@field position Vector
---@field rotation Vector
---@field scale Vector
---@field playerIndex number
---@field effectOffset Vector
local ObjectRaw = {}
ObjectRaw.__index = ObjectRaw
function ObjectRaw.new()
    local self = setmetatable({}, ObjectRaw)
    return self
end

---@class Object
---@field raw ObjectRaw
---@field protoInstance Unit
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

-- Do not return this class
---@class GeneratorCore
local GeneratorCore = {}


---@class Generator
local Generator = {}

--- 此函数为API的封装，可以直接
---@param presetID number
---@param position Vector
---@param rotation Vector
---@param scale Vector
function Generator.createComponent(presetID, position, rotation, scale, playerIndex)
    local protoPlayer = PlayerManager.getProtoPlayerByIndex(playerIndex)
    if protoPlayer == nil then
        Logger.warn("The playerIndex does not exist, use nil instead.")
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_obstacle(presetID, position:toProtoVector(), rotation:toQuaternion(), scale:toProtoVector(), protoPlayer)
end

function Generator.createTriggerSpace(presetID, position, rotation, scale, playerIndex)
    local protoPlayer = PlayerManager.getProtoPlayerByIndex(playerIndex)
    if protoPlayer == nil then
        Logger.warn("The playerIndex does not exist, use nil instead.")
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_customtriggerspace(presetID, position:toProtoVector(), rotation:toQuaternion(), scale:toProtoVector(), protoPlayer)
end

function Generator.createLogicSpace(presetID, position, rotation, scale, playerIndex)
    local protoPlayer = PlayerManager.getProtoPlayerByIndex(playerIndex)
    if protoPlayer == nil then
        Logger.warn("The playerIndex does not exist, use nil instead.")
    end
    ---@diagnostic disable-next-line: param-type-mismatch
    return GameAPI.create_triggerspace(presetID, position:toProtoVector(), rotation:toQuaternion(), scale:toProtoVector(), protoPlayer)
end

---@param objectRaw ObjectRaw
function Generator.create(objectRaw)
    local protoObject = nil
    if objectRaw.objectType == ObjectType.COMPONENT then
        protoObject = Generator.createComponent(objectRaw.presetID, objectRaw.position, objectRaw.rotation, objectRaw.scale, objectRaw.playerIndex)
    elseif objectRaw.objectType == ObjectType.TRIGGER then
        protoObject = Generator.createTriggerSpace(objectRaw.presetID, objectRaw.position, objectRaw.rotation, objectRaw.scale, objectRaw.playerIndex)
    elseif objectRaw.objectType == ObjectType.LOGIC then
        protoObject = Generator.createLogicSpace(objectRaw.presetID, objectRaw.position, objectRaw.rotation, objectRaw.scale, objectRaw.playerIndex)
    elseif objectRaw.objectType == ObjectType.EFFECT then
        -- TODO: effect
    else
        Logger.error("Unknown ObjectType of objectRaw.")
    end

    if protoObject == nil then
        return nil
    else
        -- TODO
        return Object.new(protoObject, Util.copy(objectRaw))
    end
end


---@class Audio
local Audio = {
    ---@enum Tamber
    Tamber = {
        PIANO = 0,
        STRINGS = 1,
        ACOUSTIC_GUITAR = 2,
        CLEAN_ELECTRIC_GUITAR = 3,
        BROKEN_ELECTRIC_GUITAR = 4,
        DISTORTION_ELECTRIC_GUITAR = 5,
        ELECTRIC_BASS = 6,
        BRASS = 7
    },
    NoteName = {
        C = "c",
        D = "d",
        E = "e",
        F = "f",
        G = "g",
        A = "a",
        B = "b"
    },
    NoteGroup = {
        1, 2, 3, 4, 5, 6, 7, 8, 9
    }
    
}
function Audio.playNote(tamber, pitch, duration)
    if not Util.contains(Audio.Tamber, tamber)  then
        Logger.error("Unsupported tamber.")
        return
    end
    if #pitch > 3 then
        Logger.error("Incorrect pitch string formatting.")
        return
    end
    local noteName = string.sub(pitch, 1, 1)
    local noteGroup = string.sub(pitch, 2, 2)

    if not Util.contains(Audio.NoteName, noteName) or noteGroup then
        Logger.error("Incorrect pitch string formatting.")
    end
    local offsetEnabled = false
    if #pitch == 3 then
        if string.sub(pitch, 3, 3) == "#" then
            offsetEnabled = true
        end
    end

    GameAPI.play_3d_sound_with_params()

end



-- Framework initialized flag
-- Do not return this variable
local frameworkLoaded = false

-- module initialize
-- Do not return this function.
local function init()
    if frameworkLoaded then
        return
    end
    local logo = ">> >> >> BASEBLOCK << << <<\n=======================\nVersion: " .. BaseBlock.VERSION
    print(logo)

    Logger.info(string.format("The initialization log level is [ %s ]", Logger.getMinLogLevelName()))

    FrameMetaData.init()
    Logger.info("Initialize queue of the frame update callback function.")

    PlayerMetaInfo.init()
    Logger.info("PlayerMetaInfo is loaded.")
    -- Must Before test
    frameworkLoaded = true
    -- Run test offset: 1.0s
    Timer.new(1.0, 1, false, function()
        Test.init()
        Test.test()
        Test.output()
    end):run()
end

BaseBlock.Test = Test
BaseBlock.Timer = Timer
BaseBlock.FrameTimer = FrameTimer
BaseBlock.Object = Object
BaseBlock.ObjectRaw = ObjectRaw
BaseBlock.Logger = Logger
BaseBlock.Util = Util
BaseBlock.Generator = Generator
BaseBlock.Frame = Frame
BaseBlock.PlayerManager = PlayerManager
BaseBlock.Random = Random
BaseBlock.Hash = Hash
BaseBlock.Vector = Vector
BaseBlock.LogLevel = LogLevel
BaseBlock.ObjectType = ObjectType



init()
return BaseBlock
