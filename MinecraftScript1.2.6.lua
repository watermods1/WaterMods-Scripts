-- WaterMods roblox minecraft script V2 
-- Supported Games: minerscraft,minerscave games, wolfmoons games and some others
-- unsupported games: alpha 1.2.6,voxels

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")
local HUDGui = PlayerGui:FindFirstChild("HUDGui")
local DataFrame = HUDGui and HUDGui:FindFirstChild("DataFrame")
local CoordLabel = DataFrame and (DataFrame:FindFirstChild("Coord") or DataFrame:FindFirstChild("coordinates") or DataFrame:FindFirstChild("Coordinates"))

local viewportSize = camera.ViewportSize
local screenWidth = viewportSize.X
local screenHeight = viewportSize.Y

local deviceType = "PC"
local isPhone = false
local isTablet = false

local function updateDeviceType()
    viewportSize = camera.ViewportSize
    screenWidth = viewportSize.X
    screenHeight = viewportSize.Y
    local shortest = math.min(screenWidth, screenHeight)
    if UserInputService.TouchEnabled then
        if shortest < 700 then
            deviceType = "Phone"
            isPhone = true
            isTablet = false
        else
            deviceType = "Tablet"
            isPhone = false
            isTablet = true
        end
    else
        deviceType = "PC"
        isPhone = false
        isTablet = false
    end
end
updateDeviceType()

local uiConfig = {}


local function buildUIConfig()
    if deviceType == "Phone" then
        uiConfig = {
            windowWidth = 185,
            headerHeight = 24,

            buttonHeight = 24,
            sliderHeight = 42,
            dropdownItemHeight = 24,

            fontSize = 11,
            titleSize = 12,
            smallTextSize = 10,

            padding = 3,
            cornerRadius = 5,

            scrollBarThickness = 2,

            windowSpacingY = 4,
            initialYOffset = 6,
            sideMargin = 6,
        }

    elseif deviceType == "Tablet" then
        uiConfig = {
            windowWidth = 205,
            headerHeight = 24,

            buttonHeight = 24,
            sliderHeight = 42,
            dropdownItemHeight = 24,

            fontSize = 11,
            titleSize = 12,
            smallTextSize = 10,

            padding = 3,
            cornerRadius = 5,

            scrollBarThickness = 2,

            windowSpacingY = 5,
            initialYOffset = 8,
            sideMargin = 8,
        }

    else
        uiConfig = {
            windowWidth = 215,
            headerHeight = 24,

            buttonHeight = 24,
            sliderHeight = 42,
            dropdownItemHeight = 24,

            fontSize = 11,
            titleSize = 12,
            smallTextSize = 10,

            padding = 3,
            cornerRadius = 5,

            scrollBarThickness = 2,

            windowSpacingY = 6,
            initialYOffset = 10,
            sideMargin = 10,
        }
    end
end

buildUIConfig()

local isMobile = isPhone or isTablet

local gameremotes = ReplicatedStorage:WaitForChild("GameRemotes")
local moveitems = gameremotes:FindFirstChild("MoveItem") or gameremotes:FindFirstChild("MoveItems") or gameremotes:WaitForChild("MoveItem")
local sortitems = gameremotes:FindFirstChild("SortItem") or gameremotes:FindFirstChild("SortItems") or gameremotes:WaitForChild("SortItem")
local abb = gameremotes:FindFirstChild("AcceptBreakBlock") or gameremotes:WaitForChild("AcceptBreakBlock")
local bb = gameremotes:FindFirstChild("BreakBlock") or gameremotes:WaitForChild("BreakBlock")
local Attack = gameremotes:FindFirstChild("Attack") or gameremotes:WaitForChild("Attack")
local Demo = gameremotes:FindFirstChild("Demo") or Workspace:FindFirstChild("Demo")

local version = "v1.5"
local savedName = player.Name
local nukerLockX, nukerLockY, nukerLockZ = nil, nil, nil
local nukerAutoWalk = false
local nukerRange = 1
local nukerDelay = 0.2
local KillAuraSpeed = 10
local TargetStrafeSpeed = 3
local radius = 6
local timeAcc = 0
local strafeRange = 50
local selectedTargeting = "nearest"
local scaffoldSize = 1
local afk = false
local antiKickLoaded = false

local TIERS = {Diamond = 4, Ruby = 3, Iron = 2, Gold = 2, Steel = 2, Stone = 1}
local ARMOR = {Helmet = 103, Chestplate = 102, Leggings = 101, Boots = 100}

local M_World, BlocksByName, CGlobals, BlockHighlights, ItemInfo, BlockInfo, ItemLevels
local success = pcall(function()
    local MainScript = player:WaitForChild("PlayerScripts"):WaitForChild("MainLocalScript")
    M_World = require(MainScript:WaitForChild("CWorld"))
    local M_IDs = require(ReplicatedStorage:WaitForChild("AssetsMod"):WaitForChild("IDs"))
    BlocksByName = M_IDs.ByName.Blocks
    CGlobals = require(MainScript:WaitForChild("CGlobals"))
    BlockHighlights = require(MainScript:WaitForChild("BlockHighlights"))
    ItemInfo = require(ReplicatedStorage:WaitForChild("AssetsMod"):WaitForChild("ItemInfo"))
    BlockInfo = require(ReplicatedStorage:WaitForChild("AssetsMod"):WaitForChild("BlockInfo"))
    ItemLevels = require(ReplicatedStorage:WaitForChild("AssetsMod"):WaitForChild("ItemLevels"))
end)

local cachedPlayers = {}
local function rebuildCache()
    table.clear(cachedPlayers)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(cachedPlayers, p) end
    end
end
rebuildCache()
Players.PlayerAdded:Connect(rebuildCache)
Players.PlayerRemoving:Connect(rebuildCache)

local platform = Instance.new("Part")
platform.Anchored = true
platform.Size = Vector3.new(5,1,5)
platform.Transparency = 1
platform.CanCollide = false
platform.Parent = Workspace
local platformY = 0

local function GetInventory()
    if player.Character and player.Character:FindFirstChild("Inventory") then return player.Character.Inventory end
    if PlayerGui:FindFirstChild("Inventory") then return PlayerGui.Inventory end
    if HUDGui and HUDGui:FindFirstChild("Inventory") then return HUDGui.Inventory end
    return nil
end

local function GetItemNameAtSlot(slotIndex)
    local inv = GetInventory()
    if not inv then return nil end
    local slotObj = inv:FindFirstChild("Slot"..slotIndex)
    if slotObj and slotObj:IsA("StringValue") then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, slotObj.Value)
        if ok and data and data.name then return data.name end
    end
    if inv:FindFirstChild("Slots") then
        local guiSlot = inv.Slots:FindFirstChild("Slot"..slotIndex)
        if guiSlot and guiSlot.Slot and guiSlot.Slot.Display and guiSlot.Slot.Display:FindFirstChild("SlotB") then
            return guiSlot.Slot.Display.SlotB.Name
        end
    end
    local directSlot = PlayerGui:FindFirstChild("Inventory") and PlayerGui.Inventory:FindFirstChild("Slot"..slotIndex)
    if directSlot and directSlot:IsA("StringValue") then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, directSlot.Value)
        if ok and data.name then return data.name end
    end
    return nil
end

local function getPlayerCoordFromCharacter()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pos = hrp.Position
    return math.floor(pos.X/3 + 0.5), math.floor(pos.Y/3 + 0.5), math.floor(pos.Z/3 + 0.5)
end

local function getPlayerCoord()
    if CoordLabel then
        local text = CoordLabel.Text
        local x, y, z = text:match("(%-?%d+),%s*(%-?%d+),%s*(%-?%d+)")
        if x then return tonumber(x), tonumber(y), tonumber(z) end
    end
    return getPlayerCoordFromCharacter()
end


local function buildUIConfig()
    if deviceType == "Phone" then
        uiConfig = {
            windowWidth = 200,               -- very narrow, like the reference
            headerHeight = 28,
            buttonHeight = 36,
            sliderHeight = 54,
            dropdownItemHeight = 36,
            fontSize = 13,
            titleSize = 14,
            smallTextSize = 11,
            padding = 5,
            cornerRadius = 6,
            scrollBarThickness = 4,
            windowSpacingY = 6,
            initialYOffset = 8,
            sideMargin = 8,
        }
    elseif deviceType == "Tablet" then
        uiConfig = {
            windowWidth = 220,               -- still narrow
            headerHeight = 28,
            buttonHeight = 36,
            sliderHeight = 54,
            dropdownItemHeight = 36,
            fontSize = 13,
            titleSize = 14,
            smallTextSize = 11,
            padding = 5,
            cornerRadius = 6,
            scrollBarThickness = 4,
            windowSpacingY = 8,
            initialYOffset = 12,
            sideMargin = 12,
        }
    else  -- PC
        uiConfig = {
            windowWidth = 240,               -- already small
            headerHeight = 28,
            buttonHeight = 36,
            sliderHeight = 54,
            dropdownItemHeight = 34,
            fontSize = 13,
            titleSize = 14,
            smallTextSize = 11,
            padding = 5,
            cornerRadius = 6,
            scrollBarThickness = 4,
            windowSpacingY = 8,
            initialYOffset = 20,
            sideMargin = 12,
        }
    end
end

local function getWindowPositions()
    local positions = {}
    if isPhone then
        local baseY = 36
        local gap = uiConfig.windowSpacingY + uiConfig.headerHeight 
        positions.main    = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY)
        positions.combat  = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap)
        positions.world   = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap*2)
        positions.player  = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap*3)
        positions.visual  = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap*4)
        positions.utility = UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap*5)
        positions.teleport= UDim2.new(0.5, -uiConfig.windowWidth/2, 0, baseY + gap*6)
    elseif isTablet then
        local leftX = uiConfig.sideMargin
        local rightX = screenWidth - uiConfig.windowWidth - uiConfig.sideMargin
        local baseY = 36
        local gap = uiConfig.windowSpacingY + uiConfig.headerHeight
        positions.main    = UDim2.new(0, leftX, 0, baseY)
        positions.combat  = UDim2.new(0, leftX, 0, baseY + gap)
        positions.world   = UDim2.new(0, leftX, 0, baseY + gap*2)
        positions.player  = UDim2.new(0, rightX, 0, baseY)
        positions.visual  = UDim2.new(0, rightX, 0, baseY + gap)
        positions.utility = UDim2.new(0, rightX, 0, baseY + gap*2)
        positions.teleport= UDim2.new(0, rightX, 0, baseY + gap*3)
    else
        positions.main    = UDim2.new(0, 20, 0, 70)
        positions.combat  = UDim2.new(0, 270, 0, 70)
        positions.world   = UDim2.new(0, 520, 0, 70)
        positions.player  = UDim2.new(0, 770, 0, 70)
        positions.visual  = UDim2.new(0, 270, 0, 350)
        positions.utility = UDim2.new(0, 520, 0, 350)
        positions.teleport= UDim2.new(0, 770, 0, 350)
    end
    return positions
end

local windowPositions = getWindowPositions()

local gui = Instance.new("ScreenGui"); gui.Name = "CleanBlueUI"; gui.Parent = PlayerGui
gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.DisplayOrder = 999

local COLORS = {
    Window = Color3.fromRGB(20,25,40), Header = Color3.fromRGB(25,35,65),
    Button = Color3.fromRGB(26,32,52), ButtonOn = Color3.fromRGB(55,110,220),
    Text = Color3.new(1,1,1), Dropdown = Color3.fromRGB(15,20,35)
}

local function Notify(title, message, duration)
    duration = duration or 2; message = message or ""
    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, math.min(200, screenWidth - 30), 0, 50)
    frame.Position = UDim2.new(0, 10, 1, -65)
    frame.BackgroundColor3 = COLORS.Button
    frame.BorderSizePixel = 0
    frame.ZIndex = 100
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1, -10, 1, -10)
    text.Position = UDim2.new(0, 5, 0, 5)
    text.BackgroundTransparency = 1
    text.TextWrapped = true
    text.Font = Enum.Font.Gotham
    text.TextSize = uiConfig.smallTextSize
    text.TextColor3 = COLORS.Text
    text.Text = title.." - "..message
    text.ZIndex = 101
    spawn(function() wait(duration); frame:Destroy() end)
end

local arrayWindow = Instance.new("Frame", gui)
arrayWindow.Position = UDim2.new(1, -uiConfig.windowWidth - 5, 0, 40)
arrayWindow.Size = UDim2.new(0, uiConfig.windowWidth, 0, 280)
arrayWindow.BackgroundColor3 = COLORS.Window
arrayWindow.BorderSizePixel = 0
arrayWindow.Visible = false
arrayWindow.Active = true
arrayWindow.Draggable = true
Instance.new("UICorner", arrayWindow).CornerRadius = UDim.new(0, uiConfig.cornerRadius)

local arrayHeader = Instance.new("Frame", arrayWindow)
arrayHeader.Size = UDim2.new(1, 0, 0, uiConfig.headerHeight)
arrayHeader.BackgroundColor3 = COLORS.Header
arrayHeader.BorderSizePixel = 0
Instance.new("UICorner", arrayHeader).CornerRadius = UDim.new(0, uiConfig.cornerRadius)

local arrayTitle = Instance.new("TextLabel", arrayHeader)
arrayTitle.Size = UDim2.new(1, -10, 1, 0)
arrayTitle.Position = UDim2.new(0, 10, 0, 0)
arrayTitle.BackgroundTransparency = 1
arrayTitle.Text = "Active Features"
arrayTitle.TextColor3 = COLORS.Text
arrayTitle.Font = Enum.Font.GothamBold
arrayTitle.TextSize = uiConfig.titleSize
arrayTitle.TextXAlignment = Enum.TextXAlignment.Center

local arrayScrolling = Instance.new("ScrollingFrame", arrayWindow)
arrayScrolling.Position = UDim2.new(0, 0, 0, uiConfig.headerHeight)
arrayScrolling.Size = UDim2.new(1, -5, 1, -uiConfig.headerHeight - 5)
arrayScrolling.BackgroundTransparency = 1
arrayScrolling.BorderSizePixel = 0
arrayScrolling.ScrollBarThickness = uiConfig.scrollBarThickness
arrayScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
arrayScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
arrayScrolling.ScrollingDirection = Enum.ScrollingDirection.Y

local arrayLayout = Instance.new("UIListLayout", arrayScrolling)
arrayLayout.Padding = UDim.new(0, uiConfig.padding)
arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
arrayLayout.SortOrder = Enum.SortOrder.LayoutOrder

local activeArrayItems = {}
local function AddToArray(name)
    if activeArrayItems[name] then return end
    local label = Instance.new("TextLabel", arrayScrolling)
    label.Size = UDim2.new(1, -10, 0, uiConfig.buttonHeight * 0.7)
    label.BackgroundColor3 = COLORS.Button
    label.BorderSizePixel = 0
    label.TextColor3 = COLORS.Text
    label.Font = Enum.Font.GothamBold
    label.TextSize = uiConfig.smallTextSize
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Text = name
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, uiConfig.cornerRadius / 2)
    activeArrayItems[name] = label
end

local function RemoveFromArray(name)
    if activeArrayItems[name] then activeArrayItems[name]:Destroy(); activeArrayItems[name] = nil end
end

if not isMobile then
    UserInputService.MouseIconEnabled = true
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UserInputService.MouseIconEnabled = true
        end
    end)

    RunService.Heartbeat:Connect(function()
        if gui and gui.Parent and gui.Enabled then
            GuiService.SelectedObject = nil
            UserInputService.MouseIconEnabled = true
        end
    end)
end

local function CreateWindow(title, pos)
    local window = Instance.new("Frame", gui)
    window.Position = pos
    window.Size = UDim2.new(0, uiConfig.windowWidth, 0, uiConfig.headerHeight)
    window.BackgroundColor3 = COLORS.Window
    window.BorderSizePixel = 0
    window.Visible = false
    window.Active = true
    window.Draggable = true
    window.ClipsDescendants = true
    Instance.new("UICorner", window).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    
    local header = Instance.new("Frame", window)
    header.Size = UDim2.new(1, 0, 0, uiConfig.headerHeight)
    header.BackgroundColor3 = COLORS.Header
    header.BorderSizePixel = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    
    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(0.75, 0, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = COLORS.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = uiConfig.titleSize
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local expandBtn = Instance.new("TextButton", header)
    expandBtn.Size = UDim2.new(0, 30, 1, 0)
    expandBtn.Position = UDim2.new(1, -30, 0, 0)
    expandBtn.BackgroundTransparency = 1
    expandBtn.Text = "v"
    expandBtn.TextColor3 = COLORS.Text
    expandBtn.Font = Enum.Font.GothamBold
    expandBtn.TextSize = uiConfig.titleSize + 2
    
    local outerContainer = Instance.new("Frame", window)
    outerContainer.Position = UDim2.new(0, 0, 0, uiConfig.headerHeight)
    outerContainer.Size = UDim2.new(1, 0, 0, 120)
    outerContainer.BackgroundTransparency = 1
    outerContainer.ClipsDescendants = true
    
    local scrolling = Instance.new("ScrollingFrame", outerContainer)
    scrolling.Size = UDim2.new(1, -4, 1, 0)
    scrolling.Position = UDim2.new(0, 0, 0, 0)
    scrolling.BackgroundTransparency = 1
    scrolling.BorderSizePixel = 0
    scrolling.ScrollBarThickness = uiConfig.scrollBarThickness
    scrolling.CanvasSize = UDim2.new()
    scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrolling.ScrollingDirection = Enum.ScrollingDirection.Y
    scrolling.ScrollBarImageColor3 = Color3.fromRGB(60,80,140)
    
    local container = Instance.new("Frame", scrolling)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, uiConfig.padding)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local expanded = true
    local function updateSize()
        if expanded then
            local maxHeight = camera.ViewportSize.Y - 150
            local height = math.min(layout.AbsoluteContentSize.Y + 8, maxHeight)
            container.Size = UDim2.new(1, 0, 0, height)
            outerContainer.Size = UDim2.new(1, 0, 0, height)
            window.Size = UDim2.new(0, uiConfig.windowWidth, 0, height + uiConfig.headerHeight)
            outerContainer.Visible = true
        else
            window.Size = UDim2.new(0, uiConfig.windowWidth, 0, uiConfig.headerHeight)
            outerContainer.Visible = false
        end
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    expandBtn.MouseButton1Click:Connect(function() expanded = not expanded; expandBtn.Text = expanded and "v" or ">"; updateSize() end)
    return container, window
end

local function Toggle(parent, text, showInArray, callback)
    if showInArray == nil then showInArray = true end
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(1, -6, 0, uiConfig.buttonHeight)
    button.Position = UDim2.new(0, 3, 0, 0)
    button.BackgroundColor3 = COLORS.Button
    button.TextColor3 = COLORS.Text
    button.Font = Enum.Font.Gotham
    button.TextSize = uiConfig.fontSize
    button.Text = text.." : OFF"
    button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    local state = false
    local ctrl = {}
    function ctrl.SetState(v)
        state = v
        button.Text = text.." : "..(state and "ON" or "OFF")
        button.BackgroundColor3 = state and COLORS.ButtonOn or COLORS.Button
        if showInArray then
            if state then AddToArray(text) else RemoveFromArray(text) end
        end
        if callback then callback(state) end
    end
    function ctrl.GetState() return state end
    button.MouseButton1Click:Connect(function() state = not state; ctrl.SetState(state) end)
    return ctrl
end

local function Button(parent, text, callback)
    local button = Instance.new("TextButton", parent)
    button.Size = UDim2.new(0.95, 0, 0, uiConfig.buttonHeight)
    button.BackgroundColor3 = COLORS.Button
    button.TextColor3 = COLORS.Text
    button.Font = Enum.Font.Gotham
    button.TextSize = uiConfig.fontSize
    button.Text = text
    button.BorderSizePixel = 0
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    button.MouseButton1Click:Connect(function() if callback then callback() end end)
    return button
end

local function Section(parent, text)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(0.95, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(120,140,200)
    label.Font = Enum.Font.GothamBold
    label.TextSize = uiConfig.smallTextSize
    label.TextXAlignment = Enum.TextXAlignment.Center
    return label
end

local function Dropdown(parent, text)
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(0.95, 0, 0, uiConfig.buttonHeight)
    holder.BackgroundColor3 = COLORS.Dropdown
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    
    local ddButton = Instance.new("TextButton", holder)
    ddButton.Size = UDim2.new(1, 0, 0, uiConfig.buttonHeight)
    ddButton.BackgroundTransparency = 1
    ddButton.Text = "  "..text.." >"
    ddButton.Font = Enum.Font.GothamBold
    ddButton.TextSize = uiConfig.fontSize
    ddButton.TextColor3 = COLORS.Text
    ddButton.TextXAlignment = Enum.TextXAlignment.Left
    
    local content = Instance.new("Frame", holder)
    content.Position = UDim2.new(0, 0, 0, uiConfig.buttonHeight)
    content.Size = UDim2.new(1, 0, 0, 0)
    content.BackgroundTransparency = 1
    
    local contentScroll = Instance.new("ScrollingFrame", content)
    contentScroll.Size = UDim2.new(1, 0, 1, 0)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = uiConfig.scrollBarThickness
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    contentScroll.ScrollBarImageColor3 = Color3.fromRGB(60,80,140)
    
    local innerContent = Instance.new("Frame", contentScroll)
    innerContent.Size = UDim2.new(1, 0, 0, 0)
    innerContent.BackgroundTransparency = 1
    
    local layout = Instance.new("UIListLayout", innerContent)
    layout.Padding = UDim.new(0, uiConfig.padding)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local open = false
    local function update()
        if open then
            local size = math.min(layout.AbsoluteContentSize.Y + 4, 120)
            innerContent.Size = UDim2.new(1, 0, 0, size)
            contentScroll.CanvasSize = UDim2.new(0, 0, 0, size)
            content.Size = UDim2.new(1, 0, 0, size)
            content.Visible = true
            holder.Size = UDim2.new(0.95, 0, 0, size + uiConfig.buttonHeight)
            ddButton.Text = "  "..text.." v"
        else
            holder.Size = UDim2.new(0.95, 0, 0, uiConfig.buttonHeight)
            ddButton.Text = "  "..text.." >"
            content.Visible = false
        end
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    ddButton.MouseButton1Click:Connect(function() open = not open; update() end)
    return innerContent
end

local function Slider(parent, text, min, max, default, step, callback)
    step = step or 1
    default = default or min
    local holder = Instance.new("Frame", parent)
    holder.Size = UDim2.new(1, -6, 0, 36)
    holder.Position = UDim2.new(0, 3, 0, 0)
    holder.BackgroundColor3 = COLORS.Button
    holder.BorderSizePixel = 0
    Instance.new("UICorner", holder).CornerRadius = UDim.new(0, uiConfig.cornerRadius)
    local label = Instance.new("TextLabel", holder)
    label.Position = UDim2.new(0, 6, 0, 2)
    label.Size = UDim2.new(1, -12, 0, 12)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = uiConfig.smallTextSize
    label.TextColor3 = COLORS.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text.." : "..tostring(default)
    local bar = Instance.new("TextButton", holder)
    bar.Position = UDim2.new(0, 6, 0, 22)
    bar.Size = UDim2.new(1, -12, 0, 8)
    bar.BackgroundColor3 = Color3.fromRGB(45,65,120)
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", bar)
    fill.BackgroundColor3 = COLORS.ButtonOn
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.Active = false
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local decBtn = Instance.new("TextButton", holder)
    decBtn.Size = UDim2.new(0, 18, 0, 14)
    decBtn.Position = UDim2.new(0, 6, 0, 24)
    decBtn.BackgroundColor3 = Color3.fromRGB(40,55,100)
    decBtn.Text = "-"
    decBtn.TextColor3 = COLORS.Text
    decBtn.Font = Enum.Font.GothamBold
    decBtn.TextSize = 10
    decBtn.BorderSizePixel = 0
    Instance.new("UICorner", decBtn).CornerRadius = UDim.new(0, uiConfig.cornerRadius/2)
    local incBtn = Instance.new("TextButton", holder)
    incBtn.Size = UDim2.new(0, 18, 0, 14)
    incBtn.Position = UDim2.new(0, 28, 0, 24)
    incBtn.BackgroundColor3 = Color3.fromRGB(40,55,100)
    incBtn.Text = "+"
    incBtn.TextColor3 = COLORS.Text
    incBtn.Font = Enum.Font.GothamBold
    incBtn.TextSize = 10
    incBtn.BorderSizePixel = 0
    Instance.new("UICorner", incBtn).CornerRadius = UDim.new(0, uiConfig.cornerRadius/2)
    local dragging = false
    local current = default
    local function setValue(val)
        val = math.clamp(val, min, max)
        val = math.floor(val/step + 0.5) * step
        current = val
        fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
        label.Text = text.." : "..tostring(val)
        if callback then callback(val) end
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setValue(min + (max - min) * ((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X))
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setValue(min + (max - min) * ((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    decBtn.MouseButton1Click:Connect(function() setValue(current - step) end)
    incBtn.MouseButton1Click:Connect(function() setValue(current + step) end)
    setValue(default)
end

local ActiveBulbs = {}
local activeConnections = {}
local activeThreads = {}

local oreColors = {
    CoalOre = Color3.fromRGB(56, 59, 56), IronOre = Color3.fromRGB(110, 105, 105),
    SteelOre = Color3.fromRGB(110, 105, 105), RainbowiteOre = Color3.fromRGB(25, 0, 25),
    GoldOre = Color3.fromRGB(245, 242, 71), RubyOre = Color3.fromRGB(245, 71, 48),
    DiamondOre = Color3.fromRGB(35, 207, 219), SaphireOre = Color3.fromRGB(18, 18, 120),
    SapphireOre = Color3.fromRGB(18, 18, 120), AmethystOre = Color3.fromRGB(255, 105, 180),
    OverlordOre = Color3.fromRGB(18, 18, 120), Obsidian = Color3.fromRGB(0, 0, 0),
    PurpleFlower = Color3.fromRGB(25, 0, 25),
    DiamondLuckyBlock = Color3.fromRGB(51, 204, 51), GoldLuckyBlock = Color3.fromRGB(153, 102, 0),
}

local function clearXray()
    for g in pairs(ActiveBulbs) do if g then g:Destroy() end end
    table.clear(ActiveBulbs)
end

local function createXray(part, color)
    if not part or not part.Parent or part:FindFirstChild("bulbX") then return end
    local b = Instance.new("BillboardGui"); b.Name = "bulbX"; b.Parent = part
    ActiveBulbs[b] = true; b.Destroying:Connect(function() ActiveBulbs[b] = nil end)
    b.Size = UDim2.new(1,0,1,0); b.AlwaysOnTop = true; b.LightInfluence = 0
    local f = Instance.new("Frame", b); f.Size = UDim2.new(0.8,0,0.8,0); f.Position = UDim2.new(0.1,0,0.1,0)
    f.BackgroundColor3 = color; f.BorderSizePixel = 3; f.BorderColor3 = Color3.fromRGB(31,31,31)
    part.AncestryChanged:Connect(function(_, par) if not par and b then b:Destroy() end end)
end

local killAuraHeartbeat = nil
local function updateCombatHeartbeat()
    if killAuraHeartbeat then killAuraHeartbeat:Disconnect(); killAuraHeartbeat = nil end
    if not ka and not ts then return end
    killAuraHeartbeat = RunService.Heartbeat:Connect(function(dt)
        local lpC = player.Character; local lpHRP = lpC and lpC:FindFirstChild("HumanoidRootPart")
        if not lpHRP then return end
        local function getTarget()
            local bd, bh, bt = math.huge, math.huge, nil
            for _, p in ipairs(cachedPlayers) do
                local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart")
                local hum = c and c:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (lpHRP.Position - hrp.Position).Magnitude
                    if d <= strafeRange then
                        if selectedTargeting == "lowest" and hum.Health < bh then bh, bt = hum.Health, p
                        elseif d < bd then bd, bt = d, p end
                    end
                end
            end
            return bt
        end
        if ka then local t = getTarget(); if t and t.Character then Attack:InvokeServer(t.Character) end end
        if ts then
            local t = getTarget()
            if t and t.Character then
                local tHRP = t.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    timeAcc = timeAcc + dt * TargetStrafeSpeed * 2
                    local off = Vector3.new(math.cos(timeAcc) * radius, 0, math.sin(timeAcc) * radius)
                    lpHRP.AssemblyLinearVelocity = Vector3.zero
                    lpHRP.CFrame = CFrame.new(tHRP.Position + off, tHRP.Position)
                end
            end
        end
    end)
end

local function triggerbotLoop()
    while TB do
        pcall(function()
            local c = player.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local vp = camera.ViewportSize; local ray = camera:ViewportPointToRay(vp.X/2, vp.Y/2)
            local params = RaycastParams.new(); params.FilterDescendantsInstances = {c}
            params.FilterType = Enum.RaycastFilterType.Blacklist
            local res = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            if res then
                local chr = res.Instance:FindFirstAncestorOfClass("Model")
                if chr and chr ~= c and chr:FindFirstChildOfClass("Humanoid") then
                    local hum = chr:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then Attack:InvokeServer(chr) end
                end
            end
        end)
        wait(_G.tbdelay or 0)
    end
end

local function scaffoldStart()
    local world = M_World
    local blocksByName = BlocksByName
    if not world or not blocksByName then
        local ok, err = pcall(function()
            if not world then
                world = require(game.Players.LocalPlayer.PlayerScripts.MainLocalScript.CWorld)
            end
            if not blocksByName then
                local M_IDs = require(game.ReplicatedStorage.AssetsMod.IDs)
                blocksByName = M_IDs.ByName.Blocks
            end
        end)
        if not ok then
            Notify("Scaffold Error", "Failed to load world data: "..tostring(err), 5)
            return
        end
    end
    local dir = 1

    if DataFrame and CoordLabel then
        _G.CoordsChannel = CoordLabel:GetPropertyChangedSignal("Text"):Connect(function()
            if not scaffoldEnabled then return end
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
                local placeSlot = player.Character.SelectedSlot.Value
                local pl_x, pl_y, pl_z = getPlayerCoord()
                if not pl_x then return end
                pl_y = pl_y - 1
                local realBlock
                if PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot].Slot.Display:FindFirstChild("SlotB") then
                    for _, v in pairs(PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot].Slot.Display.SlotB:GetChildren()) do
                        realBlock = v.Name
                        local canPlaceBlock = false
                        local block, chunk = world.getBlock(pl_x, pl_y, pl_z)
                        if block == nil then
                            canPlaceBlock = true
                        else
                            for _, vv in pairs(block) do
                                if vv == 0 then canPlaceBlock = true; break end
                            end
                        end
                        if canPlaceBlock and realBlock then
                            local itemblock_info = blocksByName[realBlock]
                            if itemblock_info then
                                world.placeBlock(pl_x, pl_y, pl_z, chunk, dir, itemblock_info.id)
                                local Call, Name = game.ReplicatedStorage.GameRemotes.PlaceBlock:InvokeServer(pl_x, pl_y, pl_z, placeSlot, dir)
                                if not Call then
                                    chunk:change(pl_x%16, pl_y, pl_z%16, Name)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end)
    else
        _G.CoordsChannel = RunService.Heartbeat:Connect(function()
            if not scaffoldEnabled then return end
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") and player.Character.Humanoid.Health > 0 then
                local placeSlot = player.Character.SelectedSlot.Value
                local pl_x, pl_y, pl_z = getPlayerCoordFromCharacter()
                if not pl_x then return end
                pl_y = pl_y - 1
                local realBlock
                if PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot].Slot.Display:FindFirstChild("SlotB") then
                    for _, v in pairs(PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot].Slot.Display.SlotB:GetChildren()) do
                        realBlock = v.Name
                        local canPlaceBlock = false
                        local block, chunk = world.getBlock(pl_x, pl_y, pl_z)
                        if block == nil then
                            canPlaceBlock = true
                        else
                            for _, vv in pairs(block) do
                                if vv == 0 then canPlaceBlock = true; break end
                            end
                        end
                        if canPlaceBlock and realBlock then
                            local itemblock_info = blocksByName[realBlock]
                            if itemblock_info then
                                world.placeBlock(pl_x, pl_y, pl_z, chunk, dir, itemblock_info.id)
                                local Call, Name = game.ReplicatedStorage.GameRemotes.PlaceBlock:InvokeServer(pl_x, pl_y, pl_z, placeSlot, dir)
                                if not Call then
                                    chunk:change(pl_x%16, pl_y, pl_z%16, Name)
                                end
                            end
                        end
                        break
                    end
                end
            end
        end)
    end
end

local function nukerLoop()
    while nk do
        local x, y, z
        if nukerAutoWalk then
            x, y, z = getPlayerCoord()   
        else
            x, y, z = nukerLockX, nukerLockY, nukerLockZ  
        end
        if x then
            local r = math.floor(nukerRange / 2)
            for ox = -r, r do
                for oz = -r, r do
                    if not nk then break end
                    spawn(function()
                        bb:FireServer(x + ox, y - 1, z + oz)
                        abb:InvokeServer()
                    end)
                end
            end
        end
        wait(nukerDelay)
    end
end

local function nuker3Loop()
    while nk3 do
        local x, y, z
        if nukerAutoWalk then
            x, y, z = getPlayerCoord()
        else
            x, y, z = nukerLockX, nukerLockY, nukerLockZ
        end
        if x then
            for offsetX = -1, 1 do
                for offsetY = -1, 1 do
                    for offsetZ = -1, 1 do
                        if not nk3 then break end
                        spawn(function()
                            bb:FireServer(x + offsetX, y + offsetY - 1, z + offsetZ)
                            abb:InvokeServer()
                        end)
                    end
                end
            end
        end
        wait(nukerDelay)
    end
end

local function nuker5Loop()
    while nk5 do
        local x, y, z
        if nukerAutoWalk then
            x, y, z = getPlayerCoord()
        else
            x, y, z = nukerLockX, nukerLockY, nukerLockZ
        end
        if x then
            for offsetX = -2, 2 do
                for offsetY = -2, 2 do
                    for offsetZ = -2, 2 do
                        if not nk5 then break end
                        spawn(function()
                            bb:FireServer(x + offsetX, y + offsetY - 1, z + offsetZ)
                            abb:InvokeServer()
                        end)
                    end
                end
            end
        end
        wait(nukerDelay)
    end
end

local highwayConnection = nil
local function highwayCallback(direction)
    if highwayConnection then
        highwayConnection:Disconnect()
        highwayConnection = nil
    end

    if not HUDGui or not DataFrame then
        highwayConnection = RunService.Heartbeat:Connect(function()
            if not highwayEnabled then return end
            local x, y, z = getPlayerCoordFromCharacter()
            if not x then return end
            y = y - 1
            local lp = player
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local placeSlot = char.SelectedSlot.Value
            local slotGui = lp.PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot]
            if not slotGui or not slotGui.Slot.Display:FindFirstChild("SlotB") then return end
            local realBlock
            for _, v in pairs(slotGui.Slot.Display.SlotB:GetChildren()) do
                realBlock = v.Name
                break
            end
            if not realBlock then return end
            local itemblock_info = BlocksByName[realBlock]
            if not itemblock_info then return end
            local dir = 1
            local positions = {}
            if direction == "Z" then
                for oz = -2, 2 do
                    positions[#positions + 1] = {x, y, z + oz}
                    if oz == -2 or oz == 2 then
                        positions[#positions + 1] = {x, y + 1, z + oz}
                    end
                end
            else
                for ox = -2, 2 do
                    positions[#positions + 1] = {x + ox, y, z}
                    if ox == -2 or ox == 2 then
                        positions[#positions + 1] = {x + ox, y + 1, z}
                    end
                end
            end
            for i = 1, #positions do
                spawn(function()
                    local px, py, pz = unpack(positions[i])
                    local block, chunk = M_World.getBlock(px, py, pz)
                    local canPlace = false
                    if not block then
                        canPlace = true
                    else
                        for _, v in pairs(block) do
                            if v == 0 then canPlace = true; break end
                        end
                    end
                    if canPlace then
                        M_World.placeBlock(px, py, pz, chunk, dir, itemblock_info.id)
                        local ok, name = game.ReplicatedStorage.GameRemotes.PlaceBlock:InvokeServer(px, py, pz, placeSlot, dir)
                        if not ok then
                            chunk:change(px % 16, py, pz % 16, name)
                        end
                    end
                end)
            end
        end)
        return
    end

    local coordLabel = DataFrame:FindFirstChild("Coord") or DataFrame:FindFirstChild("coordinates")
    if coordLabel then
        highwayConnection = coordLabel:GetPropertyChangedSignal("Text"):Connect(function()
            if not highwayEnabled then return end
            local x, y, z = getPlayerCoord()
            if not x then return end
            y = y - 1
            local lp = player
            local char = lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            local placeSlot = char.SelectedSlot.Value
            local slotGui = lp.PlayerGui.HUDGui.Inventory.Slots["Slot"..placeSlot]
            if not slotGui or not slotGui.Slot.Display:FindFirstChild("SlotB") then return end
            local realBlock
            for _, v in pairs(slotGui.Slot.Display.SlotB:GetChildren()) do
                realBlock = v.Name
                break
            end
            if not realBlock then return end
            local itemblock_info = BlocksByName[realBlock]
            if not itemblock_info then return end
            local dir = 1
            local positions = {}
            if direction == "Z" then
                for oz = -2, 2 do
                    positions[#positions + 1] = {x, y, z + oz}
                    if oz == -2 or oz == 2 then
                        positions[#positions + 1] = {x, y + 1, z + oz}
                    end
                end
            else
                for ox = -2, 2 do
                    positions[#positions + 1] = {x + ox, y, z}
                    if ox == -2 or ox == 2 then
                        positions[#positions + 1] = {x + ox, y + 1, z}
                    end
                end
            end
            for i = 1, #positions do
                spawn(function()
                    local px, py, pz = unpack(positions[i])
                    local block, chunk = M_World.getBlock(px, py, pz)
                    local canPlace = false
                    if not block then
                        canPlace = true
                    else
                        for _, v in pairs(block) do
                            if v == 0 then canPlace = true; break end
                        end
                    end
                    if canPlace then
                        M_World.placeBlock(px, py, pz, chunk, dir, itemblock_info.id)
                        local ok, name = game.ReplicatedStorage.GameRemotes.PlaceBlock:InvokeServer(px, py, pz, placeSlot, dir)
                        if not ok then
                            chunk:change(px % 16, py, pz % 16, name)
                        end
                    end
                end)
            end
        end)
    end
end

local function chestStealer()
    for i = 36, 62 do spawn(function() moveitems:InvokeServer(i, i - 27, true) end) end
end

local function chestDupeFunc(mode)
    if mode == 1 then sortitems:InvokeServer(36)
    elseif mode == 2 then for i = 36, 62 do spawn(function() sortitems:InvokeServer(i) end) end end
end

local function ReloadChunk()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    wait()
    hrp.CFrame = CFrame.new(30000, 180, 30000)
    wait()
    hrp.CFrame = CFrame.new(pos)
end

local function getPlayerNames()
    local t = {}; for _, p in ipairs(Players:GetPlayers()) do table.insert(t, p.Name) end; return t
end

local origBrightness, origClockTime, origFogEnd, origGlobalShadows = Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.GlobalShadows

local npConnection = nil
local function nameProtectToggle(v)
    npEnabled = v
    if npConnection then npConnection:Disconnect(); npConnection = nil end
    if v then
        local function protect()
            for _, val in ipairs(game:GetDescendants()) do
                if val.ClassName == "TextLabel" and string.find(val.Text, player.Name) then
                    val.Text = val.Text:gsub(player.Name, "Protected")
                end
            end
        end
        protect()
        npConnection = game.DescendantAdded:Connect(function(val)
            if val.ClassName == "TextLabel" then
                val:GetPropertyChangedSignal("Text"):Connect(function()
                    if string.find(val.Text, player.Name) then val.Text = val.Text:gsub(player.Name, "Protected") end
                end)
                if string.find(val.Text, player.Name) then val.Text = val.Text:gsub(player.Name, "Protected") end
            end
        end)
    end
end

local function stopAllCheats()
    for k in pairs(activeThreads) do activeThreads[k] = false end; table.clear(activeThreads)
    for _, c in pairs(activeConnections) do c:Disconnect() end; table.clear(activeConnections)
    if _G.CoordsChannel then _G.CoordsChannel:Disconnect(); _G.CoordsChannel = nil end
    if _G.HBCoordsChannel then _G.HBCoordsChannel:Disconnect(); _G.HBCoordsChannel = nil end
    clearXray()
    nameProtectToggle(false)
    ka, ts, TB, nk, nk3, nk5, fb, ae, infh = false, false, false, false, false, false, false, false, false
    scaffoldEnabled, highwayEnabled, xray1Enabled, xray2Enabled = false, false, false, false
    walkWaterEnabled, noFallDamageEnabled, fullbrightEnabled = false, false, false
    sprintEnabled, airWalkEnabled = false, false
    Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime
    Lighting.FogEnd = origFogEnd; Lighting.GlobalShadows = origGlobalShadows
    updateCombatHeartbeat()
    if highwayConnection then highwayConnection:Disconnect(); highwayConnection = nil end
    if Demo and Demo.Parent == Workspace then Demo.Parent = gameremotes end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Anchored = false
    end
    if platform then
        platform.CanCollide = false
    end
end

local mainContainer, mainWindow = CreateWindow("Main", windowPositions.main)
local combatContainer, combatWindow = CreateWindow("Combat", windowPositions.combat)
local worldContainer, worldWindow = CreateWindow("World", windowPositions.world)
local playerContainer, playerWindow = CreateWindow("Player", windowPositions.player)
local visualContainer, visualWindow = CreateWindow("Visual", windowPositions.visual)
local utilityContainer, utilityWindow = CreateWindow("Utility", windowPositions.utility)
local teleportContainer, teleportWindow = CreateWindow("Teleport", windowPositions.teleport)

mainWindow.Visible = true

Section(combatContainer, "Aura & Targeting")
local auraDrop = Dropdown(combatContainer, "Aura Settings")
Toggle(auraDrop, "Kill Aura", true, function(v) ka = v; updateCombatHeartbeat() end)
Slider(auraDrop, "Aura Speed", 1, 100, 10, 1, function(v) KillAuraSpeed = v end)
Toggle(auraDrop, "Triggerbot", true, function(v)
    TB = v
    if activeThreads["tb"] then activeThreads["tb"] = false end
    if v then activeThreads["tb"] = true; spawn(triggerbotLoop) end
end)
Slider(auraDrop, "TB Delay", 0, 10, 0, 0.1, function(v) _G.tbdelay = v end)

local targetDrop = Dropdown(combatContainer, "Target Strafe")
Toggle(targetDrop, "Target Strafe", true, function(v) ts = v; timeAcc = 0; updateCombatHeartbeat() end)
Slider(targetDrop, "Strafe Speed", 1, 30, 3, 1, function(v) TargetStrafeSpeed = v end)
Slider(targetDrop, "Strafe Radius", 1, 80, 6, 1, function(v) radius = v end)

Section(worldContainer, "Building")
local scaffoldDrop = Dropdown(worldContainer, "Scaffold")
Toggle(scaffoldDrop, "Scaffold", true, function(v)
    scaffoldEnabled = v
    if not v then
        if _G.CoordsChannel then _G.CoordsChannel:Disconnect(); _G.CoordsChannel = nil end
    else
        scaffoldStart()
    end
    Notify("NOTICE", "NOT WORKING ON ALL EXECUTORS")
end)
Slider(scaffoldDrop, "Size", 1, 300, 1, 1, function(v) scaffoldSize = v end)

local highwayDrop = Dropdown(worldContainer, "Highway Builder")
Toggle(highwayDrop, "Highway Builder", true, function(v)
    highwayEnabled = v
    if highwayConnection then highwayConnection:Disconnect(); highwayConnection = nil end
    if not v then return end
    highwayCallback(_G.highwayDir or "X")
end)

_G.highwayDir = "X"
local highwayDirDrop = Dropdown(highwayDrop, "Direction")

local function updateHighwayDirText()
    local dirText = _G.highwayDir or "X"
    for _, child in ipairs(highwayDrop:GetChildren()) do
        if child:IsA("Frame") then
            for _, btn in ipairs(child:GetChildren()) do
                if btn:IsA("TextButton") and btn.Text:find("Direction") then
                    btn.Text = "  Direction: " .. dirText .. " >"
                end
            end
        end
    end
end

Button(highwayDirDrop, "X Axis (East/West)", function()
    _G.highwayDir = "X"
    updateHighwayDirText()
    Notify("Highway", "Direction: X Axis")
    if highwayEnabled then highwayCallback("X") end
end)
Button(highwayDirDrop, "Z Axis (North/South)", function()
    _G.highwayDir = "Z"
    updateHighwayDirText()
    Notify("Highway", "Direction: Z Axis")
    if highwayEnabled then highwayCallback("Z") end
end)

Toggle(worldContainer, "Fast Break", true, function(v)
    fb = v
    if activeThreads["fb"] then activeThreads["fb"] = false end
    if v then activeThreads["fb"] = true; spawn(function() while activeThreads["fb"] do abb:InvokeServer(); wait() end end) end
end)

Toggle(worldContainer, "Instamine", true, function(v)
    if player.Character then
        if not player.Character:FindFirstChild("Gamemode") then
            Instance.new("IntValue", player.Character).Name = "Gamemode"
        end
        player.Character.Gamemode.Value = v and 1 or 0
    end
end)

local nukerDrop = Dropdown(worldContainer, "Nuker")
Slider(nukerDrop, "Range", 1, 500, 1, 1, function(v) nukerRange = v end)
Slider(nukerDrop, "Speed", 1, 100, 20, 1, function(v)
    nukerDelay = math.max(0.005, 1.0 - (v - 1) * (0.995 / 99))
end)
Toggle(nukerDrop, "Auto Nuker Walk", true, function(v)
    nukerAutoWalk = v
    if v then
        Notify("Nuker", "Auto Nuker Walk ON")
    end
end)
Toggle(nukerDrop, "Nuker", true, function(v)
    nk = v
    if activeThreads["nuker"] then activeThreads["nuker"] = false end
    if v then
        local x, y, z = getPlayerCoord()
        if x then
            nukerLockX, nukerLockY, nukerLockZ = x, y, z
        end
        activeThreads["nuker"] = true
        spawn(nukerLoop)
    else
        nukerLockX, nukerLockY, nukerLockZ = nil, nil, nil
    end
end)
Toggle(nukerDrop, "Nuker 3x3", true, function(v)
    nk3 = v
    if activeThreads["nuker3"] then activeThreads["nuker3"] = false end
    if v then
        local x, y, z = getPlayerCoord()
        if x then
            nukerLockX, nukerLockY, nukerLockZ = x, y, z
        end
        activeThreads["nuker3"] = true
        spawn(nuker3Loop)
    else
        nukerLockX, nukerLockY, nukerLockZ = nil, nil, nil
    end
end)
Toggle(nukerDrop, "Nuker 5x5", true, function(v)
    nk5 = v
    if activeThreads["nuker5"] then activeThreads["nuker5"] = false end
    if v then
        local x, y, z = getPlayerCoord()
        if x then
            nukerLockX, nukerLockY, nukerLockZ = x, y, z
        end
        activeThreads["nuker5"] = true
        spawn(nuker5Loop)
    else
        nukerLockX, nukerLockY, nukerLockZ = nil, nil, nil
    end
end)

Section(worldContainer, "Actions")
Button(worldContainer, "Reload Chunks", ReloadChunk)
Button(worldContainer, "Chest Stealer", chestStealer)

Section(playerContainer, "Health & Food")
Toggle(playerContainer, "Auto Eat", true, function(v)
    ae = v
    if activeThreads["ae"] then activeThreads["ae"] = false end
    if not v then return end
    activeThreads["ae"] = true
    spawn(function()
        while activeThreads["ae"] do
            pcall(function()
                if not player.Character or not player.Character:FindFirstChild("SelectedSlot") then return end
                local slot = player.Character.SelectedSlot.Value
                local inv = GetInventory()
                if inv then
                    gameremotes.ConsumeItem:InvokeServer(inv, slot)
                else
                    gameremotes.ConsumeItem:InvokeServer(slot)
                end
            end)
            wait(0.5)
        end
    end)
end)

local healthDrop = Dropdown(playerContainer, "Health Mods")
Toggle(healthDrop, "Inf Health Swap", true, function(v)
    infh = v
    if activeThreads["ih"] then activeThreads["ih"] = false end
    if v then
        activeThreads["ih"] = true
        spawn(function()
            while activeThreads["ih"] do
                pcall(function() moveitems:InvokeServer(101, 9, true); moveitems:InvokeServer(9, 101, true) end)
                wait()
            end
        end)
    end
end)
Button(healthDrop, "Immortality", function()
    pcall(function() moveitems:InvokeServer(101, 9, true) end)
    Notify("Health", "Immortality triggered")
end)

Section(playerContainer, "Movement")
Toggle(playerContainer, "Sprint", true, function(v)
    sprintEnabled = v
    local c = player.Character
    if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.WalkSpeed = v and 16 or 12 end
end)
Toggle(playerContainer, "No Fall + No Suffocation", true, function(v)
    noFallDamageEnabled = v
    if Demo then
        if v and Demo.Parent == gameremotes then Demo.Parent = Workspace
        elseif not v and Demo.Parent == Workspace then Demo.Parent = gameremotes end
    end
end)
Toggle(playerContainer, "Inf Jump", true, function(v) infj = v end)
Toggle(playerContainer, "Air Walk", true, function(v)
    airWalkEnabled = v
    if activeThreads["aw"] then activeThreads["aw"] = false end
    if v then
        local c = player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            platformY = c.HumanoidRootPart.Position.Y - 3
            platform.CanCollide = true
        end
        activeThreads["aw"] = true
        spawn(function()
            while activeThreads["aw"] do
                local c = player.Character
                if c and c:FindFirstChild("HumanoidRootPart") then
                    platform.Position = Vector3.new(c.HumanoidRootPart.Position.X, platformY, c.HumanoidRootPart.Position.Z)
                end
                wait()
            end
        end)
    else
        platform.CanCollide = false
    end
end)
Toggle(playerContainer, "Walk on Water", true, function(v)
    walkWaterEnabled = v
    local ff = Workspace:FindFirstChild("Fluid"); if not ff then return end
    local function iw(p) return p:IsA("BasePart") and (p.Name == "Water" or p.Name == "Lava") end
    if activeConnections["water"] then activeConnections["water"]:Disconnect(); activeConnections["water"] = nil end
    if v then
        for _, o in ipairs(ff:GetDescendants()) do if iw(o) then o.CanCollide = true end end
        activeConnections["water"] = ff.DescendantAdded:Connect(function(o) if iw(o) then o.CanCollide = true end end)
    else
        for _, o in ipairs(ff:GetDescendants()) do if iw(o) then o.CanCollide = false end end
    end
end)
Toggle(playerContainer, "Freeze", true, function(v)
    fr = v
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.Anchored = v
    end
end)

Section(playerContainer, "Equipment")
Toggle(playerContainer, "Auto Armor", true, function(v)
    if activeThreads["aa"] then activeThreads["aa"] = false end
    if not v then return end
    activeThreads["aa"] = true
    spawn(function()
        while activeThreads["aa"] do
            pcall(function()
                local best = {
                    [103] = {tier = -1, slot = nil},
                    [102] = {tier = -1, slot = nil},
                    [101] = {tier = -1, slot = nil},
                    [100] = {tier = -1, slot = nil}
                }
                for i = 0, 35 do
                    local name = GetItemNameAtSlot(i)
                    if name then
                        local armorSlot = nil
                        if string.find(name, "Helmet") then armorSlot = 103
                        elseif string.find(name, "Chestplate") then armorSlot = 102
                        elseif string.find(name, "Leggings") then armorSlot = 101
                        elseif string.find(name, "Boots") then armorSlot = 100
                        end
                        if armorSlot then
                            local tier = 0
                            for prefix, t in pairs(TIERS) do
                                if string.find(name, "^"..prefix) then
                                    tier = t
                                    break
                                end
                            end
                            if tier > best[armorSlot].tier then
                                best[armorSlot] = {tier = tier, slot = i}
                            end
                        end
                    end
                end
                for armorId, data in pairs(best) do
                    if data.slot ~= nil then
                        moveitems:InvokeServer(data.slot, armorId, true)
                    end
                end
            end)
            wait()
        end
    end)
end)

Toggle(playerContainer, "Reach", true, function(v)
    if CGlobals then CGlobals["PLAYER_REACH"] = v and 9e9 or 19.5 end
end)
Button(playerContainer, "Reset", function()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid.Health = 0
    end
end)

Section(teleportContainer, "Teleport")
local playerListScrolling = Instance.new("ScrollingFrame", teleportContainer)
playerListScrolling.Size = UDim2.new(0.95, 0, 0, 180)
playerListScrolling.BackgroundTransparency = 1
playerListScrolling.BorderSizePixel = 0
playerListScrolling.ScrollBarThickness = uiConfig.scrollBarThickness
playerListScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListScrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScrolling.ScrollBarImageColor3 = Color3.fromRGB(60,80,140)
local playerListLayout = Instance.new("UIListLayout", playerListScrolling)
playerListLayout.Padding = UDim.new(0, uiConfig.padding)
playerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function refreshPlayerList()
    for _, v in ipairs(playerListScrolling:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, name in ipairs(getPlayerNames()) do
        local btn = Instance.new("TextButton", playerListScrolling)
        btn.Size = UDim2.new(1, 0, 0, uiConfig.buttonHeight - 4)
        btn.BackgroundColor3 = COLORS.Button
        btn.TextColor3 = COLORS.Text
        btn.Font = Enum.Font.Gotham
        btn.TextSize = uiConfig.smallTextSize
        btn.Text = name
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, uiConfig.cornerRadius/2)
        btn.MouseButton1Click:Connect(function() selectedPlayerName = name; Notify("Selected", name) end)
    end
end

Button(teleportContainer, "Refresh List", refreshPlayerList)
Button(teleportContainer, "Teleport to Selected", function()
    if not selectedPlayerName then Notify("Error", "Select a player first") return end
    local target = Players:FindFirstChild(selectedPlayerName); if not target then return end
    local char = player.Character; local tChar = target.Character
    if not (char and tChar) then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    if hrp and tHRP then hrp.CFrame = tHRP.CFrame; Notify("TP", "Teleported to "..selectedPlayerName) end
end)

refreshPlayerList()

Section(visualContainer, "World Visuals")
Toggle(visualContainer, "Fullbright", true, function(v)
    fullbrightEnabled = v
    if v then
        origBrightness = Lighting.Brightness; origClockTime = Lighting.ClockTime
        origFogEnd = Lighting.FogEnd; origGlobalShadows = Lighting.GlobalShadows
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 100000; Lighting.GlobalShadows = false
    else
        Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime
        Lighting.FogEnd = origFogEnd; Lighting.GlobalShadows = origGlobalShadows
    end
end)

local xray1Conn, xray2Conn
Toggle(visualContainer, "X-Ray 1 (Ores)", true, function(v)
    xray1Enabled = v; if xray1Conn then xray1Conn:Disconnect(); xray1Conn = nil end; clearXray()
    if not v then return end
    local bf = Workspace:FindFirstChild("Blocks"); if not bf then return end
    for _, ch in ipairs(bf:GetChildren()) do
        for _, p in ipairs(ch:GetChildren()) do
            if p:IsA("BasePart") and oreColors[p.Name] then createXray(p, oreColors[p.Name]) end
        end
    end
    xray1Conn = bf.DescendantAdded:Connect(function(p)
        if xray1Enabled and p:IsA("BasePart") and oreColors[p.Name] then createXray(p, oreColors[p.Name]) end
    end)
end)

Toggle(visualContainer, "X-Ray 2 (All)", true, function(v)
    xray2Enabled = v; if xray2Conn then xray2Conn:Disconnect(); xray2Conn = nil end; clearXray()
    if not v then return end
    for _, p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") and oreColors[p.Name] then createXray(p, oreColors[p.Name]) end
    end
    xray2Conn = Workspace.DescendantAdded:Connect(function(p)
        if xray2Enabled and p:IsA("BasePart") and oreColors[p.Name] then createXray(p, oreColors[p.Name]) end
    end)
end)

Toggle(visualContainer, "Name Protect", true, nameProtectToggle)

Section(utilityContainer, "Duplication")
local dupeDrop = Dropdown(utilityContainer, "Dupe Methods")
Toggle(dupeDrop, "Remote Tables", false, function(v) usetables = v end)
Button(dupeDrop, "Dupe Selected", function()
    local s = PlayerGui.HUDGui.Inventory.Slots["Slot-1"].SlotNA.Count
    local a = tonumber(s.Text) or 0
    if a == 0 then Notify("Dupe", "Select 2 items") return end
    if a == 64 then Notify("Dupe", "Limit reached") return end
    pcall(function()
        if usetables then moveitems:InvokeServer({-1,82,true,-(64-a)})
        else moveitems:InvokeServer(-1,82,true,-(64-a)) end
        Notify("Dupe", "Duped")
    end)
end)
Button(dupeDrop, "Dupe Method 2", function()
    local s = PlayerGui.HUDGui.Inventory.Slots["Slot-1"].SlotNA.Count
    local s0 = PlayerGui.HUDGui.Inventory.Slots["Slot0"].Slot.Count
    if s.Text ~= "2" then Notify("Dupe", "Need 2 items") return end
    if s0.Text ~= "0" then Notify("Dupe", "Free first slot") return end
    pcall(function()
        if usetables then moveitems:InvokeServer({-1,0,true,0.01})
        else moveitems:InvokeServer(-1,0,true,0.01) end
        Notify("Dupe", "Duped")
    end)
end)
Button(dupeDrop, "Dupe Chest Slot", function() chestDupeFunc(1); Notify("Dupe", "Duped slot") end)
Button(dupeDrop, "Dupe Entire Chest", function() chestDupeFunc(2); Notify("Dupe", "Duped chest") end)
Button(dupeDrop, "Dupe To Infinite", function()
    if tonumber(PlayerGui.HUDGui.Inventory.Slots["Slot-1"].SlotNA.Count.Text) == 0 then
        Notify("Dupe", "Select items"); return
    end
    pcall(function()
        if usetables then moveitems:InvokeServer({-1,0,true,-9e100})
        else moveitems:InvokeServer(-1,0,true,-9e100) end
        Notify("Dupe", "Infinite duped")
    end)
end)

Section(utilityContainer, "Auto")
Toggle(utilityContainer, "Auto Drop", true, function(v)
    if activeThreads["ad"] then activeThreads["ad"] = false end
    if v then
        activeThreads["ad"] = true
        spawn(function() while activeThreads["ad"] do gameremotes.DropItem:InvokeServer(true); wait() end end)
    end
end)
Toggle(utilityContainer, "Auto Dupe Chest", true, function(v)
    if activeThreads["adc"] then activeThreads["adc"] = false end
    if v then
        activeThreads["adc"] = true
        spawn(function() while activeThreads["adc"] do chestDupeFunc(2); wait() end end)
    end
end)

Section(utilityContainer, "Misc")
Button(utilityContainer, "Kick Chest Glitch", function()
    if not _G.kickHooked then
        _G.kickHooked = true
        local mt = getrawmetatable(game); local old = mt.__namecall; setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self,...) if getnamecallmethod()=="Kick" then wait(math.huge) end return old(self,...) end)
        setreadonly(mt, true); hookfunction(player.Kick, function() wait(math.huge) end)
    end
    Notify("Glitch", "Chest bugged")
end)
Button(utilityContainer, "Fix Inv Lag", function()
    local c = PlayerGui.HUDGui.Inventory:FindFirstChild("CraftingBook")
    if c then c:Destroy(); Notify("Fix", "Lag fixed") end
end)

Section(utilityContainer, "UI")
Toggle(utilityContainer, "Show Array List", false, function(s) arrayWindow.Visible = s end)
Toggle(utilityContainer, "Array Draggable", false, function(s) arrayWindow.Draggable = s end)

Section(mainContainer, "Windows")
local mainToggles = {}
mainToggles["Combat"] = Toggle(mainContainer, "Combat", false, function(s) combatWindow.Visible = s end)
mainToggles["World"] = Toggle(mainContainer, "World", false, function(s) worldWindow.Visible = s end)
mainToggles["Player"] = Toggle(mainContainer, "Player", false, function(s) playerWindow.Visible = s end)
mainToggles["Visual"] = Toggle(mainContainer, "Visual", false, function(s) visualWindow.Visible = s end)
mainToggles["Utility"] = Toggle(mainContainer, "Utility", false, function(s) utilityWindow.Visible = s end)
mainToggles["Teleport"] = Toggle(mainContainer, "Teleport", false, function(s) teleportWindow.Visible = s end)

Section(mainContainer, "Controls")
Button(mainContainer, "Close All Windows", function()
    for _, t in pairs(mainToggles) do t.SetState(false) end
    combatWindow.Visible = false; worldWindow.Visible = false; playerWindow.Visible = false
    visualWindow.Visible = false; utilityWindow.Visible = false; teleportWindow.Visible = false
    arrayWindow.Visible = false; mainWindow.Visible = true
    Notify("Windows", "Closed")
end)
Toggle(mainContainer, "Anti AFK", false, function(v)
    afk = v
    for _, c in ipairs(getconnections(player.Idled)) do if v then c:Disable() else c:Enable() end end
end)
Toggle(mainContainer, "Anti-Adonis (Irreversible)", false, function(v)
    if v then
        if not antiKickLoaded then
            if getgc then
                local success, err = pcall(function()
                    loadstring(game:HttpGet('https://raw.githubusercontent.com/SUUUUUS00000/MEGGD-Anti-kick/refs/heads/main/MEGGD%20Best%20Anti-kick.lua'))()
                end)
                if success then
                    antiKickLoaded = true
                    Notify("Anti-Kick", "Anti-Adonis script loaded", 3)
                else
                    Notify("Anti-Kick", "Failed to load: " .. tostring(err), 4)
                end
            else
                Notify("Anti-Kick", "Executor does not support getgc", 3)
            end
        else
            Notify("Anti-Kick", "Already loaded (restart game to disable)", 3)
        end
    else
        Notify("Anti-Kick", "Disable not supported – rejoin to revert", 3)
    end
end)
Toggle(mainContainer, "Remove Cheats on Destroy", false, function(s) removeCheatsOnDestroy = s end)
Button(mainContainer, "Destroy UI", function()
    if removeCheatsOnDestroy then stopAllCheats() end
    gui:Destroy()
end)
Button(mainContainer, "Made By WaterMods", function()
    Notify("Credits", "Made By WaterMods v2.0")
end)

UserInputService.JumpRequest:Connect(function()
    if infj and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
        player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Notify("System", "WaterMods MC Script V1.5 Loaded -  Executed on "..deviceType, 3)
