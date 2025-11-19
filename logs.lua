-- ULTIMATE SECURITY MENU - DELTA EXECUTOR COMPATIBLE
-- APENAS para pentest autorizado

local SecurityMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configurações básicas
SecurityMenu.OpenKey = Enum.KeyCode.RightShift
SecurityMenu.IsOpen = false
SecurityMenu.CurrentTab = "Dashboard"

-- Sistema de logs organizado
SecurityMenu.Logs = {
    All = {},
    Remote = {},
    Character = {},
    Network = {},
    Input = {},
    Triggers = {}
}

SecurityMenu.Stats = {
    Total = 0,
    Remote = 0,
    Character = 0, 
    Network = 0,
    Input = 0,
    Triggers = 0
}

SecurityMenu.TriggersList = {}

-- Função de logging SEGURA
function SecurityMenu:Log(category, message)
    local logEntry = {
        Time = os.date("%H:%M:%S"),
        Category = category,
        Message = message,
        ID = #self.Logs.All + 1
    }
    
    -- Adicionar aos logs
    table.insert(self.Logs.All, logEntry)
    table.insert(self.Logs[category], logEntry)
    
    -- Atualizar estatísticas
    self.Stats.Total = self.Stats.Total + 1
    self.Stats[category] = self.Stats[category] + 1
    
    -- Print no console
    print("[" .. logEntry.Time .. "] " .. category .. ": " .. message)
    
    -- Atualizar UI se estiver aberta
    if self.IsOpen then
        self:UpdateDisplay()
    end
end

-- Sistema de Triggers SIMPLES
function SecurityMenu:AddTrigger(name, condition, action)
    self.TriggersList[name] = {
        Condition = condition,
        Action = action
    }
    self:Log("System", "Trigger adicionado: " .. name)
end

function SecurityMenu:CheckTriggers(category, message)
    for triggerName, trigger in pairs(self.TriggersList) do
        local success, result = pcall(trigger.Condition, category, message)
        if success and result then
            pcall(trigger.Action, message)
            self:Log("Triggers", "🚨 " .. triggerName .. " acionado!")
        end
    end
end

-- Monitoramento SEGURO de RemoteEvents
function SecurityMenu:MonitorRemoteEvents()
    self:Log("System", "Iniciando monitoramento de RemoteEvents...")
    
    local function safeMonitor(remote)
        if remote:IsA("RemoteEvent") then
            local original = remote.FireServer
            remote.FireServer = function(self, ...)
                local args = {...}
                local success = pcall(original, self, unpack(args))
                SecurityMenu:Log("Remote", remote.Name .. " fired")
                SecurityMenu:CheckTriggers("Remote", remote.Name .. " fired")
                return
            end
        elseif remote:IsA("RemoteFunction") then
            local original = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                local args = {...}
                local result = original(self, unpack(args))
                SecurityMenu:Log("Remote", remote.Name .. " invoked") 
                SecurityMenu:CheckTriggers("Remote", remote.Name .. " invoked")
                return result
            end
        end
    end

    -- Monitorar apenas ReplicatedStorage (EVITA ERROS)
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            pcall(safeMonitor, remote)
        end
    end
    
    self:Log("System", "RemoteEvents monitorados com sucesso!")
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
                        SecurityMenu:Log("Character", "Movimento: " .. math.floor(dist) .. " studs")
                        SecurityMenu:CheckTriggers("Character", "Movimento rápido: " .. math.floor(dist))
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
            SecurityMenu:Log("Input", "Tecla: " .. input.KeyCode.Name)
            SecurityMenu:CheckTriggers("Input", "Tecla: " .. input.KeyCode.Name)
        end
    end)
end

-- Monitoramento de Network  
function SecurityMenu:MonitorNetwork()
    Players.PlayerAdded:Connect(function(player)
        SecurityMenu:Log("Network", player.Name .. " entrou no jogo")
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        SecurityMenu:Log("Network", player.Name .. " saiu do jogo")
    end)
end

-- Criar Interface SIMPLES E FUNCIONAL
function SecurityMenu:CreateUI()
    -- Destruir UI existente
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    
    -- Criar nova UI
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Frame principal
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 600, 0, 450)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
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
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔒 SECURITY MENU"
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
    CloseBtn.Text = "FECHAR"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 12
    CloseBtn.Parent = Header
    
    -- Tabs
    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(1, 0, 0, 30)
    TabContainer.Position = UDim2.new(0, 0, 0, 40)
    TabContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    
    local Tabs = {"Dashboard", "Remote", "Character", "Network", "Input", "Triggers"}
    self.TabButtons = {}
    
    for i, tabName in ipairs(Tabs) do
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(0, 100, 1, 0)
        TabButton.Position = UDim2.new(0, (i-1)*100, 0, 0)
        TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        TabButton.BorderSizePixel = 0
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(180, 180, 180)
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextSize = 11
        TabButton.Parent = TabContainer
        
        TabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tabName)
        end)
        
        self.TabButtons[tabName] = TabButton
    end
    
    -- Área de conteúdo
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, 0, 1, -70)
    ContentFrame.Position = UDim2.new(0, 0, 0, 70)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Criar frames para cada tab
    self.ContentFrames = {}
    
    for _, tabName in ipairs(Tabs) do
        local Frame = Instance.new("ScrollingFrame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.Position = UDim2.new(0, 0, 0, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.ScrollBarThickness = 6
        Frame.Visible = false
        Frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Frame.Parent = ContentFrame
        
        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 5)
        Layout.Parent = Frame
        
        self.ContentFrames[tabName] = Frame
    end
    
    -- Configurar eventos
    CloseBtn.MouseButton1Click:Connect(function()
        self:ToggleMenu()
    end)
    
    self.MainFrame = MainFrame
    
    -- Selecionar tab inicial
    self:SwitchTab("Dashboard")
end

-- Sistema de Abas
function SecurityMenu:SwitchTab(tabName)
    self.CurrentTab = tabName
    
    -- Esconder todas as tabs
    for name, frame in pairs(self.ContentFrames) do
        frame.Visible = false
        -- Limpar conteúdo
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end
    
    -- Atualizar botões
    for name, button in pairs(self.TabButtons) do
        if name == tabName then
            button.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            button.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    
    -- Mostrar tab atual
    self.ContentFrames[tabName].Visible = true
    self:UpdateTabContent(tabName)
end

function SecurityMenu:UpdateTabContent(tabName)
    local frame = self.ContentFrames[tabName]
    if not frame then return end
    
    if tabName == "Dashboard" then
        self:CreateDashboard(frame)
    elseif tabName == "Remote" then
        self:CreateRemoteTab(frame)
    elseif tabName == "Character" then
        self:CreateCharacterTab(frame)
    elseif tabName == "Network" then
        self:CreateNetworkTab(frame)
    elseif tabName == "Input" then
        self:CreateInputTab(frame)
    elseif tabName == "Triggers" then
        self:CreateTriggersTab(frame)
    end
end

-- Conteúdo das Abas
function SecurityMenu:CreateDashboard(frame)
    -- Estatísticas
    local statsFrame = self:CreateSection(frame, "📊 ESTATÍSTICAS", 10)
    
    local stats = {
        {"Total Events", self.Stats.Total},
        {"Remote Events", self.Stats.Remote},
        {"Character Events", self.Stats.Character},
        {"Network Events", self.Stats.Network},
        {"Input Events", self.Stats.Input},
        {"Triggers", self.Stats.Triggers}
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatRow(statsFrame, stat[1], stat[2], i)
    end
    
    -- Controles
    local controlsFrame = self:CreateSection(frame, "🛠️ CONTROLES", 160)
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 140, 0, 30)
    clearBtn.Position = UDim2.new(0, 20, 0, 30)
    clearBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🧹 LIMPAR LOGS"
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.TextSize = 12
    clearBtn.Parent = controlsFrame
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
end

function SecurityMenu:CreateRemoteTab(frame)
    local section = self:CreateSection(frame, "📡 REMOTE EVENTS", 10)
    self:DisplayLogs(section, self.Logs.Remote, 15)
end

function SecurityMenu:CreateCharacterTab(frame)
    local section = self:CreateSection(frame, "🎯 CHARACTER", 10)
    self:DisplayLogs(section, self.Logs.Character, 15)
end

function SecurityMenu:CreateNetworkTab(frame)
    local section = self:CreateSection(frame, "🌐 NETWORK", 10)
    self:DisplayLogs(section, self.Logs.Network, 15)
end

function SecurityMenu:CreateInputTab(frame)
    local section = self:CreateSection(frame, "⌨️ INPUTS", 10)
    self:DisplayLogs(section, self.Logs.Input, 15)
end

function SecurityMenu:CreateTriggersTab(frame)
    local section = self:CreateSection(frame, "🚨 TRIGGERS", 10)
    self:DisplayLogs(section, self.Logs.Triggers, 15)
end

-- Funções auxiliares de UI
function SecurityMenu:CreateSection(parent, title, yPos)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, -20, 0, 0)
    section.Position = UDim2.new(0, 10, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    section.BorderSizePixel = 0
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = section
    
    if title then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -10, 0, 25)
        titleLabel.Position = UDim2.new(0, 10, 0, 5)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 14
        titleLabel.Parent = section
    end
    
    return section
end

function SecurityMenu:CreateStatRow(parent, label, value, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 20)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*25)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, 0, 1, 0)
    labelText.Position = UDim2.new(0, 0, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(200, 200, 200)
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Font = Enum.Font.Gotham
    labelText.TextSize = 12
    labelText.Parent = row
    
    local valueText = Instance.new("TextLabel")
    valueText.Size = UDim2.new(0.3, 0, 1, 0)
    valueText.Position = UDim2.new(0.7, 0, 0, 0)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(value)
    valueText.TextColor3 = Color3.fromRGB(76, 175, 80)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Font = Enum.Font.GothamBold
    valueText.TextSize = 12
    valueText.Parent = row
end

function SecurityMenu:DisplayLogs(section, logs, maxLogs)
    local recentLogs = {}
    for i = math.max(1, #logs - maxLogs + 1), #logs do
        table.insert(recentLogs, logs[i])
    end
    
    for i, log in ipairs(recentLogs) do
        self:CreateLogRow(section, log, i)
    end
end

function SecurityMenu:CreateLogRow(parent, log, index)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -20, 0, 25)
    row.Position = UDim2.new(0, 10, 0, 30 + (index-1)*30)
    row.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    row.BorderSizePixel = 0
    row.Parent = parent
    
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(0, 50, 1, 0)
    timeLabel.Position = UDim2.new(0, 5, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = log.Time
    timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.Parent = row
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -60, 1, 0)
    msgLabel.Position = UDim2.new(0, 60, 0, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = log.Message
    msgLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 10
    msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
    msgLabel.Parent = row
end

function SecurityMenu:UpdateDisplay()
    self:UpdateTabContent(self.CurrentTab)
end

function SecurityMenu:ClearLogs()
    for category, _ in pairs(self.Logs) do
        self.Logs[category] = {}
    end
    
    for stat, _ in pairs(self.Stats) do
        self.Stats[stat] = 0
    end
    
    self:Log("System", "Logs limpos!")
    self:UpdateDisplay()
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

-- Triggers de Exemplo
function SecurityMenu:SetupTriggers()
    -- Trigger para movimento rápido
    self:AddTrigger("MovimentoRapido",
        function(category, message)
            return category == "Character" and message:find("Movimento:") and tonumber(message:match("%d+")) > 20
        end,
        function(message)
            -- Ação quando trigger é acionado
        end
    )
    
    -- Trigger para muitos RemoteEvents
    self:AddTrigger("MuitosRemotes",
        function(category, message)
            return category == "Remote" and self.Stats.Remote > 10
        end,
        function(message)
            -- Ação quando trigger é acionado
        end
    )
end

-- Inicialização SEGURA
function SecurityMenu:Init()
    local success, err = pcall(function()
        self:CreateUI()
        self:SetupKeybind()
        self:SetupTriggers()
        
        -- Iniciar monitoramentos
        self:MonitorRemoteEvents()
        self:MonitorCharacter()
        self:MonitorInputs()
        self:MonitorNetwork()
        
        self:Log("System", "✅ SECURITY MENU PRONTO! Pressione RightShift")
        return true
    end)
    
    if not success then
        warn("SecurityMenu Error: " .. tostring(err))
        return false
    end
    
    return true
end

-- INICIAR AUTOMATICAMENTE
task.spawn(function()
    task.wait(2) -- Esperar o jogo carregar
    SecurityMenu:Init()
end)

-- Tornar global para acesso
getgenv().SecurityMenu = SecurityMenu

return SecurityMenu
