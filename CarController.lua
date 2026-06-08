-- VehicleSystem/CarController.lua
-- Контроллер машины с управлением и посадкой
-- Помести в модель автомобиля

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local car = script.Parent  -- модель машины
local seat = car:FindFirstChild("Seat") or car:FindFirstChild("VehicleSeat")
local chassis = car.PrimaryPart or car:FindFirstChild("Chassis") or car:FindFirstChild("Base")

if not chassis then
    warn("У машины нет PrimaryPart!")
    return
end

-- =================== НАСТРОЙКИ ===================
local MAX_SPEED = 100            -- максимальная скорость
local ACCELERATION = 30          -- ускорение
local TURN_SPEED = 3             -- скорость поворота
local BRAKE_FORCE = 50           -- сила торможения
local SEAT_RANGE = 10            -- дистанция для посадки

-- =================== ДАННЫЕ ===================
local currentSpeed = 0
local currentTurn = 0
local driver = nil
local isDriving = false

-- =================== ФИЗИКА МАШИНЫ ===================
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.MaxForce = Vector3.new(1, 0, 1) * 100000
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Parent = chassis

local bodyGyro = Instance.new("BodyGyro")
bodyGyro.MaxTorque = Vector3.new(0, 100000, 0)
bodyGyro.CFrame = chassis.CFrame
bodyGyro.Parent = chassis

-- =================== УПРАВЛЕНИЕ ===================
local function updateMovement()
    if not isDriving then
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        return
    end
    
    -- Газ и тормоз
    local moveForward = 0
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveForward = 1
    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveForward = -0.5  -- задний ход медленнее
    end
    
    -- Поворот
    local turn = 0
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        turn = -1
    elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then
        turn = 1
    end
    
    -- Ускорение
    if moveForward ~= 0 then
        currentSpeed = currentSpeed + moveForward * ACCELERATION * 0.1
    else
        -- Замедление
        if currentSpeed > 0 then
            currentSpeed = currentSpeed - BRAKE_FORCE * 0.1
            if currentSpeed < 0 then currentSpeed = 0 end
        elseif currentSpeed < 0 then
            currentSpeed = currentSpeed + BRAKE_FORCE * 0.1
            if currentSpeed > 0 then currentSpeed = 0 end
        end
    end
    
    -- Ограничение скорости
    currentSpeed = math.clamp(currentSpeed, -MAX_SPEED/2, MAX_SPEED)
    
    -- Поворот
    currentTurn = turn * TURN_SPEED * (currentSpeed / MAX_SPEED)
    
    -- Применяем движение
    local forward = chassis.CFrame.LookVector
    bodyVelocity.Velocity = forward * currentSpeed
    
    -- Применяем поворот
    local rotation = CFrame.Angles(0, math.rad(currentTurn), 0)
    bodyGyro.CFrame = bodyGyro.CFrame * rotation
end

-- =================== ПОСАДКА И ВЫХОД ===================
local function seatPlayer(player)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Притягиваем игрока к сиденью
    local seatPosition = seat and seat.Position or chassis.Position + Vector3.new(0, 3, 0)
    humanoid.Sit = true
    
    -- Телепортируем к сиденью
    character:MoveTo(seatPosition)
    
    driver = player
    isDriving = true
    
    print(player.Name .. " сел в машину")
end

local function unseatPlayer()
    if not driver then return end
    
    local character = driver.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Sit = false
        end
        
        -- Телепортируем рядом с машиной
        local exitPosition = chassis.Position + chassis.CFrame.RightVector * 10
        character:MoveTo(exitPosition)
    end
    
    driver = nil
    isDriving = false
    currentSpeed = 0
    
    print("Водитель вышел из машины")
end

-- Проверка нажатия E для посадки
game.Players.LocalPlayer:GetMouse().KeyDown:Connect(function(key)
    if key == "e" then
        if isDriving then
            unseatPlayer()
        else
            local player = game.Players.LocalPlayer
            local character = player.Character
            if character then
                local distance = (character:GetPrimaryPartCFrame().Position - chassis.Position).Magnitude
                if distance < SEAT_RANGE then
                    seatPlayer(player)
                end
            end
        end
    end
end)

-- =================== ИНИЦИАЛИЗАЦИЯ ===================
-- Привязываем колёса к земле (визуально)
local wheels = {}
for _, child in ipairs(car:GetDescendants()) do
    if child.Name:lower():find("wheel") then
        table.insert(wheels, child)
    end
end

-- =================== ГЛАВНЫЙ ЦИКЛ ===================
RunService.Heartbeat:Connect(function(deltaTime)
    updateMovement()
    
    -- Притягиваем водителя к сиденью
    if driver and driver.Character then
        local character = driver.Character
        local seatPosition = seat and seat.Position or chassis.Position + Vector3.new(0, 3, 0)
        character:MoveTo(seatPosition)
    end
end)

print("Car Controller запущен!")
print("Нажми E чтобы сесть в машину")
print("WASD — управление")
