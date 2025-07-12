-- Load JSON and gravity from file
local json = require("json")

-- Gravity data
local gravity_data
local planet_name = "Unknown"
do
    local file = love.filesystem.read("data.json")
    gravity_data = json.decode(file)
    planet_name = gravity_data.planet or "Unknown"
end

-- Constants
local window_width, window_height = 800, 600
local paddle_width, paddle_height = 20, 100
local ball_radius = 10

-- World gravity setup
local earth_gravity = 9.8
local world_gravity = gravity_data.gravity_m_per_s2 or earth_gravity
local gravity_scale = world_gravity / earth_gravity

-- Ball mass and physical weight
local ball_mass = 0.0027 -- kg (2.7 grams, typical ping-pong ball)
local ball_weight = ball_mass * world_gravity -- Newtons

-- Derived initial velocity from potential energy drop
local initial_height = 1.5 -- meters
local initial_velocity = math.sqrt(2 * world_gravity * initial_height)

-- Game objects
local base_player_speed = 300
local base_enemy_speed = 250
local player = { x = 50, y = 250, speed = base_player_speed }
local enemy = { x = window_width - 70, y = 250, speed = base_enemy_speed }

local ball = {
    x = window_width / 2,
    y = window_height / 2,
    radius = ball_radius,
    speed_x = 300,
    speed_y = -initial_velocity,
    gravity = world_gravity,
    mass = ball_mass,
    weight = ball_weight
}

-- Reset the ball to the center with initial vertical impulse
local function reset_ball()
    ball.x = window_width / 2
    ball.y = window_height / 2
    ball.speed_x = -ball.speed_x
    ball.speed_y = -initial_velocity
end

function love.load()
    love.window.setTitle("Accurate Pong: Mass & Gravity Physics")
    love.window.setMode(window_width, window_height)
end

function love.update(dt)
    -- Adjust paddle speed based on gravity
    local paddle_penalty = 1 - 0.2 * math.min(gravity_scale, 5) / 5
    player.speed = base_player_speed * paddle_penalty
    enemy.speed = base_enemy_speed * paddle_penalty

    -- Player movement (manual control)
    if love.keyboard.isDown("up") then
        player.y = math.max(0, player.y - player.speed * dt)
    elseif love.keyboard.isDown("down") then
        player.y = math.min(window_height - paddle_height, player.y + player.speed * dt)
    end

    -- AI (enemy paddle) tracks ball.y
    if enemy.y + paddle_height / 2 < ball.y - 10 then
        enemy.y = math.min(window_height - paddle_height, enemy.y + enemy.speed * dt)
    elseif enemy.y + paddle_height / 2 > ball.y + 10 then
        enemy.y = math.max(0, enemy.y - enemy.speed * dt)
    end

    -- Gravity applied to ball (free fall style)
    ball.speed_y = ball.speed_y + ball.gravity * dt

    -- Light air resistance drag
    local drag = 0.98
    ball.speed_y = ball.speed_y * drag

    -- Move ball
    ball.x = ball.x + ball.speed_x * dt
    ball.y = ball.y + ball.speed_y * dt

    -- Gravity-based bounce damping
    local bounce_damping = 0.6 - 0.3 * math.min(gravity_scale, 4) / 4
    bounce_damping = math.max(0.2, math.min(bounce_damping, 1.0))

    -- Bounce off floor
    if ball.y + ball.radius > window_height then
        ball.y = window_height - ball.radius
        ball.speed_y = -ball.speed_y * bounce_damping
    end

    -- Bounce off ceiling
    if ball.y - ball.radius < 0 then
        ball.y = ball.radius
        ball.speed_y = -ball.speed_y * bounce_damping
    end

    -- Collision with player paddle
    if ball.x - ball.radius < player.x + paddle_width and
       ball.y > player.y and ball.y < player.y + paddle_height then
        ball.x = player.x + paddle_width + ball.radius
        ball.speed_x = -ball.speed_x
    end

    -- Collision with enemy paddle
    if ball.x + ball.radius > enemy.x and
       ball.y > enemy.y and ball.y < enemy.y + paddle_height then
        ball.x = enemy.x - ball.radius
        ball.speed_x = -ball.speed_x
    end

    -- Ball out of bounds
    if ball.x < 0 or ball.x > window_width then
        reset_ball()
    end
end

function love.draw()
    -- Draw paddles
    love.graphics.rectangle("fill", player.x, player.y, paddle_width, paddle_height)
    love.graphics.rectangle("fill", enemy.x, enemy.y, paddle_width, paddle_height)

    -- Draw ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Draw physics data
    love.graphics.print(string.format("Planet: %s", planet_name), 10, 10)
    love.graphics.print(string.format("Gravity: %.2f m/s\194\178 (%.2f g)", ball.gravity, gravity_scale), 10, 30)
    love.graphics.print(string.format("Mass: %.4f kg", ball.mass), 10, 50)
    love.graphics.print(string.format("Weight: %.4f N", ball.weight), 10, 70)
    love.graphics.print(string.format("Initial Velocity: %.2f m/s", initial_velocity), 10, 90)
end
