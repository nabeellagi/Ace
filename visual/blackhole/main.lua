-- Load required modules
local json = require("json")
local CometBackground = require("CometBackground")

-- Global variables
local data = {}
local centerX, centerY
local scale = 100
local zoom = 1.0
local particles = {}
local streamEmitters = {}
local externalParticles = {}
local showErgosphere = true
local cometBackgroundInstance

-- Trail settings
local TRAIL_LENGTH = 15
local TRAIL_DECAY = 0.08

local stars = {}
local starMode = false

function love.load()
    love.window.setTitle("Black Hole Visualization")
    love.window.setMode(800, 600)

    local contents = love.filesystem.read("data.json")
    data = json.decode(contents)

    centerX = love.graphics.getWidth() / 2
    centerY = love.graphics.getHeight() / 2

    -- Dynamically adjust scale based on Schwarzschild radius
    local desiredPixelRadius = 80
    scale = desiredPixelRadius / data.schwarzschild_radius_km

    -- Initialize the CometBackground component
    cometBackgroundInstance = CometBackground.new(love.graphics.getWidth(), love.graphics.getHeight(), {
        numComets = 70,
        cometSpeed = 60,
        cometTrailLength = 25,
        cometColor = {0.7, 0.9, 1, 0.4}
    })

    local visual_radius = data.schwarzschild_radius_km * scale
    local ergosphere_radius = visual_radius * 1.1

    for i = 1, 1000 do
        local angle = math.random() * 2 * math.pi
        local r = ergosphere_radius + math.random() * 10
        local speed = 0.5 + math.random()
        local hue = math.random() < 0.5 and {1, 0.6, 0.1} or {1, 0.8, 0.2}
        table.insert(particles, {
            angle = angle,
            radius = r,
            speed = speed,
            color = hue,
            falling = math.random() < 0.05
        })
    end

    for i = 1, 300 do
        local angle = math.random() * 2 * math.pi
        local r = ergosphere_radius + 50 + math.random() * 150
        local speed = 0.1 + math.random() * 0.3
        local target = ergosphere_radius + math.random() * 10
        local hue = {1, 0.5 + math.random() * 0.3, 0.1}
        table.insert(externalParticles, {
            angle = angle,
            radius = r,
            speed = speed,
            color = hue,
            targetRadius = target,
            trail = {}
        })
    end
end

function love.update(dt)
    cometBackgroundInstance:update(dt)

    if showErgosphere then
        for _, p in ipairs(particles) do
            p.angle = (p.angle + p.speed * dt) % (2 * math.pi)
            if p.falling then
                p.radius = p.radius - 10 * dt * zoom
                if p.radius <= 2 then p.radius = 2 end
            end
        end
    end

    for i = #externalParticles, 1, -1 do
        local p = externalParticles[i]
        p.angle = (p.angle + p.speed * dt) % (2 * math.pi)
        local diff = p.radius - p.targetRadius
        if diff > 1 then
            p.radius = p.radius - (diff * 0.3) * dt
        else
            table.insert(particles, {
                angle = p.angle,
                radius = p.radius,
                speed = p.speed,
                color = p.color,
                falling = false
            })
            table.remove(externalParticles, i)
        end
        local x = centerX + math.cos(p.angle) * p.radius * zoom
        local y = centerY + math.sin(p.angle) * p.radius * zoom * 0.7
        table.insert(p.trail, 1, {x = x, y = y})
        if #p.trail > TRAIL_LENGTH then table.remove(p.trail) end
    end

    for i = #streamEmitters, 1, -1 do
        local emitter = streamEmitters[i]
        for j = #emitter, 1, -1 do
            local p = emitter[j]
            p.angle = (p.angle + p.speed * dt) % (2 * math.pi)
            local diff = p.radius - p.targetRadius
            if diff > 1 then
                p.radius = p.radius - (diff * 0.4) * dt
            else
                table.insert(particles, {
                    angle = p.angle,
                    radius = p.radius,
                    speed = p.speed,
                    color = p.color,
                    falling = false
                })
                table.remove(emitter, j)
            end
            local x = centerX + math.cos(p.angle) * p.radius * zoom
            local y = centerY + math.sin(p.angle) * p.radius * zoom * 0.7
            table.insert(p.trail, 1, {x = x, y = y})
            if #p.trail > TRAIL_LENGTH then table.remove(p.trail) end
        end
        if #emitter == 0 then table.remove(streamEmitters, i) end
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    cometBackgroundInstance:draw()

    local visual_radius = data.schwarzschild_radius_km * scale * zoom

    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", centerX, centerY, visual_radius)

    love.graphics.setColor(0.8, 0.8, 1.0, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", centerX, centerY, visual_radius)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", centerX, centerY, 2)

    if showErgosphere then
        for _, p in ipairs(particles) do
            local x = centerX + math.cos(p.angle) * p.radius * zoom
            local y = centerY + math.sin(p.angle) * p.radius * zoom * 0.7
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], 0.8)
            love.graphics.circle("fill", x, y, 1.5 * zoom)
        end
    end

    for _, p in ipairs(externalParticles) do
        for i, pos in ipairs(p.trail) do
            local alpha = math.max(0, p.color[4] or 1 - (i - 1) * TRAIL_DECAY)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.circle("fill", pos.x, pos.y, 0.5 * zoom)
        end
    end

    for _, p in ipairs(externalParticles) do
        local x = centerX + math.cos(p.angle) * p.radius * zoom
        local y = centerY + math.sin(p.angle) * p.radius * zoom * 0.7
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], 0.8)
        love.graphics.circle("fill", x, y, 1.3 * zoom)
    end

    for _, emitter in ipairs(streamEmitters) do
        for _, p in ipairs(emitter) do
            for i, pos in ipairs(p.trail) do
                local alpha = math.max(0, p.color[4] or 1 - (i - 1) * TRAIL_DECAY)
                love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
                love.graphics.circle("fill", pos.x, pos.y, 0.8 * zoom)
            end
        end
    end

    for _, emitter in ipairs(streamEmitters) do
        for _, p in ipairs(emitter) do
            local x = centerX + math.cos(p.angle) * p.radius * zoom
            local y = centerY + math.sin(p.angle) * p.radius * zoom * 0.7
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], 0.9)
            love.graphics.circle("fill", x, y, 2 * zoom)
        end
    end

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Mass: " .. data.mass.coeff .. "e" .. data.mass.exp .. " kg", 10, 10)
    love.graphics.print("Radius: " .. string.format("%.3f km", data.schwarzschild_radius_km), 10, 30)
    love.graphics.print("Zoom: " .. string.format("%.2f", zoom), 10, 50)
    love.graphics.print("[L] Toggle Ergosphere: " .. tostring(showErgosphere), 10, 70)
    love.graphics.print("[Right Click] Emit Spiral Streamline", 10, 90)
end

function love.mousepressed(x, y, button)
    if button == 2 then
        local emitter = {}
        local dx = x - centerX
        local dy = (y - centerY) / 0.7
        local radius = math.sqrt(dx * dx + dy * dy) / zoom
        local angle = math.atan2(dy, dx)
        local targetRadius = data.schwarzschild_radius_km * scale * 1.1 + math.random() * 10

        for i = 1, 40 do
            local offset = (math.random() - 0.5) * 0.4
            local hue = math.random() < 0.5 and {1, 0.7, 0.3} or {1, 0.9, 0.4}
            table.insert(emitter, {
                radius = radius,
                angle = angle + offset,
                speed = 0.5 + math.random(),
                color = hue,
                targetRadius = targetRadius,
                trail = {}
            })
        end
        table.insert(streamEmitters, emitter)
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        zoom = zoom * 1.1
    elseif y < 0 then
        zoom = zoom / 1.1
    end
end

function love.keypressed(key)
    if key == "l" then
        showErgosphere = not showErgosphere
    elseif key == "s" then
        starMode = not starMode
    end
end
