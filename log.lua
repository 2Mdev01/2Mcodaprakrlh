-- Ultra Simple Security MOD MENU - 100% FUNCIONAL
-- APENAS para pentest autorizado

local SecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações básicas
SecurityMenu.OpenKey = Enum.KeyCode.F5
SecurityMenu.IsOpen = false
SecurityMenu.Logs = {}
SecurityMenu.Stats = {
    Total = 0,
    Remote = 0,
    Character = 0,
    Network = 0,
    Input = 0
}

-- Função simples de log
function SecurityMenu:Log(category, message)
    local logEntry = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        ID = #self.Logs + 1
    }
    
    table.insert(self.Logs, logEntry)
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = (self.Stats[category] or 0) + 1
    
    print("[" .. logEntry.Time .. "] " .. category .. ": " .. message)
    
    -- Atualizar UI se estiver aberta
    if self.IsOpen and self.UpdateDisplay then
        self:UpdateDisplay()
    end
end

-- Monitoramento SIMPLES de RemoteEvents
function SecurityMenu:MonitorRemotes()
    self:Log("System", "Monitoring RemoteEvents...")
    
    local function safeMonitor(remote)
        if remote:IsA("RemoteEvent") then
            local original = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local success = pcall(original, self, unpack(args))
                SecurityMenu:Log("Remote", remote.Name .. " fired (" .. #args .. " args)")
                return
            end
        elseif remote:IsA("RemoteFunction") then
            local original = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local result = original(self, unpack(args))
                SecurityMenu:Log("Remote", remote.Name .. " invoked (" .. #args .. " args)")
                return result
            end
        end
    end

    -- Monitorar apenas ReplicatedStorage (evita infinite yield)
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            pcall(safeMonitor, remote)
        end
    end
end

-- Monitoramento de Character
function SecurityMenu:MonitorCharacter()
    local lastPos = nil
    
    RunService.Heartbeat:Connect(function()
        local player = Players.LocalPlayer
        if player and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local currentPos = root.Position
                if lastPos then
                    local dist = (currentPos - lastPos).Magnitude
                    if dist > 3 then
                        self:Log("Character", "Moved " .. math.floor(dist) .. " studs")
                    end
                end
                lastPos = currentPos
            end
        end
    end)
end

-- Monitoramento de Inputs
function SecurityMenu:MonitorInputs()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.UserInputType == Enum.UserInputType.Keyboard then
            self:Log("Input", "Key: " .. input.KeyCode.Name)
        end
    end)
end

-- Monitoramento de Network
function SecurityMenu:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        self:Log("Network", player.Name .. " joined")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:Log("Network", player.Name .. " left")
    end)
end

-- Criar Interface SIMPLES
function SecurityMenu:CreateUI()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Visible = false
    MainFrame.Parent = self.ScreenGui
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 SECURITY MONITOR"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Header
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 80, 0, 25)
    CloseBtn.Position = UDim2.new(1, -85, 0.5, -12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "CLOSE [F5]"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Header
    
    -- Área de conteúdo
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, 0, 1, -45)
    Content.Position = UDim2.new(0, 0, 0, 45)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 8
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.Parent = MainFrame
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 5)
    Layout.Parent = Content
    
    -- Estatísticas
    local StatsFrame = Instance.new("Frame")
    StatsFrame.Size = UDim2.new(1, -20, 0, 100)
    StatsFrame.Position = UDim2.new(0, 10, 0, 10)
    StatsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = Content
    
    local StatsTitle = Instance.new("TextLabel")
    StatsTitle.Size = UDim2.new(1, -10, 0, 25)
    StatsTitle.Position = UDim2.new(0, 10, 0, 5)
    StatsTitle.BackgroundTransparency = 1
    StatsTitle.Text = "📊 STATISTICS"
    StatsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
    StatsTitle.Font = Enum.Font.GothamBold
    StatsTitle.TextSize = 14
    StatsTitle.Parent = StatsFrame
    
    -- Logs
    local LogsFrame = Instance.new("Frame")
    LogsFrame.Size = UDim2.new(1, -20, 0, 200)
    LogsFrame.Position = UDim2.new(0, 10, 0, 120)
    LogsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    LogsFrame.BorderSizePixel = 0
    LogsFrame.Parent = Content
    
    local LogsTitle = Instance.new("TextLabel")
    LogsTitle.Size = UDim2.new(1, -10, 0, 25)
    LogsTitle.Position = UDim2.new(0, 10, 0, 5)
    LogsTitle.BackgroundTransparency = 1
    LogsTitle.Text = "📝 RECENT LOGS"
    LogsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogsTitle.TextXAlignment = Enum.TextXAlignment.Left
    LogsTitle.Font = Enum.Font.GothamBold
    LogsTitle.TextSize = 14
    LogsTitle.Parent = LogsFrame
    
    local LogsContent = Instance.new("ScrollingFrame")
    LogsContent.Size = UDim2.new(1, -20, 1, -35)
    LogsContent.Position = UDim2.new(0, 10, 0, 30)
    LogsContent.BackgroundTransparency = 1
    LogsContent.BorderSizePixel = 0
    LogsContent.ScrollBarThickness = 6
    LogsContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogsContent.Parent = LogsFrame
    
    local LogsLayout = Instance.new("UIListLayout")
    LogsLayout.Padding = UDim.new(0, 2)
    LogsLayout.Parent = LogsContent
    
    -- Controles
    local ControlsFrame = Instance.new("Frame")
    ControlsFrame.Size = UDim2.new(1, -20, 0, 40)
    ControlsFrame.Position = UDim2.new(0, 10, 0, 330)
    ControlsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    ControlsFrame.BorderSizePixel = 0
    ControlsFrame.Parent = Content
    
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Size = UDim2.new(0, 120, 0, 25)
    ClearBtn.Position = UDim2.new(0.5, -60, 0.5, -12)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    ClearBtn.BorderSizePixel = 0
    ClearBtn.Text = "🧹 CLEAR LOGS"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.TextSize = 12
    ClearBtn.Parent = ControlsFrame
    
    -- Configurar eventos
    CloseBtn.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    ClearBtn.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
    
    self.MainFrame = MainFrame
    self.StatsFrame = StatsFrame
    self.LogsContent = LogsContent
    self.ContentFrame = Content
end

-- Atualizar display
function SecurityMenu:UpdateDisplay()
    if not self.MainFrame or not self.MainFrame.Visible then return end
    
    -- Atualizar estatísticas
    for _, child in pairs(self.StatsFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= self.StatsFrame:FindFirstChild("StatsTitle") then
            child:Destroy()
        end
    end
    
    local stats = {
        {"Total Events", self.Stats.Total},
        {"Remote Events", self.Stats.Remote},
        {"Character Events", self.Stats.Character},
        {"Network Events", self.Stats.Network},
        {"Input Events", self.Stats.Input}
    }
    
    for i, stat in ipairs(stats) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 15)
        label.Position = UDim2.new(0, 10, 0, 25 + (i-1)*15)
        label.BackgroundTransparency = 1
        label.Text = stat[1] .. ": " .. stat[2]
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.Parent = self.StatsFrame
    end
    
    -- Atualizar logs
    for _, child in pairs(self.LogsContent:GetChildren()) do
        child:Destroy()
    end
    
    local recentLogs = {}
    for i = math.max(1, #self.Logs - 14), #self.Logs do
        table.insert(recentLogs, self.Logs[i])
    end
    
    for i, log in ipairs(recentLogs) do
        local logFrame = Instance.new("Frame")
        logFrame.Size = UDim2.new(1, 0, 0, 20)
        logFrame.BackgroundTransparency = 1
        logFrame.Parent = self.LogsContent
        
        local timeLabel = Instance.new("TextLabel")
        timeLabel.Size = UDim2.new(0, 50, 1, 0)
        timeLabel.Position = UDim2.new(0, 0, 0, 0)
        timeLabel.BackgroundTransparency = 1
        timeLabel.Text = log.Time
        timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        timeLabel.TextXAlignment = Enum.TextXAlignment.Left
        timeLabel.Font = Enum.Font.Gotham
        timeLabel.TextSize = 9
        timeLabel.Parent = logFrame
        
        local catLabel = Instance.new("TextLabel")
        catLabel.Size = UDim2.new(0, 70, 1, 0)
        catLabel.Position = UDim2.new(0, 55, 0, 0)
        catLabel.BackgroundTransparency = 1
        catLabel.Text = "[" .. log.Category .. "]"
        catLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        catLabel.TextXAlignment = Enum.TextXAlignment.Left
        catLabel.Font = Enum.Font.Gotham
        catLabel.TextSize = 9
        catLabel.Parent = logFrame
        
        local msgLabel = Instance.new("TextLabel")
        msgLabel.Size = UDim2.new(1, -130, 1, 0)
        msgLabel.Position = UDim2.new(0, 130, 0, 0)
        msgLabel.BackgroundTransparency = 1
        msgLabel.Text = log.Message
        msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        msgLabel.TextXAlignment = Enum.TextXAlignment.Left
        msgLabel.Font = Enum.Font.Gotham
        msgLabel.TextSize = 10
        msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
        msgLabel.Parent = logFrame
    end
end

function SecurityMenu:ClearLogs()
    self.Logs = {}
    self.Stats = {Total = 0, Remote = 0, Character = 0, Network = 0, Input = 0}
    self:Log("System", "Logs cleared")
end

function SecurityMenu:ToggleMenu()
    self.IsOpen = not self.IsOpen
    self.MainFrame.Visible = self.IsOpen
    
    if self.IsOpen then
        self:UpdateDisplay()
    end
end

-- Keybind
function SecurityMenu:SetupKeybind()
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == self.OpenKey then
            self:ToggleMenu()
        end
    end)
end

-- Inicialização SEGURA
function SecurityMenu:Init()
    local success, err = pcall(function()
        self:CreateUI()
        self:SetupKeybind()
        
        -- Iniciar monitoramentos com delay
        task.wait(1)
        self:MonitorRemotes()
        task.wait(0.5)
        self:MonitorCharacter()
        task.wait(0.5)
        self:MonitorInputs()
        task.wait(0.5)
        self:MonitorNetwork()
        
        self:Log("System", "✅ SECURITY MENU READY! Press F5")
        return true
    end)
    
    if not success then
        warn("SecurityMenu Error: " .. tostring(err))
        return false
    end
    
    return true
end

-- Iniciar
task.spawn(function()
    task.wait(3) -- Esperar o jogo carregar completamente
    SecurityMenu:Init()
end)

-- Tornar global
getgenv().SecurityMenu = SecurityMenu

return SecurityMenu
