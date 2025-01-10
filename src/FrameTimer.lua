local Logger = require("Logger")

---@class FrameTimer
---@field intervalFrames number
---@field count number
---@field currentCount number
---@field immediate boolean
---@field task function
---@field enabled boolean
---@field destroyed boolean
---@field wrappedCallback function
local FrameTimer = {}
FrameTimer.intervalFrames = 1
FrameTimer.count = 1
FrameTimer.currentCount = 0
FrameTimer.immediate = false
FrameTimer.task = function() end
FrameTimer.enabled = false
FrameTimer.destroyed = false
FrameTimer.wrappedCallback = function() end
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

return FrameTimer
