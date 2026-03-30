-- =============================================
-- JAVI MOD v1.2 - Ultimate Mining Tycoon
-- Más funciones + Rayo X mejorado
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ==================== CONFIG ====================
local xrayEnabled = true
local showMinerals = true
local showGems = true
local highlightRares = false

local autoMineEnabled = false
local speedEnabled = false
local flyEnabled = false
local noclipEnabled = false
local infJumpEnabled = false

local normalSpeed = 16
local fastSpeed = 55
local flySpeed = 60

local highlights = {}
local nameTags = {}
local connections = {}

-- Detección mejorada
local function isMineralOrGem(name)
    if not name then return false, nil end
    local lower = name:lower()
    
    if lower:find("ore") or lower:find("tin") or lower:find("iron") or lower:find("cobalt") or 
       lower:find("gold") or lower:find("silver") or lower:find("titanium") or lower:find("uranium") then
        return true, "Mineral"
    end
    if lower:find("gem") or lower:find("topaz") or lower:find("emerald") or lower:find("sapphire") or 
       lower:find("ruby") or lower:find("diamond") or lower:find("crystal") then
        return true, "Gema"
    end
    return false, nil
end

local function getColor(displayType)
    if displayType == "Gema" then
        return Color3.fromRGB(100, 255, 140)
    else
        return Color3.fromRGB(255, 140, 80)
    end
end

local function clearVisuals()
    for _, v in ipairs(highlights) do if v and v.Parent then v:Destroy() end end
    for _, v in ipairs(nameTags) do if v and v.Parent then v:Destroy() end end
    highlights = {}
    nameTags = {}
end

local function applyXRay()
    if not xrayEnabled or not root then 
        clearVisuals() 
        return 
    end
    clearVisuals()

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and obj.Transparency < 0.85 then
            local dist = (obj.Position - root.Position).Magnitude
            if dist > 140 then continue end

            local isValid, displayType = isMineralOrGem(obj.Name)
            if not isValid then continue end

            if (displayType == "Mineral" and not showMinerals) or (displayType == "Gema" and not showGems) then 
                continue 
            end

            local hl = Instance.new("Highlight")
            hl.Parent = obj
            hl.FillColor = getColor(displayType)
            hl.FillTransparency = 0.4
            hl.OutlineTransparency = 0
            hl.OutlineColor = Color3.fromRGB(255, 255, 100)
            table.insert(highlights, hl)

            local bg = Instance.new("BillboardGui")
            bg.Size = UDim2.new(0, 140, 0, 32)
            bg.StudsOffset = Vector3.new(0, 4, 0)
            bg.AlwaysOnTop = true
            bg.Parent = obj

            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1,0,1,0)
            txt.BackgroundTransparency = 1
            txt.Text = displayType
            txt.TextColor3 = getColor(displayType)
            txt.TextStrokeTransparency = 0.7
            txt.TextStrokeColor3 = Color3.new(0,0,0)
            txt.TextScaled = true
            txt.Font = Enum.Font.GothamBold
            txt.Parent = bg

            table.insert(nameTags, bg)
        end
    end
end

-- Auto Mine
local function startAutoMine()
    if connections.autoMine then connections.autoMine:Disconnect() end
    connections.autoMine = RunService.Heartbeat:Connect(function()
        if not autoMineEnabled or not root then return end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
                local isValid, _ = isMineralOrGem(obj.Name)
                if isValid then
                    local dist = (obj.Position - root.Position).Magnitude
                    if dist < 22 and dist > 4 then
                        root.CFrame = CFrame.new(obj.Position + Vector3.new(0, 6, 0))
                        task.wait(0.28)
                        break
                    end
                end
            end
        end
    end)
end

-- Speed
local function toggleSpeed(state)
    speedEnabled = state
    humanoid.WalkSpeed = state and fastSpeed or normalSpeed
end

-- Fly V3
local flying = false
local bv, bg = nil, nil

local function toggleFly(state)
    flyEnabled = state
    if state then
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0,0,0)
        bv.Parent = root

        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 9000
        bg.Parent = root

        flying = true

        connections.flyControl = RunService.RenderStepped:Connect(function()
            if not flying then return end
            local cam = workspace.CurrentCamera
            local moveDir = Vector3.new(0,0,0)

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0,1,0) end

            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * flySpeed
            else
                bv.Velocity = Vector3.new(0,0,0)
            end
            bg.CFrame = cam.CFrame
        end)
    else
        flying = false
        if bv then bv:Destroy() bv = nil end
        if bg then bg:Destroy() bg = nil end
        if connections.flyControl then connections.flyControl:Disconnect() end
    end
end

-- Noclip
local function toggleNoclip(state)
    noclipEnabled = state
    if state then
        connections.noclip = RunService.Stepped:Connect(function()
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if connections.noclip then 
            connections.noclip:Disconnect() 
            connections.noclip = nil 
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Infinite Jump
local function toggleInfJump(state)
    infJumpEnabled = state
    if state then
        connections.infJump = UserInputService.JumpRequest:Connect(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    else
        if connections.infJump then 
            connections.infJump:Disconnect() 
            connections.infJump = nil 
        end
    end
end

-- ==================== MENÚ ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Botón Δ rojo
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 65, 0, 65)
OpenButton.Position = UDim2.new(0, 20, 0.5, -32)
OpenButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
OpenButton.Text = "Δ"
OpenButton.TextScaled = true
OpenButton.Font = Enum.Font.GothamBlack
OpenButton.TextColor3 = Color3.fromRGB(255, 50, 50)
OpenButton.Parent = ScreenGui

Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 16)
local strokeBtn = Instance.new("UIStroke", OpenButton)
strokeBtn.Color = Color3.fromRGB(255, 50, 50)
strokeBtn.Thickness = 3

-- Menú negro con bordes rojos
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 500)
MainFrame.Position = UDim2.new(0.5, -180, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
local strokeMain = Instance.new("UIStroke", MainFrame)
strokeMain.Color = Color3.fromRGB(255, 50, 50)
strokeMain.Thickness = 2.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 45)
Title.BackgroundTransparency = 1
Title.Text = "JAVI MOD v1.2"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 38)
TabBar.Position = UDim2.new(0, 10, 0, 50)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TabBar.Parent = MainFrame
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)

local VisualsTab = Instance.new("TextButton")
VisualsTab.Size = UDim2.new(0, 95, 1, 0)
VisualsTab.Position = UDim2.new(0, 0, 0, 0)
VisualsTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
VisualsTab.Text = "Visuals"
VisualsTab.TextColor3 = Color3.fromRGB(255,255,255)
VisualsTab.TextSize = 14
VisualsTab.Font = Enum.Font.GothamSemibold
VisualsTab.Parent = TabBar
Instance.new("UICorner", VisualsTab).CornerRadius = UDim.new(0, 6)

local MiscTab = Instance.new("TextButton")
MiscTab.Size = UDim2.new(0, 95, 1, 0)
MiscTab.Position = UDim2.new(0, 100, 0, 0)
MiscTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
MiscTab.Text = "Misc"
MiscTab.TextColor3 = Color3.fromRGB(255,255,255)
MiscTab.TextSize = 14
MiscTab.Font = Enum.Font.GothamSemibold
MiscTab.Parent = TabBar
Instance.new("UICorner", MiscTab).CornerRadius = UDim.new(0, 6)

local StatusTab = Instance.new("TextButton")
StatusTab.Size = UDim2.new(0, 95, 1, 0)
StatusTab.Position = UDim2.new(0, 200, 0, 0)
StatusTab.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
StatusTab.Text = "Status"
StatusTab.TextColor3 = Color3.fromRGB(255,255,255)
StatusTab.TextSize = 14
StatusTab.Font = Enum.Font.GothamSemibold
StatusTab.Parent = TabBar
Instance.new("UICorner", StatusTab).CornerRadius = UDim.new(0, 6)

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -105)
Content.Position = UDim2.new(0, 10, 0, 95)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ==================== VISUALS ====================
local function CreateVisualsContent()
    local frame = Instance.new("Frame")
    frame.Name = "VisualsContent"
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.Parent = Content

    local function AddToggle(y, text, default, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 0, 45)
        f.Position = UDim2.new(0, 10, 0, y)
        f.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        f.Parent = frame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.68,0,1,0)
        lbl.Position = UDim2.new(0,15,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 32)
        btn.Position = UDim2.new(1, -95, 0.5, -16)
        btn.BackgroundColor3 = default and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    AddToggle(10, "🔄 Rayo X Activado", true, function(v) xrayEnabled = v; applyXRay() end)
    AddToggle(65, "⛏️ Mostrar Minerales", true, function(v) showMinerals = v; applyXRay() end)
    AddToggle(120, "💎 Mostrar Gemas", true, function(v) showGems = v; applyXRay() end)
end

-- ==================== MISC ====================
local function CreateMiscContent()
    local frame = Instance.new("Frame")
    frame.Name = "MiscContent"
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.Parent = Content

    local function AddToggle(y, text, default, callback)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 0, 45)
        f.Position = UDim2.new(0, 10, 0, y)
        f.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        f.Parent = frame
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.68,0,1,0)
        lbl.Position = UDim2.new(0,15,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255,255,255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 32)
        btn.Position = UDim2.new(1, -95, 0.5, -16)
        btn.BackgroundColor3 = default and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50)
        btn.Text = default and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamBold
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local state = default
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.BackgroundColor3 = state and Color3.fromRGB(0,200,100) or Color3.fromRGB(200,50,50)
            btn.Text = state and "ON" or "OFF"
            callback(state)
        end)
    end

    AddToggle(10, "⛏️ Auto Mine", false, function(v) 
        autoMineEnabled = v 
        if v then startAutoMine() else 
            if connections.autoMine then connections.autoMine:Disconnect() end 
        end 
    end)

    AddToggle(65, "⚡ Speed Hack", false, toggleSpeed)
    AddToggle(120, "✈️ Fly (WASD + Space)", false, toggleFly)
    AddToggle(175, "👻 Noclip", false, toggleNoclip)
    AddToggle(230, "↑ Infinite Jump", false, toggleInfJump)
end

-- ==================== STATUS ====================
local function CreateStatusContent()
    local frame = Instance.new("Frame")
    frame.Name = "StatusContent"
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.Parent = Content

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 1, -20)
    statusLabel.Position = UDim2.new(0, 10, 0, 10)
    statusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Text = "Cargando stats..."
    statusLabel.Parent = frame
    Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 12)

    RunService.Heartbeat:Connect(function()
        if not statusLabel.Parent then return end
        local fps = math.floor(1 / RunService.Heartbeat:Wait() + 0.5)
        local ping = player:GetNetworkPing() and math.floor(player:GetNetworkPing() * 1000) or 0
        local players = #Players:GetPlayers()

        statusLabel.Text = "📊 JAVI MOD STATUS\n\n" ..
                           "FPS: " .. fps .. "\n" ..
                           "Ping: " .. ping .. " ms\n" ..
                           "Jugadores: " .. players .. "\n\n" ..
                           "Versión: 1.2"
    end)
end

local function SwitchTab(tabName)
    for _, child in ipairs(Content:GetChildren()) do
        if child:IsA("Frame") then child.Visible = false end
    end

    VisualsTab.BackgroundColor3 = Color3.fromRGB(50,50,55)
    MiscTab.BackgroundColor3 = Color3.fromRGB(50,50,55)
    StatusTab.BackgroundColor3 = Color3.fromRGB(50,50,55)

    if tabName == "Visuals" then
        VisualsTab.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        if not Content:FindFirstChild("VisualsContent") then CreateVisualsContent() end
        Content.VisualsContent.Visible = true
    elseif tabName == "Misc" then
        MiscTab.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        if not Content:FindFirstChild("MiscContent") then CreateMiscContent() end
        Content.MiscContent.Visible = true
    elseif tabName == "Status" then
        StatusTab.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        if not Content:FindFirstChild("StatusContent") then CreateStatusContent() end
        Content.StatusContent.Visible = true
    end
end

VisualsTab.MouseButton1Click:Connect(function() SwitchTab("Visuals") end)
MiscTab.MouseButton1Click:Connect(function() SwitchTab("Misc") end)
StatusTab.MouseButton1Click:Connect(function() SwitchTab("Status") end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if MainFrame.Visible then
        SwitchTab("Visuals")
    end
end)

-- Draggable
local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(OpenButton)
makeDraggable(MainFrame)

-- Loop Rayo X
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
    if tick() - lastUpdate >= 1.4 and xrayEnabled then
        lastUpdate = tick()
        applyXRay()
    end
end)

print("✅ JAVI MOD v1.2 cargado correctamente!")
print("Toca el botón Δ rojo para abrir el menú")
