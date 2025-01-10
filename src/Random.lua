--- @class Random
--- @field seed number
--- @field state number
local Random = {}
Random.seed = 61
Random.state = 61
Random.__index = Random

function Random.new(seed)
    local self = setmetatable({}, Random)
    self.seed = seed or 61
    self.state = self.seed
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

return Random
