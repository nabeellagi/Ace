local json = require("json")

-- Physics and orbital data
local data = nil
local T, r, omega

-- Simulation control
local zoom = 1       -- dynamic zoom multiplier
local base_scale = 1e-9
local timeScale = 1  -- dynamic time multiplier
local cx, cy
local star_radius = 10
local time = 0

function love.load()
    love.window.setTitle("Binary Star System Simulation")

    local fileData = love.filesystem.read("data.json")
    data = json.decode(fileData)

    T = data.T_seconds or 1
    r = data.distance_between_stars.value or 1.5e11
    omega = 2 * math.pi / T
    cx, cy = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
end

function love.update(dt)
    time = time + dt * timeScale
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0)

    -- Center of mass
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", cx, cy, 3)

    -- Orbit radius scaled
    local orbit_radius = (r / 2) * base_scale * zoom
    local angle = omega * time

    -- Star positions
    local x1 = cx + orbit_radius * math.cos(angle)
    local y1 = cy + orbit_radius * math.sin(angle)

    local x2 = cx - orbit_radius * math.cos(angle)
    local y2 = cy - orbit_radius * math.sin(angle)

    -- Orbit paths
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle("line", cx, cy, orbit_radius)

    -- Stars
    love.graphics.setColor(1, 0.8, 0)
    love.graphics.circle("fill", x1, y1, star_radius)

    love.graphics.setColor(0.8, 0.6, 1)
    love.graphics.circle("fill", x2, y2, star_radius)

    -- UI Info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Period: %.2f years", data.T_years), 10, 10)
    love.graphics.print(string.format("Period: %.2f days", data.T_days), 150, 10)
    love.graphics.print(string.format("Separation: %.2e m", r), 10, 30)
    love.graphics.print(string.format("Zoom: %.2fx", zoom), 10, 50)
    love.graphics.print(string.format("Time Scale: %.2fx", timeScale), 10, 70)
end

function love.keypressed(key)
    if key == "left" then
        timeScale = math.max(0.1, timeScale / 2)
    elseif key == "right" then
        timeScale = timeScale * 2
    elseif key == "=" or key == "+" then
        zoom = zoom * 1.2
    elseif key == "-" then
        zoom = zoom / 1.2
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        zoom = zoom * 1.1
    elseif y < 0 then
        zoom = zoom / 1.1
    end
end
