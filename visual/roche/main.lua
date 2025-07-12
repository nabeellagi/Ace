local json = require("json")

-- Constants
local scale_factor = 1e-5 -- Scale meters to pixels
local G = 50000 -- Simulated gravity

function love.load()
    love.window.setTitle("Roche Limit Simulation")
    love.window.setMode(1000, 600)

    local file = love.filesystem.read("data.json")
    local data = json.decode(file)

    -- Convert real-world values to visual scale
    local real_planet_radius = 6371000 -- or use a new field from JSON if needed
    local real_moon_radius = data.satellite_radius.value
    local real_roche_limit = data.roche_limit_m

    planet = {
        x = 500,
        y = 300,
        radius = real_planet_radius * scale_factor,
        density = data.primary_mass.value / ((4/3) * math.pi * real_planet_radius^3),
        color = {0.2, 0.6, 1}
    }

    moon = {
        angle = 0,
        radius = real_moon_radius * scale_factor,
        density = data.satellite_mass.value / ((4/3) * math.pi * real_moon_radius^3),
        color = {1, 0.8, 0.1},
        orbit_radius = real_roche_limit * scale_factor * 1.1,
        orbit_speed = 0.8,
        x = 0,
        y = 0,
        is_collapsed = false,
        fragments = {},
        collapse_timer = 0,
        collapse_threshold = 2
    }

    roche_limit = real_roche_limit * scale_factor
    trail = {}
end


function love.update(dt)
    if not moon.is_collapsed then
        moon.angle = moon.angle + moon.orbit_speed * dt
        moon.x = planet.x + moon.orbit_radius * math.cos(moon.angle)
        moon.y = planet.y + moon.orbit_radius * math.sin(moon.angle)

        table.insert(trail, {x = moon.x, y = moon.y})
        if #trail > 500 then table.remove(trail, 1) end

        -- Check Roche limit condition
        if moon.orbit_radius <= roche_limit then
            moon.collapse_timer = moon.collapse_timer + dt
            if moon.collapse_timer >= moon.collapse_threshold then
                moon.is_collapsed = true
                spawnFragments(moon.x, moon.y)
            end
        else
            moon.collapse_timer = 0 -- reset if it escapes
        end
    else
        updateFragments(dt)
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)

    -- Roche limit ring
    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.circle("line", planet.x, planet.y, roche_limit)

    -- Planet
    love.graphics.setColor(planet.color)
    love.graphics.circle("fill", planet.x, planet.y, planet.radius)

    -- Orbit trail
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = 2, #trail do
        love.graphics.line(trail[i - 1].x, trail[i - 1].y, trail[i].x, trail[i].y)
    end

    -- Moon or Fragments
    if not moon.is_collapsed then
        -- Calculate tidal stretch scale
        local dist = math.sqrt((moon.x - planet.x)^2 + (moon.y - planet.y)^2)
        local stretch_factor = 1 + math.max(0, (roche_limit - dist) / roche_limit * 2)

        -- Elliptical stretch
        love.graphics.setColor(moon.color)
        love.graphics.ellipse("fill", moon.x, moon.y, moon.radius * stretch_factor, moon.radius)
    else
        drawFragments()
    end

    -- Text info
    love.graphics.setColor(1, 1, 1)
    -- Convert pixels back to meters, then to kilometers
    local scale_factor = 1e-5
    local orbit_radius_km = moon.orbit_radius / scale_factor / 1000
    local roche_limit_km = roche_limit / scale_factor / 1000

    love.graphics.print(string.format("Roche Limit: %.2f km", roche_limit_km), 10, 10)
    love.graphics.print(string.format("Current Orbit Radius: %.2f km", orbit_radius_km), 10, 30)


    if not moon.is_collapsed and moon.orbit_radius <= roche_limit then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print(string.format("Collapse in: %.1fs", moon.collapse_threshold - moon.collapse_timer), 10, 50)
    elseif moon.is_collapsed then
        love.graphics.setColor(1, 0.5, 0.5)
        love.graphics.print("Moon COLLAPSED!", 10, 50)
    end
end

function love.wheelmoved(x, y)
    if not moon.is_collapsed then
        moon.orbit_radius = moon.orbit_radius + y * 10
        moon.orbit_radius = math.max(planet.radius + moon.radius + 5, moon.orbit_radius)
    end
end

-- Constants
local G = 50000

function spawnFragments(cx, cy)
    local n = 30
    for i = 1, n do
        local angle = math.rad((i / n) * 360)
        local speed = love.math.random(50, 90)
        local frag = {
            x = cx,
            y = cy,
            vx = speed * math.cos(angle),
            vy = speed * math.sin(angle),
            radius = love.math.random(2, 4),
            mass = 10,
            life = 10
        }
        table.insert(moon.fragments, frag)
    end
end

function updateFragments(dt)
    for i = #moon.fragments, 1, -1 do
        local f = moon.fragments[i]
        local dx = planet.x - f.x
        local dy = planet.y - f.y
        local dist_sq = dx^2 + dy^2
        local dist = math.sqrt(dist_sq)

        local force = G * f.mass / dist_sq
        local ax = force * dx / dist
        local ay = force * dy / dist

        f.vx = f.vx + ax * dt
        f.vy = f.vy + ay * dt
        f.x = f.x + f.vx * dt
        f.y = f.y + f.vy * dt
        f.life = f.life - dt

        if dist <= planet.radius or f.life <= 0 then
            table.remove(moon.fragments, i)
        end
    end
end

function drawFragments()
    for _, f in ipairs(moon.fragments) do
        love.graphics.setColor(1, 0.6, 0.3, math.max(0.2, f.life / 10))
        love.graphics.circle("fill", f.x, f.y, f.radius)
    end
end
