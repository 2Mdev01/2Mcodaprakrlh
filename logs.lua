-- SECURITY MENU v3.0 - DELTA EXECUTOR COMPATIBLE
-- Sistema de captura REAL de eventos com hooks profundos
-- APENAS para pentest autorizado

local SecurityMenu = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

-- Configurações
SecurityMenu.OpenKey = Enum.KeyCode.F
SecurityMenu.IsOpen = false
SecurityMenu.CurrentTab = "Replay"

-- Dados
SecurityMenu.CapturedEvents = {}
SecurityMenu.Logs = {}
SecurityMenu.Stats = {Total = 0, Remote = 0, Captured = 0}
SecurityMenu.HookedRemotes = {}

--═══════════════════════════════════════════════════════════
-- SISTEMA DE LOG SIMPLES
--═══════════════════════════════════════════════════════════

function SecurityMenu:AddLog(message, data)
    local log = {
        Time = os.date("%H:%M:%S"),
        Message = message,
        Data = data or {}
    }
    
    table.insert(self.Logs, 1, log)
    if #self.Logs > 100 then
        table.remove(self.Logs)
    end
    
    self.Stats.Total = self.Stats.Total + 1
    print("[SecurityMenu]", message)
    
    if self.IsOpen then
        task.spawn(function()
            pcall(function() self:RefreshUI() end)
        end)
    end
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE CAPTURA DE EVENTOS (核心功能)
--═══════════════════════════════════════════════════════════

function SecurityMenu:CaptureRemoteEvent(remote, eventType, args)
    local eventData = {
        Name = remote.Name,
        Type = eventType,
        Path = remote:GetFullName(),
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        Timestamp = tick(),
        ID = #self.CapturedEvents + 1
    }
    
    -- Adicionar à lista
    table.insert(self.CapturedEvents, 1, eventData)
    
    -- Limitar tamanho
    if #self.CapturedEvents > 50 then
        table.remove(self.CapturedEvents)
    end
    
    self.Stats.Captured = #self.CapturedEvents
    self.Stats.Remote = self.Stats.Remote + 1
    
    -- Log detalhado
    local argsStr = "{"
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            argsStr = argsStr .. '"' .. tostring(arg) .. '"'
        else
            argsStr = argsStr .. tostring(arg)
        end
        if i < #args then argsStr = argsStr .. ", " end
    end
    argsStr = argsStr .. "}"
    
    self:AddLog(string.format("🔵 CAPTURADO: %s [%s] Args: %s", 
        remote.Name, eventType, argsStr), eventData)
    
    return eventData
end

--═══════════════════════════════════════════════════════════
-- HOOK DE REMOTE EVENTS (MÉTODO AGRESSIVO)
--═══════════════════════════════════════════════════════════

function SecurityMenu:HookRemote(remote)
    if self.HookedRemotes[remote] then return end
    
    local remoteName = remote.Name
    
    pcall(function()
        if remote:IsA("RemoteEvent") then
            -- Método 1: Hook direto (mais compatível)
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote and method == "FireServer" then
                    SecurityMenu:CaptureRemoteEvent(remote, "RemoteEvent", args)
                end
                
                return oldNamecall(self, ...)
            end)
            
        elseif remote:IsA("RemoteFunction") then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if self == remote and method == "InvokeServer" then
                    SecurityMenu:CaptureRemoteEvent(remote, "RemoteFunction", args)
                end
                
                return oldNamecall(self, ...)
            end)
        end
        
        self.HookedRemotes[remote] = true
        self:AddLog("✅ Hook instalado: " .. remoteName)
    end)
end

-- Hook alternativo usando __index
function SecurityMenu:HookAllRemotesAlternative()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Capturar FireServer
        if method == "FireServer" and typeof(self) == "Instance" then
            if self:IsA("RemoteEvent") then
                task.spawn(function()
                    SecurityMenu:CaptureRemoteEvent(self, "RemoteEvent", args)
                end)
            end
        end
        
        -- Capturar InvokeServer
        if method == "InvokeServer" and typeof(self) == "Instance" then
            if self:IsA("RemoteFunction") then
                task.spawn(function()
                    SecurityMenu:CaptureRemoteEvent(self, "RemoteFunction", args)
                end)
            end
        end
        
        return oldNamecall(self, ...)
    end))
    
    self:AddLog("✅ Hook global de __namecall instalado!")
end

--═══════════════════════════════════════════════════════════
-- SISTEMA DE REPLAY
--═══════════════════════════════════════════════════════════

function SecurityMenu:ReplayEvent(eventData, times)
    times = times or 1
    local successCount = 0
    
    for i = 1, times do
        local success = pcall(function()
            if eventData.Type == "RemoteEvent" then
                eventData.Remote:FireServer(unpack(eventData.Args))
            elseif eventData.Type == "RemoteFunction" then
                eventData.Remote:InvokeServer(unpack(eventData.Args))
            end
        end)
        
        if success then
            successCount = successCount + 1
        end
        
        if times > 1 then
            task.wait(0.05)
        end
    end
    
    self:AddLog(string.format("🔄 REPLAY: %s [%dx] - %d sucesso(s)", 
        eventData.Name, times, successCount))
    
    return successCount
end

function SecurityMenu:StartLooping(eventData)
    if eventData.IsLooping then
        eventData.IsLooping = false
        self:AddLog("⏹️ Loop parado: " .. eventData.Name)
        return
    end
    
    eventData.IsLooping = true
    self:AddLog("🔁 Loop iniciado: " .. eventData.Name)
    
    task.spawn(function()
        while eventData.IsLooping do
            pcall(function()
                if eventData.Type == "RemoteEvent" then
                    eventData.Remote:FireServer(unpack(eventData.Args))
                elseif eventData.Type == "RemoteFunction" then
                    eventData.Remote:InvokeServer(unpack(eventData.Args))
                end
            end)
            task.wait(0.5)
        end
    end)
end

--═══════════════════════════════════════════════════════════
-- SCANNER DE REMOTES
--═══════════════════════════════════════════════════════════

function SecurityMenu:ScanAndHookRemotes()
    self:AddLog("🔍 Escaneando remotes...")
    
    local remoteCount = 0
    
    -- Escanear ReplicatedStorage
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            self:HookRemote(obj)
            remoteCount = remoteCount + 1
        end
    end
    
    -- Escanear Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            self:HookRemote(obj)
            remoteCount = remoteCount + 1
        end
    end
    
    -- Monitorar novos remotes
    local function onDescendantAdded(obj)
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            task.wait(0.1)
            self:HookRemote(obj)
        end
    end
    
    ReplicatedStorage.DescendantAdded:Connect(onDescendantAdded)
    workspace.DescendantAdded:Connect(onDescendantAdded)
    
    self:AddLog(string.format("✅ %d remotes encontrados e hooked!", remoteCount))
end

--═══════════════════════════════════════════════════════════
-- INTERFACE DO USUÁRIO (SIMPLIFICADA)
--═══════════════════════════════════════════════════════════

function SecurityMenu:CreateUI()
    -- Limpar UI antiga
    pcall(function()
        if game:GetService("CoreGui"):FindFirstChild("SecurityMenuV3") then
            game:GetService("CoreGui"):FindFirstChild("SecurityMenuV3"):Destroy()
        end
    end)
    
    -- Criar ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "SecurityMenuV3"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        gui.Parent = game:GetService("CoreGui")
    end)
    
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self.ScreenGui = gui
    
    -- Cores
    local c = {
        bg = Color3.fromRGB(25, 25, 30),
        header = Color3.fromRGB(35, 35, 45),
        button = Color3.fromRGB(50, 50, 60),
        accent = Color3.fromRGB(70, 130, 255),
        success = Color3.fromRGB(76, 175, 80),
        danger = Color3.fromRGB(244, 67, 54),
        warning = Color3.fromRGB(255, 152, 0),
        text = Color3.fromRGB(255, 255, 255),
        text2 = Color3.fromRGB(180, 180, 190)
    }
    self.Colors = c
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 700, 0, 500)
    main.Position = UDim2.new(0.5, -350, 0.5, -250)
    main.BackgroundColor3 = c.bg
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.MainFrame = main
    
    -- Arredondar cantos
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = c.header
    header.BorderSizePixel = 0
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 8)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔒 SECURITY MENU v3.0 - EVENT REPLAY"
    title.TextColor3 = c.text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 25)
    closeBtn.Position = UDim2.new(1, -90, 0.5, -12)
    closeBtn.BackgroundColor3 = c.danger
    closeBtn.Text = "✖ [F]"
    closeBtn.TextColor3 = c.text
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 4)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Stats Bar
    local statsBar = Instance.new("Frame")
    statsBar.Size = UDim2.new(1, 0, 0, 35)
    statsBar.Position = UDim2.new(0, 0, 0, 40)
    statsBar.BackgroundColor3 = c.button
    statsBar.BorderSizePixel = 0
    statsBar.Parent = main
    
    self.StatsLabel = Instance.new("TextLabel")
    self.StatsLabel.Size = UDim2.new(1, -20, 1, 0)
    self.StatsLabel.Position = UDim2.new(0, 10, 0, 0)
    self.StatsLabel.BackgroundTransparency = 1
    self.StatsLabel.Text = "📊 Total: 0 | 🔵 Capturados: 0 | 📡 Remotes: 0"
    self.StatsLabel.TextColor3 = c.text2
    self.StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.StatsLabel.Font = Enum.Font.Gotham
    self.StatsLabel.TextSize = 11
    self.StatsLabel.Parent = statsBar
    
    -- Content Area
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -95)
    content.Position = UDim2.new(0, 10, 0, 80)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 6
    content.ScrollBarImageColor3 = c.accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = main
    
    self.ContentFrame = content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    
    self:AddLog("✅ Interface criada!")
end

function SecurityMenu:RefreshUI()
    if not self.ContentFrame then return end
    
    -- Limpar conteúdo
    for _, child in ipairs(self.ContentFrame:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Atualizar stats
    if self.StatsLabel then
        self.StatsLabel.Text = string.format(
            "📊 Total: %d | 🔵 Capturados: %d | 📡 Remotes: %d",
            self.Stats.Total, self.Stats.Captured, self.Stats.Remote
        )
    end
    
    -- Mostrar eventos capturados
    if #self.CapturedEvents == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 100)
        empty.BackgroundColor3 = self.Colors.header
        empty.Text = "⚠️ NENHUM EVENTO CAPTURADO\n\nInteraja com o jogo para capturar eventos!"
        empty.TextColor3 = self.Colors.text2
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 13
        empty.BorderSizePixel = 0
        empty.Parent = self.ContentFrame
        
        local emptyCorner = Instance.new("UICorner")
        emptyCorner.CornerRadius = UDim.new(0, 6)
        emptyCorner.Parent = empty
        return
    end
    
    -- Criar cards para cada evento
    for i, event in ipairs(self.CapturedEvents) do
        if i > 20 then break end
        self:CreateEventCard(event)
    end
end

function SecurityMenu:CreateEventCard(event)
    local c = self.Colors
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 90)
    card.BackgroundColor3 = c.header
    card.BorderSizePixel = 0
    card.Parent = self.ContentFrame
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card
    
    -- Nome do evento
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -300, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "📡 " .. event.Name .. " [" .. event.Type .. "]"
    nameLabel.TextColor3 = c.accent
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Caminho
    local pathLabel = Instance.new("TextLabel")
    pathLabel.Size = UDim2.new(1, -300, 0, 16)
    pathLabel.Position = UDim2.new(0, 10, 0, 28)
    pathLabel.BackgroundTransparency = 1
    pathLabel.Text = "📁 " .. event.Path
    pathLabel.TextColor3 = c.text2
    pathLabel.TextXAlignment = Enum.TextXAlignment.Left
    pathLabel.Font = Enum.Font.Gotham
    pathLabel.TextSize = 9
    pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
    pathLabel.Parent = card
    
    -- Args
    local argsStr = "Args: {"
    for i, arg in ipairs(event.Args) do
        if type(arg) == "string" then
            argsStr = argsStr .. '"' .. tostring(arg):sub(1, 30) .. '"'
        else
            argsStr = argsStr .. tostring(arg):sub(1, 30)
        end
        if i < #event.Args then argsStr = argsStr .. ", " end
        if #argsStr > 100 then argsStr = argsStr .. "..."; break end
    end
    argsStr = argsStr .. "}"
    
    local argsLabel = Instance.new("TextLabel")
    argsLabel.Size = UDim2.new(1, -300, 0, 16)
    argsLabel.Position = UDim2.new(0, 10, 0, 46)
    argsLabel.BackgroundTransparency = 1
    argsLabel.Text = argsStr
    argsLabel.TextColor3 = c.warning
    argsLabel.TextXAlignment = Enum.TextXAlignment.Left
    argsLabel.Font = Enum.Font.Code
    argsLabel.TextSize = 9
    argsLabel.TextTruncate = Enum.TextTruncate.AtEnd
    argsLabel.Parent = card
    
    -- Hora
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -300, 0, 14)
    timeLabel.Position = UDim2.new(0, 10, 0, 64)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = "🕐 " .. event.Time
    timeLabel.TextColor3 = c.text2
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = card
    
    -- Botões
    local btnWidth = 65
    local btnHeight = 28
    local btnSpacing = 5
    
    -- Replay 1x
    local btn1 = self:CreateButton(card, "▶️ x1", c.success, 1, -285, 8, btnWidth, btnHeight)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    -- Replay 5x
    local btn5 = self:CreateButton(card, "⚡ x5", c.accent, 1, -285, 8 + btnHeight + btnSpacing, btnWidth, btnHeight)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    -- Replay 10x
    local btn10 = self:CreateButton(card, "🔥 x10", c.warning, 1, -215, 8, btnWidth, btnHeight)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    -- Loop
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️ STOP" or "🔁 LOOP", 
        event.IsLooping and c.danger or Color3.fromRGB(156, 39, 176), 
        1, -215, 8 + btnHeight + btnSpacing, btnWidth, btnHeight)
    btnLoop.MouseButton1Click:Connect(function()
        self:StartLooping(event)
        btnLoop.Text = event.IsLooping and "⏹️ STOP" or "🔁 LOOP"
        btnLoop.BackgroundColor3 = event.IsLooping and c.danger or Color3.fromRGB(156, 39, 176)
    end)
    
    -- Custom
    local btnCustom = self:CreateButton(card, "⚙️ x?", Color3.fromRGB(100, 100, 120), 1, -145, 8, btnWidth, btnHeight)
    btnCustom.MouseButton1Click:Connect(function()
        local times = tonumber(prompt and prompt("Quantas vezes repetir?", "1") or "1")
        if times and times > 0 then
            self:ReplayEvent(event, times)
        end
    end)
    
    -- Info
    local btnInfo = self:CreateButton(card, "ℹ️ INFO", c.button, 1, -145, 8 + btnHeight + btnSpacing, btnWidth, btnHeight)
    btnInfo.MouseButton1Click:Connect(function()
        local info = string.format(
            "EVENTO: %s\nTIPO: %s\nHORA: %s\nCAMINHO: %s\nARGS: %s",
            event.Name, event.Type, event.Time, event.Path, 
            game:GetService("HttpService"):JSONEncode(event.Args)
        )
        print("\n" .. string.rep("═", 50))
        print(info)
        print(string.rep("═", 50) .. "\n")
        self:AddLog("ℹ️ Info printada no console: " .. event.Name)
    end)
end

function SecurityMenu:CreateButton(parent, text, color, anchorX, posX, posY, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(anchorX, posX, 0, posY)
    btn.AnchorPoint = Vector2.new(anchorX, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = self.Colors.text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    return btn
end

function SecurityMenu:Toggle()
    self.IsOpen = not self.IsOpen
    if self.MainFrame then
        self.MainFrame.Visible = self.IsOpen
        if self.IsOpen then
            self:RefreshUI()
        end
    end
end

function SecurityMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.OpenKey then
            self:Toggle()
        end
    end)
end

--═══════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
--═══════════════════════════════════════════════════════════

function SecurityMenu:Init()
    print("\n" .. string.rep("═", 60))
    print("🔒 SECURITY MENU v3.0 - EVENT REPLAY SYSTEM")
    print("   Compatível com Delta Executor")
    print(string.rep("═", 60))
    
    -- Criar UI
    self:CreateUI()
    self:AddLog("✅ UI Criada")
    
    -- Configurar keybind
    self:SetupKeybind()
    self:AddLog("⌨️ Keybind [F] configurado")
    
    -- Hook global (método mais eficiente)
    task.wait(0.5)
    self:HookAllRemotesAlternative()
    
    -- Scan de remotes existentes
    task.wait(0.5)
    self:ScanAndHookRemotes()
    
    -- Auto-abrir
    task.wait(1)
    self:Toggle()
    
    print("✅ Security Menu inicializado!")
    print("⌨️ Pressione [F] para abrir/fechar")
    print("🎯 Interaja com o jogo para capturar eventos")
    print(string.rep("═", 60) .. "\n")
end

-- Auto-inicializar
task.spawn(function()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    task.wait(3)
    
    SecurityMenu:Init()
end)

-- Global
getgenv().SecurityMenu = SecurityMenu
_G.SecurityMenu = SecurityMenu

return SecurityMenu
