local json = require("json")

local PIXEL_SCALE = 200  -- Scale gravity to pixels/s²
local timeScale = 1       -- Simulation timescale (1.0 = real time)

function love.load()
    love.window.setTitle("Planet Gravity Visualizer")
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    -- Load gravity from JSON file
    local file = love.filesystem.read("data.json")
    local parsedData = json.decode(file)
    gravity = parsedData.gravity_m_per_s2 or 9.8

    world = love.physics.newWorld(0, 0, true)
    objects = {}
    inputMass = 0.1
    dragging = nil
    mouseJoint = nil

    -- Create boundaries
    ground = makeWall(400, 590, 800, 20)
    leftWall = makeWall(0, 300, 20, 600)
    rightWall = makeWall(800, 300, 20, 600)
end

function makeWall(x, y, w, h)
    local wall = {}
    wall.body = love.physics.newBody(world, x, y, "static")
    wall.shape = love.physics.newRectangleShape(w, h)
    wall.fixture = love.physics.newFixture(wall.body, wall.shape)
    return wall
end

function love.update(dt)
    local scaled_dt = dt * timeScale

    for _, obj in ipairs(objects) do
        local gy = obj.mass * gravity * PIXEL_SCALE
        obj.body:applyForce(0, gy)
    end

    world:update(scaled_dt)

    if dragging and mouseJoint then
        mouseJoint:setTarget(love.mouse.getPosition())
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Gravity: " .. gravity .. " m/s² (from JSON)", 10, 10)
    love.graphics.print("Object Mass (kg): " .. string.format("%.3f", inputMass), 10, 30)
    love.graphics.print("Simulation Timescale: " .. timeScale .. "x (1 sec real = " .. string.format("%.2f", timeScale) .. " sec simulated)", 10, 50)
    love.graphics.print("Right-click: Add object | Left-drag: Move object", 10, 70)
    love.graphics.print("Press 1 = +100g | 2 = +1kg | 3 = +5kg | 0 = reset to 100g", 10, 90)
    love.graphics.print("Arrow Up/Down = Increase/Decrease Timescale", 10, 110)

    drawWall(ground)
    drawWall(leftWall)
    drawWall(rightWall)

    for _, obj in ipairs(objects) do
        love.graphics.setColor(0.2, 0.6, 1)
        local x, y = obj.body:getPosition()
        love.graphics.circle("fill", x, y, obj.shape:getRadius())
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(obj.mass .. " kg", x - 15, y - 7)
    end
end

function drawWall(wall)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.polygon("fill", wall.body:getWorldPoints(wall.shape:getPoints()))
end

function love.mousepressed(x, y, button)
    if button == 2 then
        if inputMass >= 0.001 and inputMass <= 100 then
            local radius = 5 + math.pow(inputMass, 1/3) * 4
            local obj = {}
            obj.mass = inputMass
            obj.body = love.physics.newBody(world, x, y, "dynamic")
            obj.shape = love.physics.newCircleShape(radius)
            obj.fixture = love.physics.newFixture(obj.body, obj.shape, 1)
            obj.fixture:setRestitution(0.3)
            obj.body:setMassData(0, 0, radius, obj.mass)
            obj.body:setLinearDamping(0.5)
            table.insert(objects, obj)
        end
    elseif button == 1 then
        for _, obj in ipairs(objects) do
            if isMouseInsideObject(x, y, obj) then
                dragging = obj
                mouseJoint = love.physics.newMouseJoint(obj.body, x, y)
                break
            end
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and mouseJoint then
        mouseJoint:destroy()
        mouseJoint = nil
        dragging = nil
    end
end

function love.keypressed(key)
    if key == "1" then
        inputMass = math.min(inputMass + 0.1, 100)
    elseif key == "2" then
        inputMass = math.min(inputMass + 1, 100)
    elseif key == "3" then
        inputMass = math.min(inputMass + 5, 100)
    elseif key == "0" then
        inputMass = 0.1
    elseif key == "up" then
        timeScale = math.min(timeScale + 0.1, 10)
    elseif key == "down" then
        timeScale = math.max(timeScale - 0.1, 0.1)
    end
end

function isMouseInsideObject(mx, my, obj)
    local x, y = obj.body:getPosition()
    local r = obj.shape:getRadius()
    return (mx - x)^2 + (my - y)^2 <= r^2
end
