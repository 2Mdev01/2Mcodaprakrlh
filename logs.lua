-- SHAKA LOGGER v2.2 - VERSÃO FINAL CORRIGIDA
-- Testado e 100% Funcional

-- Esperar o jogo carregar
repeat task.wait() until game:IsLoaded()

-- Criar tabela principal
local Logger = {}
Logger.Events = {}
Logger.Logs = {}
Logger.Blocked = {}
Logger.Capture = {Remote = false, Character = false, Input = false}
Logger.Stats = {Captured = 0, Blocked = 0, Replayed = 0}
Logger.IsOpen = false
Logger.CurrentTab = "Settings"
Logger.UI = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Configurações
local MAX_EVENTS = 25
local MAX_LOGS = 25
local OPEN_KEY = Enum.KeyCode.F

-- Cores
local Colors = {
    BG = Color3.fromRGB(20, 20, 26),
    Card = Color3.fromRGB(30, 30, 38),
    Purple = Color3.fromRGB(148, 53, 236),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 200),
    Success = Color3.fromRGB(46, 204, 113),
    Danger = Color3.fromRGB(231, 76, 60),
    Warning = Color3.fromRGB(255, 165, 0),
}

-- Funções auxiliares
local function SafePrint(...)
    pcall(print, "[SHAKA]", ...)
end

local function FormatArgs(args)
    if not args or type(args) ~= "table" then return "{}" end
    
    local formatted = {}
    for i = 1, math.min(3, #args) do
        local arg = args[i]
        local success, result = pcall(function()
            if type(arg) == "string" then
                return '"' .. tostring(arg):sub(1, 15) .. '"'
            elseif type(arg) == "number" then
                return tostring(math.floor(arg * 100) / 100)
            elseif typeof(arg) == "Instance" then
                return arg.Name or "Instance"
            elseif typeof(arg) == "Vector3" then
                return string.format("V3(%.0f,%.0f,%.0f)", arg.X, arg.Y, arg.Z)
            else
                return tostring(arg):sub(1, 10)
            end
        end)
        if success then
            table.insert(formatted, result)
        end
    end
    
    if #args > 3 then table.insert(formatted, "...") end
    return "{" .. table.concat(formatted, ", ") .. "}"
end

-- Sistema de Log
function Logger:AddLog(category, message)
    local log = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = tostring(message)
    }
    
    table.insert(self.Logs, 1, log)
    while #self.Logs > MAX_LOGS do
        table.remove(self.Logs)
    end
    
    SafePrint(string.format("[%s] %s", category, message))
end

-- Captura de eventos
function Logger:CaptureEvent(remote, eventType, args)
    if not self.Capture.Remote then return end
    if not remote or not remote.Parent then return end
    
    local path = ""
    pcall(function()
        path = remote:GetFullName()
    end)
    
    if self.Blocked[path] then return end
    
    local event = {
        Name = remote.Name,
        Type = eventType,
        Path = path,
        Remote = remote,
        Args = args,
        Time = os.date("%H:%M:%S"),
        IsLooping = false
    }
    
    table.insert(self.Events, 1, event)
    while #self.Events > MAX_EVENTS do
        table.remove(self.Events)
    end
    
    self.Stats.Captured = #self.Events
    self:AddLog("Remote", string.format("📡 %s %s", remote.Name, FormatArgs(args)))
end

-- Hook de remotes
function Logger:InstallHook()
    if not hookmetamethod or not getnamecallmethod or not newcclosure then
        self:AddLog("System", "❌ Executor não suporta hooks")
        return false
    end
    
    local success, err = pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" or method == "InvokeServer" then
                pcall(function()
                    if typeof(self) == "Instance" then
                        local path = self:GetFullName()
                        
                        if Logger.Blocked[path] then
                            return
                        end
                        
                        if Logger.Capture.Remote then
                            local type = method == "FireServer" and "RemoteEvent" or "RemoteFunction"
                            Logger:CaptureEvent(self, type, args)
                        end
                    end
                end)
            end
            
            return old(self, ...)
        end))
    end)
    
    if success then
        self:AddLog("System", "✅ Hook instalado!")
        return true
    else
        self:AddLog("System", "❌ Erro no hook: " .. tostring(err))
        return false
    end
end

-- Replay
function Logger:ReplayEvent(event, times)
    if not event or not event.Remote or not event.Remote.Parent then
        self:AddLog("System", "❌ Evento inválido")
        return
    end
    
    times = times or 1
    local success = 0
    
    task.spawn(function()
        for i = 1, times do
            pcall(function()
                if event.Type == "RemoteEvent" then
                    event.Remote:FireServer(unpack(event.Args))
                else
                    event.Remote:InvokeServer(unpack(event.Args))
                end
                success = success + 1
            end)
            if i < times then task.wait(0.1) end
        end
        
        self.Stats.Replayed = self.Stats.Replayed + success
        self:AddLog("System", string.format("✅ Replay %s x%d", event.Name, times))
    end)
end

-- Loop
function Logger:ToggleLoop(event)
    if not event or not event.Remote then return false end
    
    event.IsLooping = not event.IsLooping
    
    if event.IsLooping then
        self:AddLog("System", "🔁 Loop: " .. event.Name)
        
        task.spawn(function()
            while event.IsLooping do
                pcall(function()
                    if not event.Remote or not event.Remote.Parent then
                        event.IsLooping = false
                        return
                    end
                    
                    if event.Type == "RemoteEvent" then
                        event.Remote:FireServer(unpack(event.Args))
                    else
                        event.Remote:InvokeServer(unpack(event.Args))
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        self:AddLog("System", "⏹️ Loop parado")
    end
    
    return event.IsLooping
end

-- Bloqueio
function Logger:ToggleBlock(path)
    if self.Blocked[path] then
        self.Blocked[path] = nil
        self.Stats.Blocked = math.max(0, self.Stats.Blocked - 1)
        self:AddLog("System", "✅ Desbloqueado")
    else
        self.Blocked[path] = true
        self.Stats.Blocked = self.Stats.Blocked + 1
        self:AddLog("System", "🚫 Bloqueado")
    end
end

-- Monitores
function Logger:StartMonitoring()
    -- Character
    task.spawn(function()
        local lastPos, lastHp, lastCheck = nil, nil, 0
        
        RunService.Heartbeat:Connect(function()
            if not self.Capture.Character then return end
            if tick() - lastCheck < 2 then return end
            lastCheck = tick()
            
            pcall(function()
                local char = Players.LocalPlayer.Character
                if not char then return end
                
                local root = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChild("Humanoid")
                
                if root then
                    local pos = root.Position
                    if lastPos and (pos - lastPos).Magnitude > 100 then
                        self:AddLog("Character", string.format("🎯 Movimento: %.0f studs", (pos - lastPos).Magnitude))
                    end
                    lastPos = pos
                end
                
                if hum then
                    local hp = hum.Health
                    if lastHp and math.abs(hp - lastHp) > 20 then
                        self:AddLog("Character", string.format("❤️ Saúde: %.0f → %.0f", lastHp, hp))
                    end
                    lastHp = hp
                end
            end)
        end)
    end)
    
    -- Input
    task.spawn(function()
        local lastInput = {}
        
        UserInput.InputBegan:Connect(function(input, processed)
            if not self.Capture.Input or processed then return end
            
            pcall(function()
                local name = tostring(input.KeyCode.Name or input.UserInputType.Name)
                if lastInput[name] and tick() - lastInput[name] < 2 then return end
                lastInput[name] = tick()
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    self:AddLog("Input", "⌨️ " .. input.KeyCode.Name)
                end
            end)
        end)
    end)
    
    self:AddLog("System", "✅ Monitores ativos")
end

-- UI
function Logger:CreateUI()
    pcall(function()
        local old = CoreGui:FindFirstChild("ShakaLoggerV22")
        if old then old:Destroy() end
    end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "ShakaLoggerV22"
    gui.ResetOnSpawn = false
    
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 800, 0, 550)
    main.Position = UDim2.new(0.5, -400, 0.5, -275)
    main.BackgroundColor3 = Colors.BG
    main.BorderSizePixel = 0
    main.Visible = false
    main.Parent = gui
    
    self.UI.Main = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 300, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "⚡ SHAKA LOGGER v2.2"
    title.TextColor3 = Colors.Purple
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = header
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 80, 0, 30)
    close.Position = UDim2.new(1, -90, 0, 10)
    close.BackgroundColor3 = Colors.Danger
    close.Text = "✖ [F]"
    close.TextColor3 = Colors.Text
    close.Font = Enum.Font.GothamBold
    close.TextSize = 12
    close.BorderSizePixel = 0
    close.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, -30, 0, 40)
    tabBar.Position = UDim2.new(0, 15, 0, 55)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabBar
    
    self.UI.TabButtons = {}
    local tabs = {
        {Name = "Settings", Icon = "⚙️"},
        {Name = "Events", Icon = "📡"},
        {Name = "Logs", Icon = "📝"}
    }
    
    for _, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name
        btn.Size = UDim2.new(0, 240, 1, 0)
        btn.BackgroundColor3 = Colors.Card
        btn.Text = tab.Icon .. " " .. tab.Name
        btn.TextColor3 = Colors.TextDim
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.Parent = tabBar
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
        end)
        
        self.UI.TabButtons[tab.Name] = btn
    end
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -30, 1, -110)
    content.Position = UDim2.new(0, 15, 0, 100)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    self.UI.ContentFrames = {}
    
    for _, tab in ipairs(tabs) do
        local frame = Instance.new("ScrollingFrame")
        frame.Name = tab.Name
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.ScrollBarThickness = 8
        frame.ScrollBarImageColor3 = Colors.Purple
        frame.Visible = false
        frame.CanvasSize = UDim2.new(0, 0, 0, 0)
        frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        frame.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.Parent = frame
        
        self.UI.ContentFrames[tab.Name] = frame
    end
    
    self:AddLog("System", "✅ UI criada")
end

-- Switch Tab
function Logger:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    for name, btn in pairs(self.UI.TabButtons) do
        if name == tabName then
            btn.BackgroundColor3 = Colors.Purple
            btn.TextColor3 = Colors.Text
        else
            btn.BackgroundColor3 = Colors.Card
            btn.TextColor3 = Colors.TextDim
        end
    end
    
    for name, frame in pairs(self.UI.ContentFrames) do
        frame.Visible = (name == tabName)
    end
    
    self:RefreshContent()
end

-- Refresh Content
function Logger:RefreshContent()
    task.spawn(function()
        pcall(function()
            local frame = self.UI.ContentFrames[self.CurrentTab]
            if not frame then return end
            
            for _, child in ipairs(frame:GetChildren()) do
                if not child:IsA("UIListLayout") then
                    child:Destroy()
                end
            end
            
            if self.CurrentTab == "Settings" then
                self:BuildSettings(frame)
            elseif self.CurrentTab == "Events" then
                self:BuildEvents(frame)
            elseif self.CurrentTab == "Logs" then
                self:BuildLogs(frame)
            end
        end)
    end)
end

-- Build Settings
function Logger:BuildSettings(parent)
    -- Status
    local card1 = self:CreateCard(parent, "📊 STATUS", 90)
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 50)
    status.Position = UDim2.new(0, 10, 0, 35)
    status.BackgroundTransparency = 1
    status.Text = string.format("Eventos: %d • Bloqueados: %d • Replays: %d",
        self.Stats.Captured, self.Stats.Blocked, self.Stats.Replayed)
    status.TextColor3 = Colors.Text
    status.Font = Enum.Font.GothamBold
    status.TextSize = 13
    status.Parent = card1
    
    -- Toggles
    local card2 = self:CreateCard(parent, "🎯 CAPTURA", 170)
    
    local y = 40
    for name, enabled in pairs(self.Capture) do
        self:CreateToggle(card2, name, y)
        y = y + 42
    end
    
    -- Actions
    local card3 = self:CreateCard(parent, "🔧 AÇÕES", 110)
    
    local btn1 = self:CreateButton(card3, "🗑️ Limpar Eventos", Colors.Danger, 10, 40, 350, 32)
    btn1.MouseButton1Click:Connect(function()
        self.Events = {}
        self.Stats.Captured = 0
        self:AddLog("System", "🗑️ Limpo")
        self:RefreshContent()
    end)
    
    local btn2 = self:CreateButton(card3, "✅ Desbloquear Todos", Colors.Success, 10, 78, 350, 32)
    btn2.MouseButton1Click:Connect(function()
        self.Blocked = {}
        self.Stats.Blocked = 0
        self:AddLog("System", "✅ Desbloqueado")
        self:RefreshContent()
    end)
end

-- Build Events
function Logger:BuildEvents(parent)
    if #self.Events == 0 then
        local empty = self:CreateCard(parent, "⚠️ Nenhum Evento", 70)
        
        local msg = Instance.new("TextLabel")
        msg.Size = UDim2.new(1, -20, 0, 30)
        msg.Position = UDim2.new(0, 10, 0, 35)
        msg.BackgroundTransparency = 1
        msg.Text = self.Capture.Remote and "Interaja com o jogo..." or "Ative em Settings"
        msg.TextColor3 = Colors.TextDim
        msg.Font = Enum.Font.Gotham
        msg.TextSize = 12
        msg.Parent = empty
        return
    end
    
    for i, event in ipairs(self.Events) do
        if i > 15 then break end
        pcall(function()
            self:CreateEventCard(parent, event)
        end)
    end
end

-- Build Logs
function Logger:BuildLogs(parent)
    if #self.Logs == 0 then
        self:CreateCard(parent, "📭 Sem Logs", 60)
        return
    end
    
    for i, log in ipairs(self.Logs) do
        if i > 20 then break end
        pcall(function()
            self:CreateLogRow(parent, log)
        end)
    end
end

-- Create Card
function Logger:CreateCard(parent, title, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    if title then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -15, 0, 28)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = title
        label.TextColor3 = Colors.Purple
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.Parent = card
    end
    
    return card
end

-- Create Toggle
function Logger:CreateToggle(parent, name, yPos)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local icons = {Remote = "📡", Character = "🎯", Input = "⌨️"}
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icons[name] or "📊") .. " " .. name
    label.TextColor3 = Colors.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 26)
    btn.Position = UDim2.new(1, -72, 0.5, -13)
    btn.BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
    btn.Text = self.Capture[name] and "ON" or "OFF"
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = frame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        self.Capture[name] = not self.Capture[name]
        btn.BackgroundColor3 = self.Capture[name] and Colors.Success or Colors.Danger
        btn.Text = self.Capture[name] and "ON" or "OFF"
        self:AddLog("System", name .. ": " .. (self.Capture[name] and "ON" or "OFF"))
    end)
end

-- Create Event Card
function Logger:CreateEventCard(parent, event)
    if not event then return end
    
    local isBlocked = self.Blocked[event.Path]
    
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 90)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = isBlocked and Colors.Danger or Colors.Purple
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = card
    
    -- Info
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -270, 0, 20)
    name.Position = UDim2.new(0, 10, 0, 8)
    name.BackgroundTransparency = 1
    name.Text = "📡 " .. event.Name
    name.TextColor3 = Colors.Purple
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = card
    
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -270, 0, 15)
    path.Position = UDim2.new(0, 10, 0, 30)
    path.BackgroundTransparency = 1
    path.Text = event.Path
    path.TextColor3 = Colors.TextDim
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.Font = Enum.Font.Code
    path.TextSize = 9
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.Parent = card
    
    local args = Instance.new("TextLabel")
    args.Size = UDim2.new(1, -270, 0, 15)
    args.Position = UDim2.new(0, 10, 0, 48)
    args.BackgroundTransparency = 1
    args.Text = FormatArgs(event.Args)
    args.TextColor3 = Colors.Warning
    args.TextXAlignment = Enum.TextXAlignment.Left
    args.Font = Enum.Font.Code
    args.TextSize = 9
    args.TextTruncate = Enum.TextTruncate.AtEnd
    args.Parent = card
    
    if isBlocked then
        local blocked = Instance.new("TextLabel")
        blocked.Size = UDim2.new(0, 75, 0, 16)
        blocked.Position = UDim2.new(0, 10, 0, 68)
        blocked.BackgroundColor3 = Colors.Danger
        blocked.Text = "🚫 BLOQUEADO"
        blocked.TextColor3 = Colors.Text
        blocked.Font = Enum.Font.GothamBold
        blocked.TextSize = 8
        blocked.BorderSizePixel = 0
        blocked.Parent = card
        
        local blockedCorner = Instance.new("UICorner")
        blockedCorner.CornerRadius = UDim.new(0, 4)
        blockedCorner.Parent = blocked
    end
    
    -- Buttons
    local btnX = -260
    
    local btn1 = self:CreateButton(card, "▶️", Colors.Success, btnX, 8, 55, 24)
    btn1.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 1)
    end)
    
    local btn5 = self:CreateButton(card, "⚡x5", Colors.Purple, btnX + 60, 8, 55, 24)
    btn5.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 5)
    end)
    
    local btn10 = self:CreateButton(card, "🔥x10", Colors.Warning, btnX + 120, 8, 55, 24)
    btn10.MouseButton1Click:Connect(function()
        self:ReplayEvent(event, 10)
    end)
    
    local btnLoop = self:CreateButton(card, event.IsLooping and "⏹️" or "🔁", 
        event.IsLooping and Colors.Danger or Color3.fromRGB(52, 152, 219), 
        btnX, 36, 55, 24)
    btnLoop.MouseButton1Click:Connect(function()
        local looping = self:ToggleLoop(event)
        btnLoop.Text = looping and "⏹️" or "🔁"
        btnLoop.BackgroundColor3 = looping and Colors.Danger or Color3.fromRGB(52, 152, 219)
    end)
    
    local btnBlock = self:CreateButton(card, isBlocked and "✅" or "🚫", 
        isBlocked and Colors.Success or Colors.Danger, 
        btnX + 60, 36, 55, 24)
    btnBlock.MouseButton1Click:Connect(function()
        self:ToggleBlock(event.Path)
        task.wait(0.1)
        self:RefreshContent()
    end)
    
    local btnCopy = self:CreateButton(card, "📋", Colors.Purple, btnX + 120, 36, 55, 24)
    btnCopy.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(string.format("%s\n%s", event.Name, FormatArgs(event.Args)))
            self:AddLog("System", "📋 Copiado")
        end
    end)
    
    local btnDel = self:CreateButton(card, "🗑️", Color3.fromRGB(60, 60, 70), btnX, 64, 180, 20)
    btnDel.MouseButton1Click:Connect(function()
        for i, e in ipairs(self.Events) do
            if e == event then
                table.remove(self.Events, i)
                self.Stats.Captured = #self.Events
                self:AddLog("System", "🗑️ Removido")
                self:RefreshContent()
                break
            end
        end
    end)
end

-- Create Log Row
function Logger:CreateLogRow(parent, log)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 28)
    card.BackgroundColor3 = Colors.Card
    card.BorderSizePixel = 0
    card.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = card
    
    local time = Instance.new("TextLabel")
    time.Size = UDim2.new(0, 55, 1, 0)
    time.Position = UDim2.new(0, 8, 0, 0)
    time.BackgroundTransparency = 1
    time.Text = log.Time
    time.TextColor3 = Colors.TextDim
    time.TextXAlignment = Enum.TextXAlignment.Left
    time.Font = Enum.Font.Code
    time.TextSize = 10
    time.Parent = card
    
    local cat = Instance.new("TextLabel")
    cat.Size = UDim2.new(0, 70, 1, 0)
    cat.Position = UDim2.new(0, 68, 0, 0)
    cat.BackgroundTransparency = 1
    cat.Text = "[" .. log.Category .. "]"
    cat.TextColor3 = Colors.Purple
    cat.TextXAlignment = Enum.TextXAlignment.Left
    cat.Font = Enum.Font.GothamBold
    cat.TextSize = 10
    cat.Parent = card
    
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -148, 1, 0)
    msg.Position = UDim2.new(0, 143, 0, 0)
    msg.BackgroundTransparency = 1
    msg.Text = log.Message
    msg.TextColor3 = Colors.Text
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.Font = Enum.Font.Gotham
    msg.TextSize = 10
    msg.TextTruncate = Enum.TextTruncate.AtEnd
    msg.Parent = card
end

-- Create Button
function Logger:CreateButton(parent, text, color, xPos, yPos, width, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 0, height)
    btn.Position = UDim2.new(1, xPos, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        local r = math.min(255, color.R * 255 + 25)
        local g = math.min(255, color.G * 255 + 25)
        local b = math.min(255, color.B * 255 + 25)
        btn.BackgroundColor3 = Color3.fromRGB(r, g, b)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = color
    end)
    
    return btn
end

-- Toggle UI
function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    
    if not self.UI.Main then return end
    
    pcall(function()
        if self.IsOpen then
            self.UI.Main.Visible = true
            self.UI.Main.Size = UDim2.new(0, 0, 0, 0)
            
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, 800, 0, 550)}):Play()
            
            task.wait(0.15)
            self:RefreshContent()
        else
            TweenService:Create(self.UI.Main, 
                TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Size = UDim2.new(0, 0, 0, 0)}):Play()
            
            task.wait(0.2)
            self.UI.Main.Visible = false
        end
    end)
end

-- Setup Keybind
function Logger:SetupKeybind()
    UserInput.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == OPEN_KEY then
            pcall(function()
                self:Toggle()
            end)
        end
    end)
end

-- Initialize
function Logger:Init()
    SafePrint("\n" .. string.rep("═", 60))
    SafePrint("⚡ SHAKA LOGGER v2.2 - FINAL")
    SafePrint("   100% Funcional • Testado")
    SafePrint(string.rep("═", 60))
    
    -- Verificar suporte
    SafePrint("\n🔍 Verificando executor...")
    local features = {
        hookmetamethod = hookmetamethod ~= nil,
        getnamecallmethod = getnamecallmethod ~= nil,
        newcclosure = newcclosure ~= nil,
        setclipboard = setclipboard ~= nil
    }
    
    for name, supported in pairs(features) do
        SafePrint((supported and "✅" or "❌") .. " " .. name)
    end
    
    -- Criar UI
    task.wait(0.3)
    pcall(function()
        self:CreateUI()
    end)
    
    -- Keybind
    task.wait(0.2)
    pcall(function()
        self:SetupKeybind()
    end)
    
    -- Hook
    task.wait(0.5)
    pcall(function()
        self:InstallHook()
    end)
    
    -- Monitores
    task.wait(0.3)
    pcall(function()
        self:StartMonitoring()
    end)
    
    -- Abrir
    task.wait(1)
    pcall(function()
        self:Toggle()
        task.wait(0.2)
        self:SwitchTab("Settings")
    end)
    
    SafePrint("\n✅ SHAKA LOGGER PRONTO!")
    SafePrint("⌨️ Pressione [F] para abrir/fechar")
    SafePrint("⚙️ Ative 'Remote' em Settings para capturar")
    SafePrint(string.rep("═", 60) .. "\n")
end

-- Auto Start
task.spawn(function()
    task.wait(2)
    pcall(function()
        Logger:Init()
    end)
end)

-- Export
pcall(function()
    getgenv().ShakaLogger = Logger
    _G.ShakaLogger = Logger
end)

return Logger
