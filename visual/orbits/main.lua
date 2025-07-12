local json = require("json")
local planets = {}
local central_mass
local background

-- Constants
local G = 6.67430e-11
local AU = 149.6e9
local base_scale = 100 / AU
local zoom = 1.0
local scale = base_scale
local planet_radius = 6
local star_radius = 30
local eccentricity = 0.6  -- assumed same for all
local time_scale = 50000

-- Central position
local cx, cy

-- Kepler's Equation solver
local function solveE(M, e)
    local E = M
    for _ = 1, 5 do
        E = E - (E - e * math.sin(E) - M) / (1 - e * math.cos(E))
    end
    return E
end

-- Calculate position from time using elliptical orbit
local function getPosition(t, a, e, T)
    local M = 2 * math.pi * (t % T) / T
    local E = solveE(M, e)
    local x = a * (math.cos(E) - e)
    local b = a * math.sqrt(1 - e^2)
    local y = b * math.sin(E)
    return x, y
end

-- Calculate static ellipse points
local function generateEllipsePoints(a, e)
    local points = {}
    local b = a * math.sqrt(1 - e^2)
    for theta = 0, 2 * math.pi, math.rad(2) do
        local x = a * math.cos(theta) - a * e
        local y = b * math.sin(theta)
        table.insert(points, {x = x, y = y})
    end
    return points
end

function love.load()
    background = love.graphics.newImage("assets/nebula.png")
    background:setWrap("repeat", "repeat")
    background:setFilter("nearest", "nearest")

    love.graphics.setDefaultFilter("nearest", "nearest")
    cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2

    local file = love.filesystem.read("data.json")
    local data = json.decode(file)
    central_mass = data.central_mass.value

    for _, planet in ipairs(data.planets) do
        local a = planet.semi_major_axis.value
        local T = planet.T_seconds
        local e = planet.eccentricity or 0.0
        local color = {
            r = love.math.random(),
            g = love.math.random(),
            b = love.math.random()
        }

        table.insert(planets, {
            name = planet.planet,
            a = a,
            T = T,
            e = e,
            t = math.random() * T,
            color = color,
            path = {},
            ellipse_points = generateEllipsePoints(a, e)
        })
    end
end

function love.update(dt)
    for _, planet in ipairs(planets) do
        planet.t = planet.t + dt * time_scale
        local x, y = getPosition(planet.t, planet.a, planet.e, planet.T)
        table.insert(planet.path, { x = x, y = y })
        if #planet.path > 1000 then
            table.remove(planet.path, 1)
        end
    end
end

function love.draw()
    love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight())

    cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
    scale = base_scale * zoom

    -- Draw central star with zoom-scaled size
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", cx, cy, star_radius * zoom)

    for _, planet in ipairs(planets) do
        -- White Elliptical Path
        love.graphics.setColor(1, 1, 1, 0.2)
        for i = 2, #planet.ellipse_points do
            local p1 = planet.ellipse_points[i - 1]
            local p2 = planet.ellipse_points[i]
            love.graphics.line(
                cx + p1.x * scale, cy + p1.y * scale,
                cx + p2.x * scale, cy + p2.y * scale
            )
        end

        -- Colored trail
        love.graphics.setColor(planet.color.r, planet.color.g, planet.color.b, 0.3)
        for i = 2, #planet.path do
            local p1 = planet.path[i - 1]
            local p2 = planet.path[i]
            love.graphics.line(
                cx + p1.x * scale, cy + p1.y * scale,
                cx + p2.x * scale, cy + p2.y * scale
            )
        end

        -- Current position
        local x, y = getPosition(planet.t, planet.a, planet.e, planet.T)
        local drawX = cx + x * scale
        local drawY = cy + y * scale

        love.graphics.setColor(planet.color.r, planet.color.g, planet.color.b)
        love.graphics.circle("fill", drawX, drawY, planet_radius)

        -- Label
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(planet.name, drawX + 6, drawY + 6)
    end

    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Zoom: " .. string.format("%.2f", zoom) .. "x", 10, 10)
    love.graphics.print("Time Scale: " .. string.format("%.0f", time_scale) .. "x", 10, 30)
end

function love.keypressed(key)
    if key == "up" then
        zoom = math.min(zoom * 1.2, 10.0)
    elseif key == "down" then
        zoom = math.max(zoom / 1.2, 0.05)
    elseif key == "left" then
        time_scale = math.max(1000, time_scale / 2)
    elseif key == "right" then
        time_scale = math.min(2e6, time_scale * 2)
    elseif key == "w" then
        planet_radius = planet_radius + 1
    elseif key == "s" then
        planet_radius = math.max(1, planet_radius - 1)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        zoom = math.min(zoom * 1.1, 10.0)
    elseif y < 0 then
        zoom = math.max(zoom / 1.1, 0.05)
    end
end