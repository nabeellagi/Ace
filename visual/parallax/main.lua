-- main.lua
local zoom = 1
local camX, camY = 0, 0
local dragging = false
local dragStart = {x = 0, y = 0}
local cameraStart = {x = 0, y = 0}

local sun = { x = 0, y = 0 }
local earth = { radius = 200, angle = 0 }
local star = { x = 1000, y = -50 } -- distant star
local time = 0
local font
local timescale = 1

function love.load()
    love.window.setTitle("Parallax Astronomy Simulation")
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    love.graphics.setDefaultFilter("nearest", "nearest")
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)
end

function love.update(dt)
    time = time + dt * timescale
    earth.angle = (time * 0.2) % (2 * math.pi)
end

function love.draw()
    -- Draw fixed HUD text first
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Use Mouse Wheel to Zoom | Drag Left Click to Move Camera", 10, 10)
    love.graphics.print("Left/Right Arrows to Adjust Timescale", 10, 30)

    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2 + camX, love.graphics.getHeight()/2 + camY)
    love.graphics.scale(zoom)

    -- Draw orbit
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.circle("line", sun.x, sun.y, earth.radius)

    -- Draw Sun
    love.graphics.setColor(1, 1, 0)
    love.graphics.circle("fill", sun.x, sun.y, 15)

    -- Earth position
    local earthX = sun.x + math.cos(earth.angle) * earth.radius
    local earthY = sun.y + math.sin(earth.angle) * earth.radius

    love.graphics.setColor(0, 0.5, 1)
    love.graphics.circle("fill", earthX, earthY, 8)

    -- Draw star
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", star.x, star.y, 12)

    -- Parallax lines
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.line(earthX, earthY, star.x, star.y)

    -- Second Earth (opposite side)
    local oppositeX = sun.x + math.cos(earth.angle + math.pi) * earth.radius
    local oppositeY = sun.y + math.sin(earth.angle + math.pi) * earth.radius

    love.graphics.setColor(0, 0.5, 1, 0.3)
    love.graphics.circle("fill", oppositeX, oppositeY, 6)

    love.graphics.setColor(0.8, 0.2, 0.2, 0.5)
    love.graphics.line(oppositeX, oppositeY, star.x, star.y)

    -- Calculate parallax angle
    local p = calculateParallaxAngle(earthX, earthY, oppositeX, oppositeY, star.x, star.y)

    love.graphics.pop() -- Reset transform so HUD text is unaffected

    -- Fixed position text (HUD)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(string.format("Parallax Angle (arcsec): %.5f", p), 10, 50)
    if p > 0 then
        love.graphics.print(string.format("Estimated Distance (parsecs): %.10f", 1 / p), 10, 70)
    end
    love.graphics.print(string.format("Timescale: %.3f", timescale), 10, 90)
end

function calculateParallaxAngle(x1, y1, x2, y2, sx, sy)
    local a = math.atan2(sy - y1, sx - x1)
    local b = math.atan2(sy - y2, sx - x2)
    local angle = math.abs(a - b)
    if angle > math.pi then angle = 2 * math.pi - angle end
    return math.deg(angle) * 3600  -- radians to arcseconds
end

function love.mousepressed(x, y, button)
    if button == 1 then
        dragging = true
        dragStart.x, dragStart.y = x, y
        cameraStart.x, cameraStart.y = camX, camY
    end
end

function love.mousereleased(_, _, button)
    if button == 1 then dragging = false end
end

function love.mousemoved(x, y, dx, dy)
    if dragging then
        camX = cameraStart.x + (x - dragStart.x)
        camY = cameraStart.y + (y - dragStart.y)
    end
end

function love.wheelmoved(x, y)
    local scaleFactor = 1.1
    if y > 0 then
        zoom = zoom * scaleFactor
    elseif y < 0 then
        zoom = zoom / scaleFactor
    end
end

function love.keypressed(key)
    if key == "right" then
        timescale = timescale * 1.1
    elseif key == "left" then
        timescale = timescale / 1.1
    end
end
