local Logger = require("Logger")


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

return Timer