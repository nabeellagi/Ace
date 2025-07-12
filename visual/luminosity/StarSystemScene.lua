-- StarSystemScene.lua

local json = require("json")
local CometBackground = require("CometBackground") -- Require the CometBackground module

local StarSystemScene = {} -- This table will hold all functions and data for this scene

-- Scene-specific variables
local starData
local zoom
local zoomSpeed
local minZoom
local maxZoom

-- Camera position
local cameraX
local cameraY
local cameraMoveSpeed

-- Scale radius (real radius in meters → AU → pixels)
local AU_IN_METERS = 1.496e+11
local PX_PER_AU_INITIAL -- Will be calculated dynamically

local mainFont -- Font for general text
local labelFont -- Font for smaller labels, scaled dynamically

local cometBackground -- Instance of the CometBackground

local planets = {} -- Table to hold planets

-- Sample data.json structure (replace with your actual data.json file)
-- This is assumed based on the provided code's usage of starData fields.
local sampleStarData = {
    luminosity_solar_units = 1.0, -- Example: 1.0 for Sun-like star
    star_radius = { value = 695700000 }, -- Example: Sun's radius in meters
    hex_color = "#FFD700" -- Example: Gold/Yellow color for the star
}

-- Initialize scene variables (called once, outside of love.load equivalent)
function StarSystemScene.init()
    -- Initial values, will be re-calculated in load()
    zoom = 1
    zoomSpeed = 0.05 -- Slower, more controlled zoom
    minZoom = 0.001 -- Allows extreme zoom out for very large systems
    maxZoom = 500 -- Allows extreme zoom in for small systems/planets

    cameraX = 0
    cameraY = 0
    cameraMoveSpeed = 200
end

-- Load function for the Star System Scene
function StarSystemScene:load() -- Changed to colon syntax
    -- Attempt to read data.json, otherwise use sample data
    local fileContent = love.filesystem.read("data.json")
    if fileContent then
        starData = json.decode(fileContent)
    else
        love.filesystem.write("data.json", json.encode(sampleStarData))
        starData = sampleStarData
        print("data.json not found, created a sample data.json. Please restart the application.")
    end

    -- Set nearest-neighbor scaling to prevent blurring for graphics
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Constants
    local sunLuminosity = 3.828e26 -- W

    -- Use given solar unit if available, calculate otherwise
    starData.luminosity_solar = starData.luminosity_solar_units or (starData.luminosity_watt / sunLuminosity)
    starData.luminosity_solar = math.max(starData.luminosity_solar, 0.001) -- Ensure non-zero for sqrt

    -- Habitable zone in AU
    starData.inner_AU = math.sqrt(starData.luminosity_solar / 1.1)
    starData.outer_AU = math.sqrt(starData.luminosity_solar / 0.53)

    -- --- Dynamic PX_PER_AU_INITIAL calculation ---
    -- Determine an initial scaling factor (pixels per AU) dynamically based on the system size.
    -- This ensures the entire system (star to outer HZ or furthest planet) fits on screen.
    local systemMaxRadiusAU = math.max(starData.outer_AU, 10) -- Consider HZ or a fixed large value for initial scale
    for _, planet in ipairs(planets) do -- Also consider furthest pre-defined planet
        systemMaxRadiusAU = math.max(systemMaxRadiusAU, planet.orbital_radius_au * 1.2) -- Add buffer
    end

    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local min_dim = math.min(screen_width, screen_height)

    -- Target: System should take up about 80% of the smallest screen dimension
    PX_PER_AU_INITIAL = (min_dim * 0.4) / systemMaxRadiusAU
    PX_PER_AU_INITIAL = math.max(PX_PER_AU_INITIAL, 5) -- Ensure a minimum scaling for very small systems

    -- Scale star radius from meters to AU to pixels
    local radius_m = starData.star_radius.value
    local radius_au = radius_m / AU_IN_METERS
    starData.star_radius_draw = radius_au * PX_PER_AU_INITIAL

    -- Ensure star is always visible, but not disproportionately huge for tiny stars
    local MIN_STAR_DRAW_SIZE = 5 -- Pixels
    starData.star_radius_draw = math.max(starData.star_radius_draw, MIN_STAR_DRAW_SIZE)
    -- For truly enormous stars, prevent it from taking up the entire screen initially
    local MAX_STAR_SCREEN_FRACTION = 0.4 -- Star takes max 40% of screen width initially
    if starData.star_radius_draw * 2 > screen_width * MAX_STAR_SCREEN_FRACTION then
        starData.star_radius_draw = (screen_width * MAX_STAR_SCREEN_FRACTION) / 2
    end


    -- Convert Hex to RGB
    starData.star_rgb = StarSystemScene.hexToRGB(starData.hex_color)

    -- Fonts: Create fonts once in love.load
    mainFont = love.graphics.newFont(14)
    labelFont = love.graphics.newFont(10) -- A slightly smaller font for labels
    love.graphics.setFont(mainFont)

    -- Initialize CometBackground
    cometBackground = CometBackground.new(love.graphics.getWidth(), love.graphics.getHeight(), {
        numComets = 100, -- More comets for a denser background
        cometSpeed = 70,
        cometTrailLength = 30,
        cometTrailDecay = 0.03,
        cometColor = {0.7, 0.9, 1, 0.6} -- Slightly brighter bluish tint
    })

    -- Define planets (orbital_radius_au, color, speed, current_angle, name)
    -- Ensure planets table is cleared before re-populating on scene load
    planets = {}
    table.insert(planets, {
        orbital_radius_au = starData.inner_AU * 0.7, -- Inside HZ
        color = {0.7, 0.7, 1.0, 1.0}, -- Blueish
        speed = 0.5, -- radians per second
        current_angle = 0,
        name = "Ice Planet",
        radius_px = 5 -- Fixed pixel size for planet
    })
    table.insert(planets, {
        orbital_radius_au = (starData.inner_AU + starData.outer_AU) / 2, -- Within HZ
        color = {0.0, 1.0, 0.0, 1.0}, -- Greenish
        speed = 0.3,
        current_angle = math.pi / 2,
        name = "Terra",
        radius_px = 6 -- Slightly larger
    })
    table.insert(planets, {
        orbital_radius_au = starData.outer_AU * 1.5, -- Outside HZ
        color = {1.0, 0.5, 0.0, 1.0}, -- Orangish
        speed = 0.1,
        current_angle = math.pi,
        name = "Gas Giant",
        radius_px = 8 -- Largest
    })

    -- Reset camera position and zoom when scene loads
    cameraX = 0
    cameraY = 0
    zoom = 1 -- Start with a default zoom, dynamic scaling handled by PX_PER_AU_INITIAL
end

-- Update function for the Star System Scene
function StarSystemScene:update(dt) -- Changed to colon syntax
    -- Update planet positions
    for i, planet in ipairs(planets) do
        planet.current_angle = planet.current_angle + planet.speed * dt
    end

    -- Update CometBackground
    cometBackground:update(dt)

    -- Handle camera movement with WASD
    -- Camera movement speed should also be responsive to zoom
    local currentCameraMoveSpeed = cameraMoveSpeed / zoom
    if love.keyboard.isDown("w") then
        cameraY = cameraY + currentCameraMoveSpeed * dt
    end
    if love.keyboard.isDown("s") then
        cameraY = cameraY - currentCameraMoveSpeed * dt
    end
    if love.keyboard.isDown("a") then
        cameraX = cameraX + currentCameraMoveSpeed * dt
    end
    if love.keyboard.isDown("d") then
        cameraX = cameraX - currentCameraMoveSpeed * dt
    end
end

-- Draw function for the Star System Scene
function StarSystemScene.draw()
    -- Draw CometBackground first, relative to screen, not zoomed
    love.graphics.push()
    cometBackground:draw()
    love.graphics.pop()

    love.graphics.push()
    -- Translate to center of screen and apply camera offset and zoom
    love.graphics.translate(love.graphics.getWidth() / 2 + cameraX * zoom, love.graphics.getHeight() / 2 + cameraY * zoom)
    love.graphics.scale(zoom)

    -- Reset color to white for main elements if needed, or set specifically
    love.graphics.setColor(1, 1, 1)

    -- Draw star
    love.graphics.setColor(starData.star_rgb[1], starData.star_rgb[2], starData.star_rgb[3], 1.0)
    love.graphics.circle("fill", 0, 0, starData.star_radius_draw)

    -- Draw green translucent habitable zone ring
    StarSystemScene.drawRing(starData.inner_AU * PX_PER_AU_INITIAL, starData.outer_AU * PX_PER_AU_INITIAL, {0, 1, 0, 0.3})

    -- Draw dashed HZ boundaries
    love.graphics.setColor(1, 1, 1, 0.7) -- White with some transparency
    love.graphics.setLineWidth(1 / zoom) -- Scale line width with zoom
    StarSystemScene.drawDashedCircle(0, 0, starData.inner_AU * PX_PER_AU_INITIAL, 60)
    StarSystemScene.drawDashedCircle(0, 0, starData.outer_AU * PX_PER_AU_INITIAL, 60)
    love.graphics.setLineWidth(1) -- Reset line width

    -- Draw planets and their orbits
    local MIN_PLANET_DRAW_SIZE = 2 -- pixels
    for i, planet in ipairs(planets) do
        local orbital_radius_px = planet.orbital_radius_au * PX_PER_AU_INITIAL
        local px = math.cos(planet.current_angle) * orbital_radius_px
        local py = math.sin(planet.current_angle) * orbital_radius_px

        -- Draw orbit path (thin line)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Grey, translucent
        love.graphics.setLineWidth(0.5 / zoom) -- Very thin line
        love.graphics.circle("line", 0, 0, orbital_radius_px)
        love.graphics.setLineWidth(1) -- Reset line width

        -- Draw planet
        love.graphics.setColor(planet.color[1], planet.color[2], planet.color[3], planet.color[4])
        -- Ensure planet has a minimum visible size
        local current_planet_radius_draw = math.max(MIN_PLANET_DRAW_SIZE, planet.radius_px / zoom)
        love.graphics.circle("fill", px, py, current_planet_radius_draw)
        
        -- Draw planet label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(labelFont) -- Set font for labels
        love.graphics.printf(planet.name, px - 50 / zoom, py + 10 / zoom, 100 / zoom, "center") -- Scale label position and width
    end

    love.graphics.pop() -- End of zoomed/translated drawing

    -- UI elements (not scaled, always at screen coordinates)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(mainFont) -- Set font for main labels

    -- Display zoom level
    love.graphics.print(string.format("Zoom: %.2f", zoom), 10, 10)

    -- Display star radius
    love.graphics.print("Star Radius: " .. StarSystemScene.sciNotation(starData.star_radius.value) .. " m", 10, 30)

    -- Habitable zone text on the top right
    local screen_width = love.graphics.getWidth()
    local right_margin = 10
    local top_offset = 10

    local hzInnerText = string.format("HZ Inner: %.2f AU", starData.inner_AU)
    local hzOuterText = string.format("HZ Outer: %.2f AU", starData.outer_AU)

    love.graphics.print(hzInnerText, screen_width - mainFont:getWidth(hzInnerText) - right_margin, top_offset)
    love.graphics.print(hzOuterText, screen_width - mainFont:getWidth(hzOuterText) - right_margin, top_offset + 20)

end

-- Mouse wheel event handler for the Star System Scene
function StarSystemScene:wheelmoved(x, y) -- Changed to colon syntax
    -- Exponential zoom centered on mouse cursor (conceptually, implemented by scaling)
    local scaleFactor = 1 + y * zoomSpeed
    local newZoom = math.max(minZoom, math.min(maxZoom, zoom * scaleFactor))

    -- To make zooming feel centered, adjust cameraX/Y based on mouse position
    local mouseX, mouseY = love.mouse.getX(), love.mouse.getY()
    local centerX, centerY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2

    -- Convert mouse position to world coordinates before zoom
    local worldMouseX = (mouseX - (centerX + cameraX * zoom)) / zoom
    local worldMouseY = (mouseY - (centerY + cameraY * zoom)) / zoom

    -- Calculate new camera position to keep the point under the mouse fixed
    local newCameraX = (mouseX - centerX - worldMouseX * newZoom) / newZoom
    local newCameraY = (mouseY - centerY - worldMouseY * newZoom) / newZoom

    cameraX = newCameraX
    cameraY = newCameraY
    zoom = newZoom
end

-- Utility functions (made local to the scene or moved to a shared utility module if needed by both)
function StarSystemScene.hexToRGB(hex)
    if not hex or type(hex) ~= "string" or not hex:match("^#?%x%x%x%x%x%x$") then
        return {1, 1, 1} -- Default to white if hex is invalid
    end
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255
    return {r, g, b}
end

function StarSystemScene.drawRing(inner, outer, color)
    love.graphics.setColor(color)
    love.graphics.circle("fill", 0, 0, outer)
    love.graphics.setColor(0, 0, 0, 1) -- Black to cut out the inner circle
    love.graphics.circle("fill", 0, 0, inner)
end

function StarSystemScene.drawDashedCircle(x, y, radius, segments)
    -- Calculate segment length for dashes
    local circumference = 2 * math.pi * radius
    -- Ensure dashLength is not zero for very small radii.
    local dashLength = math.max(0.001, circumference / segments / 2) -- Length of each dash (half a segment)
    
    for i = 0, segments - 1 do
        -- Draw dash
        local angle1 = (i / segments) * 2 * math.pi
        local angle2 = angle1 + (dashLength / circumference) * 2 * math.pi

        local x1 = x + math.cos(angle1) * radius
        local y1 = y + math.sin(angle1) * radius
        local x2 = x + math.cos(angle2) * radius
        local y2 = y + math.sin(angle2) * radius

        love.graphics.line(x1, y1, x2, y2)
    end
end

function StarSystemScene.sciNotation(val)
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

return StarSystemScene
