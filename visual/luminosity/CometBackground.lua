-- CometBackground.lua

local CometBackground = {}
CometBackground.__index = CometBackground

-- Comet settings (can be customized when creating an instance)
local DEFAULT_NUM_COMETS = 50
local DEFAULT_COMET_SPEED = 50 -- Pixels per second
local DEFAULT_COMET_TRAIL_LENGTH = 20 -- Longer trail for comets
local DEFAULT_COMET_TRAIL_DECAY = 0.05
local DEFAULT_COMET_COLOR = {0.8, 0.8, 1, 0.5} -- Bluish, semi-transparent

--- Creates a new CometBackground instance.
-- @param screenWidth The width of the screen.
-- @param screenHeight The height of the screen.
-- @param settings (optional) A table to override default settings (e.g., {numComets = 100, cometSpeed = 70})
function CometBackground.new(screenWidth, screenHeight, settings)
    local self = setmetatable({}, CometBackground)

    settings = settings or {}
    self.numComets = settings.numComets or DEFAULT_NUM_COMETS
    self.cometSpeed = settings.cometSpeed or DEFAULT_COMET_SPEED
    self.cometTrailLength = settings.cometTrailLength or DEFAULT_COMET_TRAIL_LENGTH
    self.cometTrailDecay = settings.cometTrailDecay or DEFAULT_COMET_TRAIL_DECAY
    self.cometColor = settings.cometColor or DEFAULT_COMET_COLOR

    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.comets = {}

    self:initializeComets()

    return self
end

function CometBackground:initializeComets()
    for i = 1, self.numComets do
        local x = math.random(0, self.screenWidth)
        local y = math.random(0, self.screenHeight)
        local angle = math.random() * 2 * math.pi -- Direction of travel
        local speed = self.cometSpeed * (0.8 + math.random() * 0.4) -- Slightly varied speed
        local hue = {
            self.cometColor[1] * (0.9 + math.random() * 0.2),
            self.cometColor[2] * (0.9 + math.random() * 0.2),
            self.cometColor[3] * (0.9 + math.random() * 0.2),
            self.cometColor[4]
        } -- Slightly varied color around the base

        table.insert(self.comets, {
            x = x,
            y = y,
            angle = angle,
            speed = speed,
            color = hue,
            trail = {}
        })
    end
end

--- Updates the positions and trails of all comets.
-- @param dt Delta time.
function CometBackground:update(dt)
    for i = #self.comets, 1, -1 do
        local comet = self.comets[i]
        comet.x = comet.x + math.cos(comet.angle) * comet.speed * dt
        comet.y = comet.y + math.sin(comet.angle) * comet.speed * dt

        -- Wrap around screen
        if comet.x < 0 then comet.x = self.screenWidth
        elseif comet.x > self.screenWidth then comet.x = 0 end
        if comet.y < 0 then comet.y = self.screenHeight
        elseif comet.y > self.screenHeight then comet.y = 0 end

        -- Update trail
        table.insert(comet.trail, 1, {x = comet.x, y = comet.y})
        if #comet.trail > self.cometTrailLength then
            table.remove(comet.trail)
        end
    end
end

--- Draws all comets and their trails.
function CometBackground:draw()
    -- Ensure rendering is done from the correct perspective if camera is used
    -- For this simple background, no complex transformations are needed.

    for _, comet in ipairs(self.comets) do
        -- Draw trail
        for i, pos in ipairs(comet.trail) do
            local alpha = math.max(0, comet.color[4] - (i - 1) * self.cometTrailDecay)
            love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], alpha)
            love.graphics.circle("fill", pos.x, pos.y, 0.5) -- Smaller trail particles
        end
        -- Draw comet head
        love.graphics.setColor(comet.color[1], comet.color[2], comet.color[3], comet.color[4] * 1.5) -- Slightly brighter head
        love.graphics.circle("fill", comet.x, comet.y, 1.5)
    end
end

return CometBackground