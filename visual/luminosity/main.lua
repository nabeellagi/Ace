-- main.lua (Scene Manager)

local StarSystemScene = require("StarSystemScene")
local StarScene = require("StarScene")

local currentScene -- This will hold the currently active scene object

function love.load()
    -- Initialize both scenes
    StarSystemScene.init()
    StarScene.init()

    -- Set the initial scene
    currentScene = StarSystemScene

    -- Call the load function of the initial scene
    currentScene:load()
end

function love.update(dt)
    -- Update the current scene
    currentScene:update(dt)
end

function love.draw()
    -- Draw the current scene
    currentScene:draw()
end

function love.keypressed(key)
    if key == "z" then
        if currentScene == StarSystemScene then
            currentScene = StarScene
        else
            currentScene = StarSystemScene
        end
        -- Re-load the new scene when switching to reset its state if necessary
        currentScene:load()
    end
    -- Pass key presses to the current scene if it has a keypressed method
    if currentScene.keypressed then
        currentScene:keypressed(key)
    end
end

function love.wheelmoved(x, y)
    -- Pass mouse wheel events to the current scene
    if currentScene.wheelmoved then
        currentScene:wheelmoved(x, y)
    end
end