-- Developer Cheat Panel - for testing client-side vulnerabilities
-- Run this script in any executor after joining your game.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local env = getsenv(player.PlayerScripts.MainLocalScript)

-- Store original functions/variables so toggles can restore them
local originalDamage = env.reqDamage
local originalBeginBreaking = env.beginBreakingBlock
local originalAttemptPlace = env.attemptPlace
local originalUpdateDurability = env.updateG_Durability
local originalAttackInvoke = env.game.ReplicatedStorage.GameRemotes.Attack.InvokeServer

-- Helper to create a toggle button with a label
local function createToggle(parent, name, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 0.8, 0)
    btn.Position = UDim2.new(0.75, -5, 0.1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = frame

    local enabled = false
    btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            btn.Text = "OFF"
        end
        callback(enabled)
    end)
    return frame
end

-- Build the GUI
local screen = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screen.Name = "DevCheats"

local main = Instance.new("Frame", screen)
main.Size = UDim2.new(0, 220, 0, 400)
main.Position = UDim2.new(0.5, -110, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
main.BorderSizePixel = 0

-- Make the window draggable (simple)
local dragging, dragStart, startPos
main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
main.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
title.Text = "Cheat Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -10, 1, -35)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)

-- Update canvas size automatically
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

-- ===== Toggles for each cheat =====

-- 1. God Mode (block all damage)
createToggle(scroll, "God Mode", function(on)
    if on then env.reqDamage = function() end
    else env.reqDamage = originalDamage end
end)

-- 2. Lava/Fire immunity
createToggle(scroll, "Lava/Fire Immune", function(on)
    if on then
        game.ReplicatedStorage.Fire.FireServer = function() end
    else
        -- Can't restore original, so just rejoin to disable
    end
end)

-- 3. Drowning immunity
createToggle(scroll, "Drowning Immune", function(on)
    if on then
        env.reqDamage = function(amount, dtype)
            if dtype ~= "drowning" then originalDamage(amount, dtype) end
        end
    else
        env.reqDamage = originalDamage
    end
end)

-- 4. Void immunity (also auto-teleport)
local voidConn
createToggle(scroll, "Void Immune", function(on)
    if on then
        env.reqDamage = function(amount, dtype)
            if dtype ~= "void" then originalDamage(amount, dtype) end
        end
        voidConn = game:GetService("RunService").RenderStepped:Connect(function()
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Position.Y < -100 then
                root.CFrame = CFrame.new(root.Position.X, 50, root.Position.Z)
            end
        end)
    else
        env.reqDamage = originalDamage
        if voidConn then voidConn:Disconnect() end
    end
end)

-- 5. Fall damage immunity
createToggle(scroll, "Fall Damage Immune", function(on)
    if on then
        env.reqDamage = function(amount, dtype)
            if dtype ~= "fall" then originalDamage(amount, dtype) end
        end
    else
        env.reqDamage = originalDamage
    end
end)

-- 6. Suffocation immunity
createToggle(scroll, "Suffocation Immune", function(on)
    if on then
        env.reqDamage = function(amount, dtype)
            if dtype ~= "suffocation" then originalDamage(amount, dtype) end
        end
    else
        env.reqDamage = originalDamage
    end
end)

-- 7. Infinite Health
createToggle(scroll, "Infinite Health", function(on)
    local human = env.char and env.char:FindFirstChild("Humanoid")
    if human then
        if on then
            human.MaxHealth = 9e9
            human.Health = 9e9
            human:GetPropertyChangedSignal("Health"):Connect(function()
                human.Health = 9e9
            end)
        else
            -- Can't easily revert; rejoin
        end
    end
end)

-- 8. Creative Mode
createToggle(scroll, "Creative Mode", function(on)
    if on then
        env.M_GameUtil.getGamemode = function() return 1 end
    else
        env.M_GameUtil.getGamemode = function() return 0 end
    end
end)

-- 9. Fly / No-Clip
local flyConn, grav, swim
createToggle(scroll, "Fly", function(on)
    local char = env.char
    local human = char.Humanoid
    local root = char.HumanoidRootPart
    local uis = game:GetService("UserInputService")
    if on then
        human:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        if root:FindFirstChild("Grav") then root.Grav:Destroy() end
        if root:FindFirstChild("Swim") then root.Swim:Destroy() end
        flyConn = uis.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.E then
                while uis:IsKeyDown(Enum.KeyCode.E) do root.Velocity = root.Velocity + Vector3.new(0,2,0); task.wait() end
            elseif input.KeyCode == Enum.KeyCode.Q then
                while uis:IsKeyDown(Enum.KeyCode.Q) do root.Velocity = root.Velocity + Vector3.new(0,-2,0); task.wait() end
            end
        end)
    else
        human:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
        if flyConn then flyConn:Disconnect() end
    end
end)

-- 10. Super Speed (change value to any number)
createToggle(scroll, "Super Speed", function(on)
    if on then env.char.Humanoid.WalkSpeed = 100 else env.char.Humanoid.WalkSpeed = 12 end
end)

-- 11. Instant Block Break
createToggle(scroll, "Instant Break", function(on)
    if on then
        env.beginBreakingBlock = function(x, y, z, force, hit_pos)
            originalBeginBreaking(x, y, z, force, hit_pos)
            if env.breaking then env.breakTimer = 0 end
        end
    else
        env.beginBreakingBlock = originalBeginBreaking
    end
end)

-- 12. Reach Hack (infinite distance)
createToggle(scroll, "Reach Hack", function(on)
    if on then env.Globals.IsBlockInReach = true else env.Globals.IsBlockInReach = false end
end)

-- 13. Place Anywhere
createToggle(scroll, "Place Anywhere", function(on)
    if on then
        env.attemptPlace = function()
            local oldSolid = env.is_solid
            env.is_solid = false
            originalAttemptPlace()
            env.is_solid = oldSolid
        end
    else
        env.attemptPlace = originalAttemptPlace
    end
end)

-- 14. Give Item (click once)
createToggle(scroll, "Give Diamond Sword", function(on)
    if on then
        env.selSlotV.Value = game:GetService("HttpService"):JSONEncode({
            name = "DiamondSword",
            count = 64,
            durability = 9999
        })
        -- Auto-disable after giving to prevent spam
        task.wait(0.1)
        env.selSlotV.Value = originalSelSlotValue -- not stored, so not reversible; better to just use button click
    end
end)

-- 15. Infinite Durability
createToggle(scroll, "Infinite Durability", function(on)
    if on then
        env.updateG_Durability = function(slot, tab)
            if tab.durability then tab.durability = 9999 end
            originalUpdateDurability(slot, tab)
        end
    else
        env.updateG_Durability = originalUpdateDurability
    end
end)

-- 16. No Attack Cooldown
createToggle(scroll, "No Attack CD", function(on)
    if on then
        env.swingCooldown = false
        env.canattack = true
        env.game.ReplicatedStorage.GameRemotes.Attack.InvokeServer = function(target) return nil, nil end
    else
        env.game.ReplicatedStorage.GameRemotes.Attack.InvokeServer = originalAttackInvoke
    end
end)

-- 17. Item Magnet
local magnetConn
createToggle(scroll, "Item Magnet", function(on)
    if on then
        magnetConn = game:GetService("RunService").RenderStepped:Connect(function()
            for _, ent in pairs(env.entities) do
                if ent.part and ent.part.Parent == workspace then
                    ent.part.CFrame = env.char.HumanoidRootPart.CFrame
                end
            end
        end)
    else
        if magnetConn then magnetConn:Disconnect() end
    end
end)

-- 18. Fullbright
createToggle(scroll, "Fullbright", function(on)
    local lighting = game:GetService("Lighting")
    if on then
        lighting.Brightness = 10
        lighting.FogEnd = 1e5
        lighting.FogStart = 0
        lighting.Ambient = Color3.new(1,1,1)
        lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        lighting.Brightness = 2
        lighting.FogEnd = 2000
        lighting.FogStart = 500
    end
end)

-- 19. X-Ray
createToggle(scroll, "X-Ray", function(on)
    for _, part in pairs(workspace.Blocks:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = on and 0.7 or 0
        end
    end
    -- Highlight players
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local hl = p.Character:FindFirstChild("ESP_Highlight")
            if on and not hl then
                hl = Instance.new("Highlight", p.Character)
                hl.Name = "ESP_Highlight"
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.new(1,0,0)
            elseif not on and hl then
                hl:Destroy()
            end
        end
    end
end)
