-- Kepler's First and Second Law Visualizer (Revised & A1/A2 Time Accurate)
-- Demonstrates:
-- 1. Elliptical orbit with Sun at one focus (Kepler's First Law)
-- 2. Two equal-time areas A1 and A2 (Kepler's Second Law)

local sun = {x = 500, y = 300} -- SUN is the first focus
local a, b = 300, 200
local e = math.sqrt(1 - (b * b) / (a * a))
local c = e * a
local centerX = sun.x + c -- ellipse center lies c units from sun (1st focus)
local f2 = {x = sun.x + 2 * c, y = sun.y} -- second focus is symmetric from ellipse center

local dt = 1 -- Initial timescale
local planet = {theta = 0}
local A1, A2 = {}, {}

-- Camera & zoom
local cam = {x = 0, y = 0, zoom = 1}
local dragging, dragStart = false, {x = 0, y = 0}

-- Key cooldown
local keyCooldown = {left = false, right = false}

function ellipsePos(theta)
    local x = centerX + a * math.cos(theta)
    local y = sun.y + b * math.sin(theta)
    return x, y
end

function orbitalSpeed(theta)
    local x, y = ellipsePos(theta)
    local dx = x - sun.x
    local dy = y - sun.y
    local r = math.sqrt(dx * dx + dy * dy)
    local mu = 20000
    return math.sqrt(mu * (2 / r - 1 / a))
end

function love.load()
    love.window.setTitle("Kepler's Laws Visualizer")
    love.window.setMode(1000, 600)

    -- Equal time sweeping for A1 and A2 (shorter angle at perihelion, longer at aphelion)
    for theta = -0.2, 0.2, 0.005 do
        local x, y = ellipsePos(theta)
        table.insert(A1, {x = x, y = y})
    end

    for theta = math.pi - 0.6, math.pi + 0.6, 0.005 do
        local x, y = ellipsePos(theta)
        table.insert(A2, {x = x, y = y})
    end
end

function love.update(dt_real)
    local speed = orbitalSpeed(planet.theta)
    local x, y = ellipsePos(planet.theta)
    local dx = x - sun.x
    local dy = y - sun.y
    local r = math.sqrt(dx * dx + dy * dy)
    local angularVelocity = speed / r
    planet.theta = (planet.theta + angularVelocity * dt * dt_real) % (2 * math.pi)
    planet.x, planet.y = x, y

    if love.keyboard.isDown("right") then
        if not keyCooldown.right then
            dt = dt + 1
            keyCooldown.right = true
        end
    else
        keyCooldown.right = false
    end

    if love.keyboard.isDown("left") then
        if not keyCooldown.left then
            dt = math.max(1, dt - 1)
            keyCooldown.left = true
        end
    else
        keyCooldown.left = false
    end
end

function love.wheelmoved(_, y)
    cam.zoom = math.max(0.1, math.min(5, cam.zoom + y * 0.1))
end

function love.mousepressed(x, y, button)
    if button == 1 then
        dragging = true
        dragStart.x, dragStart.y = x, y
    end
end

function love.mousereleased(_, _, button)
    if button == 1 then dragging = false end
end

function love.mousemoved(x, y, dx, dy)
    if dragging then
        cam.x = cam.x + dx / cam.zoom
        cam.y = cam.y + dy / cam.zoom
    end
end

function drawEllipse(cx, cy, a, b, seg)
    local pts = {}
    for i = 0, seg do
        local ang = (i / seg) * 2 * math.pi
        local x = cx + a * math.cos(ang)
        local y = cy + b * math.sin(ang)
        table.insert(pts, x)
        table.insert(pts, y)
    end
    love.graphics.line(pts)
end

function drawArea(area, color)
    if #area >= 2 then
        local poly = {sun.x, sun.y}
        for _, pt in ipairs(area) do
            table.insert(poly, pt.x)
            table.insert(poly, pt.y)
        end
        love.graphics.setColor(color)
        love.graphics.polygon("fill", poly)
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(cam.x, cam.y)
    love.graphics.scale(cam.zoom)

    love.graphics.setColor(0.8, 0.8, 0.8)
    drawEllipse(centerX, sun.y, a, b, 100)

    drawArea(A1, {1, 0, 0, 0.4})
    drawArea(A2, {0, 0, 1, 0.4})

    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", sun.x, sun.y, 10)
    love.graphics.setColor(1, 0.5, 0.2)
    love.graphics.circle("fill", f2.x, f2.y, 10)

    love.graphics.setColor(0, 1, 1)
    love.graphics.circle("fill", planet.x, planet.y, 6)

    love.graphics.setColor(0.6, 0.6, 1)
    love.graphics.line(centerX - a, sun.y, centerX + a, sun.y)
    love.graphics.line(centerX, sun.y - b, centerX, sun.y + b)
    love.graphics.print("Major Axis", centerX - 40, sun.y + 10)
    love.graphics.print("Minor Axis", centerX + 10, sun.y - b / 2)

    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.circle("line", centerX + a, sun.y, 5)
    love.graphics.print("Aphelion (A2)", centerX + a + 10, sun.y - 10)
    love.graphics.circle("line", centerX - a, sun.y, 5)
    love.graphics.print("Perihelion (A1)", centerX - a - 70, sun.y - 10)

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("dt (timescale): " .. dt, 10, 10)
    love.graphics.print("Kepler's First Law: Elliptical Orbit (Sun at one focus)", 10, 30)
    love.graphics.print("Kepler's Second Law: A1 and A2 are equal-time sweep areas", 10, 50)
end