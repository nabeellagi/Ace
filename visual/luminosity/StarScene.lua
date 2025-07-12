-- StarScene.lua

local json = require("json")

local StarScene = {} -- This table will hold all functions and data for this scene

-- Scene-specific variables
local starData
local zoom
local zoomSpeed
local minZoom
local maxZoom
local starRotation
local time
local particles = {}

local PI = math.pi

-- Initialize scene variables (called once, outside of love.load equivalent)
function StarScene.init()
    -- These are initial defaults; they will be adjusted in load() based on star size
    zoom = 1
    zoomSpeed = 0.1
    minZoom = 0.01 -- Allow much deeper zoom out
    maxZoom = 100 -- Allow much closer zoom in
    starRotation = 0
    time = 0
end

-- Load function for the Star Scene
function StarScene:load() -- Changed to colon syntax
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)

    -- Load star data
    local contents = love.filesystem.read("data.json")
    starData = json.decode(contents)

    -- Physical attributes
    -- Fallback to Sun's radius if data is missing, but prioritize data.json
    starData.radius = starData.star_radius.value or 695700000
    starData.surface_area = 4 * PI * starData.radius^2
    starData.volume = (4 / 3) * PI * starData.radius^3

    -- Color
    local r, g, b = StarScene.hexToRGB(starData.hex_color)
    starData.color = { r, g, b, 1.0 }

    -- --- Dynamic Scaling for Star Radius ---
    -- The goal is to make the star visible and reasonably sized on screen,
    -- regardless of its actual astronomical radius.
    -- We use a logarithmic scale to handle vast differences in star sizes (e.g., Sun vs. UY Scuti).
    -- A reference radius (e.g., Sun's radius) is used to normalize the scale.
    local SUN_RADIUS = 6.957e8 -- meters
    local REF_DRAW_RADIUS = 150 -- pixels for a Sun-like star

    -- Calculate a scaling factor. For very large stars, the log helps compress the scale.
    -- For smaller stars, it still provides a reasonable size.
    -- Ensure radius is never zero or negative for log.
    local effectiveRadius = math.max(starData.radius, 1e5) -- Minimum effective radius to avoid log(0)
    local scaleFactor = math.log10(effectiveRadius / SUN_RADIUS)
    -- Adjust the base draw size; this can be fine-tuned.
    -- A linear component (REF_DRAW_RADIUS) combined with a scaled log component.
    starData.radius_draw = REF_DRAW_RADIUS + (scaleFactor * 50) -- Adjust 50 for more or less sensitivity
    starData.radius_draw = math.max(starData.radius_draw, 50) -- Ensure a minimum drawing size

    -- Adjust initial zoom based on star size
    -- For larger stars, start zoomed out more. For smaller, zoom in more.
    -- This helps the star fit the screen initially.
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local min_dim = math.min(screen_width, screen_height)

    -- Calculate initial zoom to fit the star, plus some buffer
    zoom = (min_dim / 2) / (starData.radius_draw * 1.5) -- Make the star take up about 2/3 of the smallest dimension initially
    zoom = math.min(zoom, maxZoom) -- Cap initial zoom at maxZoom
    zoom = math.max(zoom, minZoom) -- Ensure initial zoom is not below minZoom

    -- Particle setup
    particles = {} -- Clear existing particles on load
    -- Adjust particle properties relative to the dynamically calculated starData.radius_draw
    for i = 1, 150 do -- Keep a fixed number of particles, but scale their positions
        table.insert(particles, {
            angle = math.random() * 2 * PI,
            radius = math.random() * starData.radius_draw * (1.2 + math.random() * 0.5), -- Particles spread further
            speed = 0.2 + math.random() * 0.5,
            size = 1 + math.random() * 2,
            alpha = 0.1 + math.random() * 0.2
        })
    end
end

-- Update function for the Star Scene
function StarScene:update(dt) -- Changed to colon syntax
    time = time + dt
    starRotation = starRotation + dt * 0.3

    for _, p in ipairs(particles) do
        p.angle = p.angle + dt * p.speed
        if p.angle > 2 * PI then
            p.angle = p.angle - 2 * PI
        end
    end
end

-- Draw function for the Star Scene
function StarScene.draw()
    love.graphics.push()
    love.graphics.scale(zoom, zoom)

    local cx, cy = love.graphics.getWidth() / (2 * zoom), love.graphics.getHeight() / (2 * zoom)

    -- Pulsating effect based on time
    local pulse = 1 + 0.05 * math.sin(time * 2)
    local glow_radius = starData.radius_draw * pulse

    -- Layered glow (scaled by zoom implicitly due to push/pop and scale)
    for i = 1, 10 do
        local alpha = 0.04 * (11 - i)
        love.graphics.setColor(starData.color[1], starData.color[2], starData.color[3], alpha)
        love.graphics.circle("fill", cx, cy, glow_radius + i * (6 / zoom)) -- Scale glow layers with zoom
    end

    -- Star body
    love.graphics.setColor(starData.color)
    love.graphics.circle("fill", cx, cy, glow_radius)

    -- Rotating bubbles (scaled implicitly)
    for i = 0, 2 * PI, PI / 12 do
        local r = glow_radius * 0.85
        local x = cx + r * math.cos(i + starRotation)
        local y = cy + r * math.sin(i + starRotation)
        love.graphics.setColor(1, 1, 1, 0.08)
        love.graphics.circle("fill", x, y, 8 / zoom) -- Scale bubble size with zoom
    end

    -- Glowing particles (scaled implicitly)
    for _, p in ipairs(particles) do
        local px = cx + p.radius * math.cos(p.angle)
        local py = cy + p.radius * math.sin(p.angle)
        love.graphics.setColor(starData.color[1], starData.color[2], starData.color[3], p.alpha)
        love.graphics.circle("fill", px, py, p.size / zoom) -- Scale particle size with zoom
    end

    love.graphics.pop()

    -- UI (not scaled, always at screen coordinates)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14)) -- Ensure UI font is consistent
    love.graphics.print(string.format("Zoom: %.2f", zoom), 10, 10)
    -- Fixed: Added more precision to scientific notation for display
    love.graphics.print("Hex Color: " .. (starData.hex_color or "N/A"), 10, 30)
    love.graphics.print("Radius: " .. StarScene.sciNotation(starData.radius) .. " m", 10, 50)
    love.graphics.print("Surface Area: " .. StarScene.sciNotation(starData.surface_area) .. " m²", 10, 70)
    love.graphics.print("Volume: " .. StarScene.sciNotation(starData.volume) .. " m³", 10, 90)
end

-- Mouse wheel event handler for the Star Scene
function StarScene:wheelmoved(_, y) -- Already colon syntax, confirming consistency
    local oldZoom = zoom
    if y > 0 then
        -- Zoom in: faster when already zoomed in
        zoom = math.min(zoom * (1 + zoomSpeed), maxZoom)
    elseif y < 0 then
        -- Zoom out: slower when already zoomed out
        zoom = math.max(zoom * (1 - zoomSpeed), minZoom)
    end
end

-- Utility functions
function StarScene.hexToRGB(hex)
    if not hex or type(hex) ~= "string" or not hex:match("^#?%x%x%x%x%x%x$") then
        return 1, 1, 1
    end
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then
        return r / 255, g / 255, b / 255
    else
        return 1, 1, 1
    end
end

function StarScene.sciNotation(val)
    -- Updated: Format base to limit decimal places for readability
    if val == 0 then return "0" end
    local base, exp = ("%e"):format(val):match("([^e]+)e([+-]?%d+)")
    if base and exp then
        -- Format base to limit decimal places, e.g., 3.847
        local formatted_base = string.format("%.3f", tonumber(base))
        return string.format("%s × 10^%d", formatted_base, tonumber(exp))
    else
        return tostring(val) -- Fallback for non-scientific format numbers
    end
end

return StarScene
