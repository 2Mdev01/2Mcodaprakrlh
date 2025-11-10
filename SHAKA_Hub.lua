-- SHAKA Hub Premium v6.1 - Menu Completo e Funcional
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera

-- ════════════════════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ════════════════════════════════════════════════════════════
local CONFIG = {
    NOME = "SHAKA",
    VERSAO = "v6.1",
    COR_ROXO = Color3.fromRGB(139, 0, 255),
    COR_ROXO_HOVER = Color3.fromRGB(170, 50, 255),
    COR_CUSTOM = nil,
    RAINBOW_MODE = false,
    COR_FUNDO = Color3.fromRGB(10, 10, 15),
    COR_FUNDO_2 = Color3.fromRGB(18, 18, 25),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(150, 150, 160),
    COR_SUCESSO = Color3.fromRGB(0, 255, 100),
    COR_ERRO = Color3.fromRGB(255, 50, 80)
}

-- ════════════════════════════════════════════════════════════
-- VARIÁVEIS PERSISTENTES
-- ════════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local ToggleStates = {}
local RainbowHue = 0

-- Estados salvos
local SavedStates = {
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    Fullbright = false,
    ESPEnabled = false,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    RemoveFog = false,
    RemoveShadows = false,
    FOV = 70,
    Brightness = 1,
    MenuRainbowMode = false,
    ColorR = 139,
    ColorG = 0,
    ColorB = 255
}

local ESPObjects = {}

-- Funções para obter cor atual
local function GetCurrentColor()
    if CONFIG.RAINBOW_MODE then
        return Color3.fromHSV(RainbowHue, 1, 1)
    elseif CONFIG.COR_CUSTOM then
        return CONFIG.COR_CUSTOM
    else
        return CONFIG.COR_ROXO
    end
end

local function GetCurrentColorHover()
    if CONFIG.RAINBOW_MODE then
        return Color3.fromHSV((RainbowHue + 0.05) % 1, 1, 1)
    elseif CONFIG.COR_CUSTOM then
        local r, g, b = CONFIG.COR_CUSTOM.R, CONFIG.COR_CUSTOM.G, CONFIG.COR_CUSTOM.B
        return Color3.new(math.min(r * 1.2, 1), math.min(g * 1.2, 1), math.min(b * 1.2, 1))
    else
        return CONFIG.COR_ROXO_HOVER
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ════════════════════════════════════════════════════════════
local function Log(msg)
    print("[SHAKA] " .. msg)
end

local function Tween(obj, props, time)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local function Notify(text, color)
    task.spawn(function()
        if not GUI then return end
        
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 300, 0, 60)
        notif.Position = UDim2.new(1, -310, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or GetCurrentColor()
        stroke.Thickness = 2
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -310, 1, -70)}, 0.3)
        task.wait(3)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -70)}, 0.3)
        task.wait(0.3)
        if notif and notif.Parent then notif:Destroy() end
    end)
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DO PLAYER
-- ════════════════════════════════════════════════════════════
local function ToggleFly(state)
    SavedStates.FlyEnabled = state
    
    if Connections.Fly then
        Connections.Fly:Disconnect()
        Connections.Fly = nil
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    
    if state then
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.P = 9e4
        bodyGyro.Parent = root
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = root
        
        Connections.Fly = RunService.Heartbeat:Connect(function()
            if not char or not char.Parent or not root or not root.Parent then
                ToggleFly(false)
                return
            end
            
            local moveVector = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveVector = moveVector + (Camera.CFrame.LookVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveVector = moveVector - (Camera.CFrame.LookVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveVector = moveVector - (Camera.CFrame.RightVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveVector = moveVector + (Camera.CFrame.RightVector * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveVector = moveVector + (Vector3.new(0, 1, 0) * SavedStates.FlySpeed)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveVector = moveVector - (Vector3.new(0, 1, 0) * SavedStates.FlySpeed)
            end
            
            bodyVelocity.Velocity = moveVector
            bodyGyro.CFrame = Camera.CFrame
        end)
        
        Notify("✈️ Fly ativado! [WASD/Space/Shift]", CONFIG.COR_SUCESSO)
    else
        if root then
            local gyro = root:FindFirstChild("FlyGyro")
            local velocity = root:FindFirstChild("FlyVelocity")
            if gyro then gyro:Destroy() end
            if velocity then velocity:Destroy() end
        end
        Notify("✈️ Fly desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleNoclip(state)
    SavedStates.NoclipEnabled = state
    
    if Connections.Noclip then
        Connections.Noclip:Disconnect()
        Connections.Noclip = nil
    end
    
    if state then
        Connections.Noclip = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Notify("👻 Noclip ativado", CONFIG.COR_SUCESSO)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        Notify("👻 Noclip desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleInfJump(state)
    SavedStates.InfJumpEnabled = state
    
    if Connections.InfJump then
        Connections.InfJump:Disconnect()
        Connections.InfJump = nil
    end
    
    if state then
        Connections.InfJump = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
        Notify("🦘 Pulo Infinito ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🦘 Pulo Infinito desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleGodMode(state)
    SavedStates.GodMode = state
    
    if Connections.GodMode then
        Connections.GodMode:Disconnect()
        Connections.GodMode = nil
    end
    
    if state then
        Connections.GodMode = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("🛡️ God Mode ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🛡️ God Mode desativado", CONFIG.COR_ERRO)
    end
end

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if humanoid.WalkSpeed ~= SavedStates.WalkSpeed then
                    humanoid.WalkSpeed = SavedStates.WalkSpeed
                end
                if humanoid.JumpPower ~= SavedStates.JumpPower then
                    humanoid.JumpPower = SavedStates.JumpPower
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE TELEPORTE
-- ════════════════════════════════════════════════════════════
local function TeleportToPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            local wasNoclip = SavedStates.NoclipEnabled
            if wasNoclip then
                ToggleNoclip(false)
            end
            
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            
            if wasNoclip then
                task.wait(0.1)
                ToggleNoclip(true)
            end
            
            Notify("🚀 Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
        else
            Notify("❌ Erro ao teleportar", CONFIG.COR_ERRO)
        end
    else
        Notify("❌ Jogador não encontrado", CONFIG.COR_ERRO)
    end
end

local function BringPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        
        if root and targetRoot then
            targetRoot.CFrame = root.CFrame * CFrame.new(0, 0, -3)
            Notify("🔙 " .. SelectedPlayer.Name .. " trazido", CONFIG.COR_SUCESSO)
        end
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE COMBAT (CORRIGIDAS E FUNCIONAIS)
-- ════════════════════════════════════════════════════════════
local function KillPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(humanoid.MaxHealth)
            humanoid.Health = 0
            
            for _, part in pairs(targetChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part:BreakJoints()
                end
            end
            
            Notify("💀 " .. SelectedPlayer.Name .. " eliminado", CONFIG.COR_SUCESSO)
        end
    end
end

local function ExplodePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            for i = 1, 3 do
                local explosion = Instance.new("Explosion")
                explosion.Position = root.Position
                explosion.BlastRadius = 25
                explosion.BlastPressure = 500000
                explosion.DestroyJointRadiusPercent = 1
                explosion.Parent = workspace
                task.wait(0.1)
            end
            Notify("💥 Explosão criada!", CONFIG.COR_SUCESSO)
        end
    end
end

local function BurnPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
        
        for _, part in pairs(targetChar:GetChildren()) do
            if part:IsA("BasePart") then
                local fire = Instance.new("Fire")
                fire.Size = 20
                fire.Heat = 25
                fire.Parent = part
                
                task.spawn(function()
                    for i = 1, 10 do
                        if humanoid and humanoid.Parent then
                            humanoid:TakeDamage(10)
                        end
                        task.wait(0.5)
                    end
                end)
            end
        end
        Notify("🔥 Jogador incendiado!", CONFIG.COR_SUCESSO)
    end
end

local function FlingPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            for _, part in pairs(targetChar:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(
                math.random(-500, 500),
                500,
                math.random(-500, 500)
            )
            bodyVelocity.Parent = root
            
            task.spawn(function()
                task.wait(0.5)
                if bodyVelocity and bodyVelocity.Parent then
                    bodyVelocity:Destroy()
                end
                task.wait(1)
                for _, part in pairs(targetChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end)
            
            Notify("🌪️ " .. SelectedPlayer.Name .. " arremessado!", CONFIG.COR_SUCESSO)
        end
    end
end

local function FreezePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = true
            end
        end
        
        for _, part in pairs(targetChar:GetChildren()) do
            if part:IsA("BasePart") then
                local ice = Instance.new("Part")
                ice.Size = part.Size * 1.1
                ice.CFrame = part.CFrame
                ice.Transparency = 0.5
                ice.Color = Color3.fromRGB(150, 200, 255)
                ice.Material = Enum.Material.Ice
                ice.CanCollide = false
                ice.Anchored = true
                ice.Parent = part
            end
        end
        
        Notify("❄️ " .. SelectedPlayer.Name .. " congelado!", CONFIG.COR_SUCESSO)
    end
end

local function UnfreezePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
            end
        end
        
        for _, part in pairs(targetChar:GetChildren()) do
            if part:IsA("BasePart") then
                for _, child in pairs(part:GetChildren()) do
                    if child:IsA("Part") and child.Material == Enum.Material.Ice then
                        child:Destroy()
                    end
                end
            end
        end
        
        Notify("🔥 " .. SelectedPlayer.Name .. " descongelado!", CONFIG.COR_SUCESSO)
    end
end

local function SpinPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local spin = Instance.new("BodyAngularVelocity")
            spin.MaxTorque = Vector3.new(0, math.huge, 0)
            spin.AngularVelocity = Vector3.new(0, 100, 0)
            spin.Parent = root
            
            task.spawn(function()
                task.wait(5)
                if spin and spin.Parent then
                    spin:Destroy()
                end
            end)
            
            Notify("🌀 " .. SelectedPlayer.Name .. " girando!", CONFIG.COR_SUCESSO)
        end
    end
end

local function LaunchPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        local root = targetChar:FindFirstChild("HumanoidRootPart")
        if root then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVelocity.Velocity = Vector3.new(0, 1000, 0)
            bodyVelocity.Parent = root
            
            task.wait(0.3)
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
            
            Notify("🚀 " .. SelectedPlayer.Name .. " lançado!", CONFIG.COR_SUCESSO)
        end
    end
end

local function InvisiblePlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for _, part in pairs(targetChar:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = 1
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                end
            end
        end
        
        Notify("👻 " .. SelectedPlayer.Name .. " invisível!", CONFIG.COR_SUCESSO)
    end
end

local function CrashPlayer()
    if not SelectedPlayer then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local targetChar = SelectedPlayer.Character
    if targetChar then
        for i = 1, 1000 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(10, 10, 10)
            part.CFrame = targetChar.HumanoidRootPart.CFrame
            part.Anchored = false
            part.CanCollide = true
            part.Parent = workspace
            
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(
                math.random(-100, 100),
                math.random(-100, 100),
                math.random(-100, 100)
            )
            bodyVelocity.Parent = part
            
            task.spawn(function()
                task.wait(5)
                if part and part.Parent then
                    part:Destroy()
                end
            end)
        end
        
        Notify("💥 Sobrecarga enviada!", CONFIG.COR_SUCESSO)
    end
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        if esp.Box then esp.Box:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.Health then esp.Health:Remove() end
    end
    ESPObjects = {}
end

local function CreateESP(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local esp = {
        Player = player,
        Box = nil,
        Line = nil,
        Name = nil,
        Distance = nil,
        Health = nil
    }
    
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = Color3.new(1, 0, 1)
        esp.Box.Transparency = 1
        esp.Box.Visible = false
        esp.Box.ZIndex = 2
    end
    
    if SavedStates.ESPLine then
        esp.Line = Drawing.new("Line")
        esp.Line.Thickness = 2
        esp.Line.Color = Color3.new(1, 0, 1)
        esp.Line.Transparency = 1
        esp.Line.Visible = false
        esp.Line.ZIndex = 2
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 16
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Transparency = 1
        esp.Name.Visible = false
        esp.Name.ZIndex = 2
        esp.Name.Text = player.Name
    end
    
    if SavedStates.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 14
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = Color3.new(1, 1, 0)
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
        esp.Distance.ZIndex = 2
    end
    
    if SavedStates.ESPHealth then
        esp.Health = Drawing.new("Line")
        esp.Health.Thickness = 4
        esp.Health.Transparency = 1
        esp.Health.Visible = false
        esp.Health.ZIndex = 2
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    if not SavedStates.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent or player == LocalPlayer then
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char then
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.Health then esp.Health.Visible = false end
            continue
        end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if root and head and humanoid and humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and rootPos.Z > 0 then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                if esp.Box and SavedStates.ESPBox then
                    esp.Box.Size = Vector2.new(width, height)
                    esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                    esp.Box.Visible = true
                end
                
                if esp.Line and SavedStates.ESPLine then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Line.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 25)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Text = string.format("[%d studs]", math.floor(distance))
                    esp.Distance.Visible = true
                end
                
                if esp.Health and SavedStates.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    
                    esp.Health.From = Vector2.new(rootPos.X - width/2 - 6, rootPos.Y + height/2)
                    esp.Health.To = Vector2.new(rootPos.X - width/2 - 6, rootPos.Y + height/2 - barHeight)
                    esp.Health.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    esp.Health.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Line then esp.Line.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.Health then esp.Health.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.Health then esp.Health.Visible = false end
        end
    end
end

local function ToggleESP(state)
    SavedStates.ESPEnabled = state
    
    if Connections.ESP then
        Connections.ESP:Disconnect()
        Connections.ESP = nil
    end
    
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            CreateESP(player)
        end
        
        Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)
        Notify("👁️ ESP ativado", CONFIG.COR_SUCESSO)
    else
        ClearESP()
        Notify("👁️ ESP desativado", CONFIG.COR_ERRO)
    end
end

Players.PlayerAdded:Connect(function(player)
    if SavedStates.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.Box then esp.Box:Remove() end
        if esp.Line then esp.Line:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.Health then esp.Health:Remove() end
        ESPObjects[player] = nil
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ════════════════════════════════════════════════════════════
local function ToggleFullbright(state)
    SavedStates.Fullbright = state
    
    if state then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e10
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Ambient = Color3.new(1, 1, 1)
        Notify("💡 Fullbright ativado", CONFIG.COR_SUCESSO)
    else
        Lighting.Brightness = SavedStates.Brightness
        Lighting.FogEnd = 1e5
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Ambient = Color3.new(0, 0, 0)
        Notify("💡 Fullbright desativado", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- CRIAÇÃO DA GUI
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 750, 0, 520)
    main.Position = UDim2.new(0.5, -375, 0.5, -260)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = GetCurrentColor()
    mainStroke.Thickness = 2
    
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 150, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "🟣 SHAKA HUB"
    logo.TextColor3 = GetCurrentColor()
    logo.TextSize = 22
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 65, 0, 24)
    version.Position = UDim2.new(0, 175, 0, 13)
    version.BackgroundColor3 = GetCurrentColor()
    version.Text = CONFIG.VERSAO
    version.TextColor3 = CONFIG.COR_TEXTO
    version.TextSize = 13
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    
    Instance.new("UICorner", version).CornerRadius = UDim.new(0, 6)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -45, 0, 7)
    closeBtn.BackgroundColor3 = CONFIG.COR_ERRO
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.COR_TEXTO
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
        task.wait(0.2)
        GUI:Destroy()
        GUI = nil
    end)
    
    -- Sistema de arrastar
    local dragging, dragInput, dragStart, startPos
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    RunService.Heartbeat:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Lista de Jogadores
    local playerListContainer = Instance.new("Frame")
    playerListContainer.Size = UDim2.new(0, 240, 1, -60)
    playerListContainer.Position = UDim2.new(0, 10, 0, 55)
    playerListContainer.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerListContainer.BorderSizePixel = 0
    playerListContainer.Visible = false
    playerListContainer.Parent = main
    
    Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 10)
    
    local playerListTitle = Instance.new("TextLabel")
    playerListTitle.Size = UDim2.new(1, 0, 0, 35)
    playerListTitle.BackgroundColor3 = GetCurrentColor()
    playerListTitle.Text = "🎯 JOGADORES ONLINE"
    playerListTitle.TextColor3 = CONFIG.COR_TEXTO
    playerListTitle.TextSize = 14
    playerListTitle.Font = Enum.Font.GothamBold
    playerListTitle.BorderSizePixel = 0
    playerListTitle.Parent = playerListContainer
    
    Instance.new("UICorner", playerListTitle).CornerRadius = UDim.new(0, 10)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 30)
    selectedLabel.Position = UDim2.new(0, 5, 0, 40)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.Text = "👤 Nenhum selecionado"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 11
    selectedLabel.Font = Enum.Font.GothamBold
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerListContainer
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 8)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 1, -80)
    playerScroll.Position = UDim2.new(0, 5, 0, 75)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 4
    playerScroll.ScrollBarImageColor3 = GetCurrentColor()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerListContainer
    
    local playerLayout = Instance.new("UIListLayout")
    playerLayout.Padding = UDim.new(0, 5)
    playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerLayout.Parent = playerScroll
    
    playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 5)
    end)
    
    local function UpdatePlayerList()
        playerScroll:ClearAllChildren()
        
        local playerLayout = Instance.new("UIListLayout")
        playerLayout.Padding = UDim.new(0, 5)
        playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        playerLayout.Parent = playerScroll
        
        playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 5)
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -5, 0, 38)
                playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
                playerBtn.Text = "  👤 " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 13
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = playerScroll
                
                Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 6)
                
                if SelectedPlayer == player then
                    playerBtn.BackgroundColor3 = GetCurrentColor()
                end
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    selectedLabel.Text = "👤 " .. player.Name
                    selectedLabel.TextColor3 = GetCurrentColor()
                    
                    for _, btn in pairs(playerScroll:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
                        end
                    end
                    
                    Tween(playerBtn, {BackgroundColor3 = GetCurrentColor()}, 0.1)
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.1)
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundColor3 = CONFIG.COR_FUNDO}, 0.1)
                    end
                end)
            end
        end
    end
    
    UpdatePlayerList()
    
    task.spawn(function()
        while GUI do
            UpdatePlayerList()
            task.wait(2)
        end
    end)
    
    -- Container de Abas
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 720, 1, -60)
    tabContainer.Position = UDim2.new(0, 10, 0, 55)
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = main
    
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 45)
    tabBar.BackgroundTransparency = 1
    tabBar.BorderSizePixel = 0
    tabBar.Parent = tabContainer
    
    local tabBarLayout = Instance.new("UIListLayout")
    tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
    tabBarLayout.Padding = UDim.new(0, 5)
    tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabBarLayout.Parent = tabBar
    
    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, -50)
    tabContent.Position = UDim2.new(0, 0, 0, 50)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = tabContainer
    
    local tabs = {
        {Name = "Player", Icon = "👤", ShowPlayerList = false},
        {Name = "Combat", Icon = "⚔️", ShowPlayerList = true},
        {Name = "Teleport", Icon = "📍", ShowPlayerList = true},
        {Name = "ESP", Icon = "👁️", ShowPlayerList = false},
        {Name = "Visual", Icon = "✨", ShowPlayerList = false},
        {Name = "Config", Icon = "⚙️", ShowPlayerList = false}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    
    local function CreateToggle(name, desc, savedKey, callback, parent)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -10, 0, 65)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 15
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.7, 0, 0, 20)
        descLabel.Position = UDim2.new(0, 12, 0, 35)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        descLabel.TextSize = 11
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = toggle
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 55, 0, 26)
        btn.Position = UDim2.new(1, -65, 0.5, -13)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 13)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 22, 0, 22)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = btn
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 11)
        
        local state = SavedStates[savedKey] or false
        
        if state then
            btn.BackgroundColor3 = GetCurrentColor()
            knob.Position = UDim2.new(0, 31, 0, 2)
        end
        
        ToggleStates[savedKey] = btn
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            SavedStates[savedKey] = state
            
            if state then
                Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 31, 0, 2)}, 0.15)
            else
                Tween(btn, {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.15)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateSlider(name, min, max, savedKey, callback, parent)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -10, 0, 75)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
        nameLabel.Position = UDim2.new(0, 12, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 15
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local default = SavedStates[savedKey] or min
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = GetCurrentColor()
        valueLabel.TextSize = 15
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 48)
        track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 3)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = GetCurrentColor()
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 3)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 8)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -8, 0.5, -8)
            valueLabel.Text = tostring(value)
            
            SavedStates[savedKey] = value
            callback(value)
        end
        
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
        
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                update(input)
            end
        end)
        
        return slider
    end
    
    local function CreateButton(text, callback, parent)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 45)
        btn.BackgroundColor3 = GetCurrentColor()
        btn.Text = text
        btn.TextColor3 = CONFIG.COR_TEXTO
        btn.TextSize = 15
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = GetCurrentColorHover()}, 0.15)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 115, 0, 40)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_2
        tabBtn.Text = tab.Icon .. " " .. tab.Name
        tabBtn.TextColor3 = CONFIG.COR_TEXTO
        tabBtn.TextSize = 13
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        
        local tabFrame = Instance.new("ScrollingFrame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.ScrollBarThickness = 4
        tabFrame.ScrollBarImageColor3 = GetCurrentColor()
        tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabFrame.Visible = false
        tabFrame.Parent = tabContent
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            if tab.ShowPlayerList then
                playerListContainer.Visible = true
                tabContainer.Size = UDim2.new(0, 480, 1, -60)
                tabContainer.Position = UDim2.new(0, 260, 0, 55)
            else
                playerListContainer.Visible = false
                tabContainer.Size = UDim2.new(0, 720, 1, -60)
                tabContainer.Position = UDim2.new(0, 10, 0, 55)
            end
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundColor3 = CONFIG.COR_FUNDO_2}, 0.15)
                end
            end
            
            Tween(tabBtn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
        end)
        
        if i == 1 then
            tabBtn.BackgroundColor3 = GetCurrentColor()
            tabFrame.Visible = true
            playerListContainer.Visible = false
            tabContainer.Size = UDim2.new(0, 720, 1, -60)
            tabContainer.Position = UDim2.new(0, 10, 0, 55)
        end
    end
    
    -- CONTEÚDO DAS ABAS
    
    -- ABA PLAYER
    CreateToggle("✈️ Fly", "Voar pelo mapa com WASD/Space/Shift", "FlyEnabled", ToggleFly, tabFrames["Player"])
    CreateSlider("🚀 Velocidade Fly", 10, 200, "FlySpeed", function(value)
        SavedStates.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("👻 Noclip", "Atravessar paredes e objetos", "NoclipEnabled", ToggleNoclip, tabFrames["Player"])
    CreateToggle("🦘 Pulo Infinito", "Pular infinitas vezes no ar", "InfJumpEnabled", ToggleInfJump, tabFrames["Player"])
    
    CreateSlider("🏃 Velocidade", 16, 250, "WalkSpeed", function(value)
        SavedStates.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateSlider("⬆️ Força do Pulo", 50, 400, "JumpPower", function(value)
        SavedStates.JumpPower = value
    end, tabFrames["Player"])
    
    CreateToggle("🛡️ God Mode", "Vida infinita", "GodMode", ToggleGodMode, tabFrames["Player"])
    
    CreateButton("🔄 Resetar Personagem", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("Personagem resetado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Player"])
    
    CreateButton("⚡ Remover Ferramentas", function()
        LocalPlayer.Backpack:ClearAllChildren()
        if LocalPlayer.Character then
            for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
                if tool:IsA("Tool") then
                    tool:Destroy()
                end
            end
        end
        Notify("Ferramentas removidas", CONFIG.COR_SUCESSO)
    end, tabFrames["Player"])
    
    -- ABA COMBAT
    CreateButton("💀 Eliminar Jogador", KillPlayer, tabFrames["Combat"])
    CreateButton("💥 Explodir Jogador", ExplodePlayer, tabFrames["Combat"])
    CreateButton("🔥 Incendiar Jogador", BurnPlayer, tabFrames["Combat"])
    CreateButton("🌪️ Arremessar Jogador", FlingPlayer, tabFrames["Combat"])
    CreateButton("❄️ Congelar Jogador", FreezePlayer, tabFrames["Combat"])
    CreateButton("🔥 Descongelar Jogador", UnfreezePlayer, tabFrames["Combat"])
    CreateButton("🌀 Girar Jogador", SpinPlayer, tabFrames["Combat"])
    CreateButton("🚀 Lançar para Cima", LaunchPlayer, tabFrames["Combat"])
    CreateButton("👻 Tornar Invisível", InvisiblePlayer, tabFrames["Combat"])
    CreateButton("💥 Crash Jogador (Lag)", CrashPlayer, tabFrames["Combat"])
    
    -- ABA TELEPORT
    CreateButton("🚀 Teleportar para Jogador", TeleportToPlayer, tabFrames["Teleport"])
    CreateButton("🔙 Trazer Jogador", BringPlayer, tabFrames["Teleport"])
    
    CreateButton("🏠 Voltar ao Spawn", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
                if spawn then
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                    Notify("Teleportado para spawn", CONFIG.COR_SUCESSO)
                else
                    root.CFrame = CFrame.new(0, 50, 0)
                    Notify("Teleportado para origem", CONFIG.COR_SUCESSO)
                end
            end
        end
    end, tabFrames["Teleport"])
    
    CreateButton("⬆️ Teleport +10 Studs Cima", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame + Vector3.new(0, 10, 0)
                Notify("Teleportado 10 studs acima", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    CreateButton("📌 Salvar Posição", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                SavedStates.SavedPosition = root.CFrame
                Notify("✅ Posição salva!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    CreateButton("📍 Voltar para Posição Salva", function()
        if not SavedStates.SavedPosition then
            Notify("⚠️ Nenhuma posição salva!", CONFIG.COR_ERRO)
            return
        end
        
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = SavedStates.SavedPosition
                Notify("Teleportado para posição salva", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    -- ABA ESP
    CreateToggle("👁️ Ativar ESP", "Sistema de visão de jogadores", "ESPEnabled", ToggleESP, tabFrames["ESP"])
    
    CreateToggle("📦 Box ESP", "Caixas ao redor dos jogadores", "ESPBox", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📏 Line ESP", "Linhas conectando você aos jogadores", "ESPLine", function(state)
        SavedStates.ESPLine = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📝 Name ESP", "Mostrar nomes dos jogadores", "ESPName", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📍 Distance ESP", "Mostrar distância dos jogadores", "ESPDistance", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("❤️ Health ESP", "Barra de vida dos jogadores", "ESPHealth", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    -- ABA VISUAL
    CreateToggle("💡 Fullbright", "Iluminação máxima", "Fullbright", ToggleFullbright, tabFrames["Visual"])
    
    CreateToggle("🌫️ Remover Fog", "Remover neblina", "RemoveFog", function(state)
        SavedStates.RemoveFog = state
        if state then
            Lighting.FogEnd = 1e10
            Lighting.FogStart = 0
            Notify("Fog removido", CONFIG.COR_SUCESSO)
        else
            Lighting.FogEnd = 1e5
            Lighting.FogStart = 0
            Notify("Fog restaurado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Visual"])
    
    CreateToggle("🌑 Remover Sombras", "Desativar sombras", "RemoveShadows", function(state)
        SavedStates.RemoveShadows = state
        Lighting.GlobalShadows = not state
        if state then
            Notify("Sombras removidas", CONFIG.COR_SUCESSO)
        else
            Notify("Sombras restauradas", CONFIG.COR_ERRO)
        end
    end, tabFrames["Visual"])
    
    CreateSlider("☀️ Brilho", 0, 10, "Brightness", function(value)
        SavedStates.Brightness = value
        Lighting.Brightness = value
    end, tabFrames["Visual"])
    
    CreateSlider("🔭 Campo de Visão (FOV)", 70, 120, "FOV", function(value)
        SavedStates.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    CreateButton("⏰ Dia Permanente", function()
        Lighting.ClockTime = 14
        if Connections.TimeFreeze then
            Connections.TimeFreeze:Disconnect()
        end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 14
        end)
        Notify("⏰ Dia permanente ativado", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🌙 Noite Permanente", function()
        Lighting.ClockTime = 0
        if Connections.TimeFreeze then
            Connections.TimeFreeze:Disconnect()
        end
        Connections.TimeFreeze = RunService.Heartbeat:Connect(function()
            Lighting.ClockTime = 0
        end)
        Notify("🌙 Noite permanente ativada", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🔄 Restaurar Tempo Normal", function()
        if Connections.TimeFreeze then
            Connections.TimeFreeze:Disconnect()
            Connections.TimeFreeze = nil
        end
        Notify("Tempo restaurado", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🎨 Céu Colorido", function()
        local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
        sky.SkyboxBk = "rbxassetid://48020371"
        sky.SkyboxDn = "rbxassetid://48020144"
        sky.SkyboxFt = "rbxassetid://48020359"
        sky.SkyboxLf = "rbxassetid://48020320"
        sky.SkyboxRt = "rbxassetid://48020315"
        sky.SkyboxUp = "rbxassetid://48020383"
        Notify("🎨 Céu alterado!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    CreateButton("🌈 Modo Rainbow (Lighting)", function()
        if Connections.Rainbow then
            Connections.Rainbow:Disconnect()
            Connections.Rainbow = nil
            Lighting.Ambient = Color3.new(0, 0, 0)
            Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
            Notify("Modo Rainbow desativado", CONFIG.COR_ERRO)
        else
            local hue = 0
            Connections.Rainbow = RunService.Heartbeat:Connect(function()
                hue = (hue + 0.01) % 1
                local color = Color3.fromHSV(hue, 1, 1)
                Lighting.Ambient = color
                Lighting.OutdoorAmbient = color
            end)
            Notify("🌈 Modo Rainbow ativado!", CONFIG.COR_SUCESSO)
        end
    end, tabFrames["Visual"])
    
    CreateButton("⚡ Otimizar FPS", function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
        
        Notify("⚡ FPS otimizado!", CONFIG.COR_SUCESSO)
    end, tabFrames["Visual"])
    
    -- ABA CONFIG
    local colorTitle = Instance.new("TextLabel")
    colorTitle.Size = UDim2.new(1, -10, 0, 35)
    colorTitle.BackgroundColor3 = GetCurrentColor()
    colorTitle.Text = "🎨 CUSTOMIZAÇÃO DE CORES"
    colorTitle.TextColor3 = CONFIG.COR_TEXTO
    colorTitle.TextSize = 14
    colorTitle.Font = Enum.Font.GothamBold
    colorTitle.BorderSizePixel = 0
    colorTitle.Parent = tabFrames["Config"]
    Instance.new("UICorner", colorTitle).CornerRadius = UDim.new(0, 8)
    
    CreateToggle("🌈 Modo Rainbow (Menu)", "Cores do menu mudam constantemente", "MenuRainbowMode", function(state)
        CONFIG.RAINBOW_MODE = state
        
        if Connections.MenuRainbow then
            Connections.MenuRainbow:Disconnect()
            Connections.MenuRainbow = nil
        end
        
        if state then
            Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
                RainbowHue = (RainbowHue + 0.005) % 1
            end)
            
            Notify("🌈 Modo Rainbow do Menu ativado!", CONFIG.COR_SUCESSO)
        else
            CONFIG.COR_CUSTOM = nil
            Notify("🌈 Modo Rainbow desativado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Config"])
    
    CreateSlider("🔴 Vermelho (R)", 0, 255, "ColorR", function(value)
        if not CONFIG.RAINBOW_MODE then
            local r = value / 255
            local g = (SavedStates.ColorG or 0) / 255
            local b = (SavedStates.ColorB or 255) / 255
            CONFIG.COR_CUSTOM = Color3.new(r, g, b)
            CONFIG.COR_ROXO = CONFIG.COR_CUSTOM
        end
    end, tabFrames["Config"])
    
    CreateSlider("🟢 Verde (G)", 0, 255, "ColorG", function(value)
        if not CONFIG.RAINBOW_MODE then
            local r = (SavedStates.ColorR or 139) / 255
            local g = value / 255
            local b = (SavedStates.ColorB or 255) / 255
            CONFIG.COR_CUSTOM = Color3.new(r, g, b)
            CONFIG.COR_ROXO = CONFIG.COR_CUSTOM
        end
    end, tabFrames["Config"])
    
    CreateSlider("🔵 Azul (B)", 0, 255, "ColorB", function(value)
        if not CONFIG.RAINBOW_MODE then
            local r = (SavedStates.ColorR or 139) / 255
            local g = (SavedStates.ColorG or 0) / 255
            local b = value / 255
            CONFIG.COR_CUSTOM = Color3.new(r, g, b)
            CONFIG.COR_ROXO = CONFIG.COR_CUSTOM
        end
    end, tabFrames["Config"])
    
    local presetColors = {
        {Name = "🟣 Roxo Original", Color = Color3.fromRGB(139, 0, 255)},
        {Name = "🔴 Vermelho", Color = Color3.fromRGB(255, 0, 0)},
        {Name = "🔵 Azul", Color = Color3.fromRGB(0, 100, 255)},
        {Name = "🟢 Verde", Color = Color3.fromRGB(0, 255, 100)},
        {Name = "🟡 Amarelo", Color = Color3.fromRGB(255, 220, 0)},
        {Name = "🟠 Laranja", Color = Color3.fromRGB(255, 140, 0)},
        {Name = "💗 Rosa", Color = Color3.fromRGB(255, 0, 150)},
        {Name = "🔵 Ciano", Color = Color3.fromRGB(0, 255, 255)}
    }
    
    for _, preset in ipairs(presetColors) do
        CreateButton(preset.Name, function()
            if CONFIG.RAINBOW_MODE then
                Notify("⚠️ Desative o Modo Rainbow primeiro!", CONFIG.COR_ERRO)
                return
            end
            
            CONFIG.COR_CUSTOM = preset.Color
            CONFIG.COR_ROXO = preset.Color
            
            SavedStates.ColorR = math.floor(preset.Color.R * 255)
            SavedStates.ColorG = math.floor(preset.Color.G * 255)
            SavedStates.ColorB = math.floor(preset.Color.B * 255)
            
            Notify("Cor alterada!", CONFIG.COR_SUCESSO)
            
            task.wait(0.2)
            CreateGUI()
            ReloadSavedStates()
        end, tabFrames["Config"])
    end
    
    CreateButton("🔄 Resetar para Roxo Original", function()
        CONFIG.RAINBOW_MODE = false
        CONFIG.COR_CUSTOM = nil
        CONFIG.COR_ROXO = Color3.fromRGB(139, 0, 255)
        
        SavedStates.ColorR = 139
        SavedStates.ColorG = 0
        SavedStates.ColorB = 255
        SavedStates.MenuRainbowMode = false
        
        if Connections.MenuRainbow then
            Connections.MenuRainbow:Disconnect()
            Connections.MenuRainbow = nil
        end
        
        Notify("Cores resetadas", CONFIG.COR_SUCESSO)
        
        task.wait(0.2)
        CreateGUI()
        ReloadSavedStates()
    end, tabFrames["Config"])
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -10, 0, 2)
    separator.BackgroundColor3 = CONFIG.COR_FUNDO_2
    separator.BorderSizePixel = 0
    separator.Parent = tabFrames["Config"]
    
    local otherTitle = Instance.new("TextLabel")
    otherTitle.Size = UDim2.new(1, -10, 0, 35)
    otherTitle.BackgroundColor3 = GetCurrentColor()
    otherTitle.Text = "⚙️ OUTRAS CONFIGURAÇÕES"
    otherTitle.TextColor3 = CONFIG.COR_TEXTO
    otherTitle.TextSize = 14
    otherTitle.Font = Enum.Font.GothamBold
    otherTitle.BorderSizePixel = 0
    otherTitle.Parent = tabFrames["Config"]
    Instance.new("UICorner", otherTitle).CornerRadius = UDim.new(0, 8)
    
    CreateButton("🗑️ Limpar Todos os Estados", function()
        for key, _ in pairs(SavedStates) do
            SavedStates[key] = nil
        end
        
        for _, conn in pairs(Connections) do
            if conn and conn.Disconnect then
                conn:Disconnect()
            end
        end
        Connections = {}
        
        Notify("✅ Estados limpos!", CONFIG.COR_SUCESSO)
        
        task.wait(1)
        CreateGUI()
    end, tabFrames["Config"])
    
    CreateButton("📋 Informações do Sistema", function()
        local info = string.format([[
🟣 SHAKA Hub %s
━━━━━━━━━━━━━━━━━
📊 FPS: %d
👥 Jogadores: %d
🎮 Jogo: %s
        ]],
            CONFIG.VERSAO,
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Desconhecido"
        )
        
        Notify(info, GetCurrentColor())
    end, tabFrames["Config"])
    
    main.Size = UDim2.new(0, 0, 0, 0)
    Tween(main, {Size = UDim2.new(0, 750, 0, 520)}, 0.3)
    
    Log("Menu carregado com sucesso!")
    Notify("🟣 SHAKA Hub " .. CONFIG.VERSAO .. " carregado!", GetCurrentColor())
end

local function ReloadSavedStates()
    if SavedStates.FlyEnabled then
        ToggleFly(true)
    end
    
    if SavedStates.NoclipEnabled then
        ToggleNoclip(true)
    end
    
    if SavedStates.InfJumpEnabled then
        ToggleInfJump(true)
    end
    
    if SavedStates.GodMode then
        ToggleGodMode(true)
    end
    
    if SavedStates.ESPEnabled then
        ToggleESP(true)
    end
    
    if SavedStates.Fullbright then
        ToggleFullbright(true)
    end
    
    if SavedStates.RemoveFog then
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 0
    end
    
    if SavedStates.RemoveShadows then
        Lighting.GlobalShadows = false
    end
    
    Camera.FieldOfView = SavedStates.FOV
    Lighting.Brightness = SavedStates.Brightness
    
    if SavedStates.MenuRainbowMode then
        CONFIG.RAINBOW_MODE = true
    end
    
    if SavedStates.ColorR and SavedStates.ColorG and SavedStates.ColorB then
        CONFIG.COR_CUSTOM = Color3.fromRGB(SavedStates.ColorR, SavedStates.ColorG, SavedStates.ColorB)
        CONFIG.COR_ROXO = CONFIG.COR_CUSTOM
    end
end

Log("════════════════════════════════════════")
Log("  SHAKA Hub Premium " .. CONFIG.VERSAO)
Log("  Inicializando sistema...")
Log("════════════════════════════════════════")

task.wait(0.5)

CreateGUI()
ReloadSavedStates()

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if GUI then
            local main = GUI:FindFirstChild("Main")
            if main then
                Tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.2)
                task.wait(0.2)
            end
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado (estados salvos)")
        else
            CreateGUI()
            ReloadSavedStates()
            
            task.wait(0.1)
            for key, btn in pairs(ToggleStates) do
                if SavedStates[key] then
                    btn.BackgroundColor3 = GetCurrentColor()
                    local knob = btn:FindFirstChildOfClass("Frame")
                    if knob then
                        knob.Position = UDim2.new(0, 31, 0, 2)
                    end
                end
            end
            
            Log("Menu aberto (estados restaurados)")
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ReloadSavedStates()
    Log("Personagem resetado - estados recarregados")
end)

Log("✅ Sistema carregado!")
Log("⌨️  Pressione F para abrir/fechar o menu")
Log("💾 Estados salvos e persistentes")
Log("════════════════════════════════════════")
