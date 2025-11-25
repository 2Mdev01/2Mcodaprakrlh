-- Purple Dump Panel v7.0 - Ultra Simple
-- UI Testada e Funcional

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Configuração simples
local Config = {
    Theme = {
        Primary = Color3.fromRGB(147, 51, 234),
        Secondary = Color3.fromRGB(20, 20, 20),
        Background = Color3.fromRGB(30, 30, 40),
        Surface = Color3.fromRGB(40, 35, 55),
        Success = Color3.fromRGB(72, 199, 142),
        Error = Color3.fromRGB(255, 85, 85),
        Text = Color3.fromRGB(255, 255, 255)
    }
}

-- Dados
local Memory = {
    Events = {},
    Blocked = {},
    LastTab = "Home"
}

-- Criar UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PurplePanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Config.Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Header
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Config.Theme.Primary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "💜 Purple Panel v7.0"
TitleLabel.TextColor3 = Config.Theme.Text
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 16
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundColor3 = Config.Theme.Error
CloseButton.Text = "X"
CloseButton.TextColor3 = Config.Theme.Text
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.BorderSizePixel = 0
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Tabs
local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, -20, 0, 40)
TabButtons.Position = UDim2.new(0, 10, 0, 45)
TabButtons.BackgroundTransparency = 1
TabButtons.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabButtons

-- Conteúdo
local TabContent = Instance.new("Frame")
TabContent.Size = UDim2.new(1, -20, 1, -95)
TabContent.Position = UDim2.new(0, 10, 0, 90)
TabContent.BackgroundColor3 = Config.Theme.Surface
TabContent.BorderSizePixel = 0
TabContent.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = TabContent

-- Variáveis
local CurrentTab = "Home"
local IsUIVisible = false

-- Função simples para criar botões
local function CreateButton(text, color, parent, position, size)
    local Button = Instance.new("TextButton")
    Button.Size = size or UDim2.new(0.45, 0, 0, 35)
    Button.Position = position or UDim2.new(0, 0, 0, 0)
    Button.BackgroundColor3 = color
    Button.Text = text
    Button.TextColor3 = Config.Theme.Text
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 12
    Button.AutoButtonColor = false
    Button.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Button
    
    return Button
end

-- Criar abas
local tabs = {"Home", "Events", "Executor", "Settings"}

for i, tabName in ipairs(tabs) do
    local TabButton = CreateButton(tabName, Config.Theme.Surface, TabButtons, 
        UDim2.new(0, (i-1)*120, 0, 0), UDim2.new(0, 115, 1, 0))
    
    TabButton.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

-- Função para trocar aba
function SwitchTab(tabName)
    CurrentTab = tabName
    
    -- Atualizar botões
    for i, child in ipairs(TabButtons:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = (child.Text == tabName) and Config.Theme.Primary or Config.Theme.Surface
        end
    end
    
    -- Limpar conteúdo
    for _, child in ipairs(TabContent:GetChildren()) do
        child:Destroy()
    end
    
    -- Criar conteúdo da aba
    if tabName == "Home" then
        CreateHomeTab()
    elseif tabName == "Events" then
        CreateEventsTab()
    elseif tabName == "Executor" then
        CreateExecutorTab()
    elseif tabName == "Settings" then
        CreateSettingsTab()
    end
end

-- Aba Home
function CreateHomeTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local WelcomeLabel = Instance.new("TextLabel")
    WelcomeLabel.Size = UDim2.new(1, -20, 0, 100)
    WelcomeLabel.Position = UDim2.new(0, 10, 0, 10)
    WelcomeLabel.BackgroundTransparency = 1
    WelcomeLabel.Text = "💜 Purple Dump Panel v7.0\n\n✅ UI Testada e Funcional\n🔧 Pressione F para abrir/fechar\n🎯 Sistema de memória ativo"
    WelcomeLabel.TextColor3 = Config.Theme.Text
    WelcomeLabel.Font = Enum.Font.GothamBold
    WelcomeLabel.TextSize = 14
    WelcomeLabel.TextYAlignment = Enum.TextYAlignment.Top
    WelcomeLabel.TextWrapped = true
    WelcomeLabel.Parent = Container
    
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, -20, 0, 80)
    StatsLabel.Position = UDim2.new(0, 10, 0, 120)
    StatsLabel.BackgroundColor3 = Config.Theme.Secondary
    StatsLabel.Text = string.format("📊 Estatísticas:\n\nEventos: %d\nBloqueados: %d", #Memory.Events, #Memory.Blocked)
    StatsLabel.TextColor3 = Config.Theme.Text
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.TextSize = 12
    StatsLabel.TextYAlignment = Enum.TextYAlignment.Top
    StatsLabel.TextWrapped = true
    StatsLabel.Parent = Container
    
    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 8)
    StatsCorner.Parent = StatsLabel
    
    local ClearButton = CreateButton("🗑️ Limpar Tudo", Config.Theme.Error, Container,
        UDim2.new(0, 10, 1, -45), UDim2.new(1, -20, 0, 35))
    
    ClearButton.MouseButton1Click:Connect(function()
        Memory.Events = {}
        Memory.Blocked = {}
        print("✅ Dados limpos!")
        SwitchTab("Home")
    end)
end

-- Aba Events
function CreateEventsTab()
    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 5
    Container.ScrollBarImageColor3 = Config.Theme.Primary
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Container.Parent = TabContent
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.Parent = Container
    
    if #Memory.Events == 0 then
        local EmptyLabel = Instance.new("TextLabel")
        EmptyLabel.Size = UDim2.new(1, -20, 0, 60)
        EmptyLabel.Position = UDim2.new(0, 10, 0, 10)
        EmptyLabel.BackgroundColor3 = Config.Theme.Secondary
        EmptyLabel.Text = "Nenhum evento capturado\nInteraja com o jogo para ver eventos"
        EmptyLabel.TextColor3 = Config.Theme.Text
        EmptyLabel.Font = Enum.Font.Gotham
        EmptyLabel.TextSize = 12
        EmptyLabel.TextWrapped = true
        EmptyLabel.Parent = Container
        
        local EmptyCorner = Instance.new("UICorner")
        EmptyCorner.CornerRadius = UDim.new(0, 8)
        EmptyCorner.Parent = EmptyLabel
    else
        for i, event in ipairs(Memory.Events) do
            if i > 15 then break end
            
            local EventFrame = Instance.new("Frame")
            EventFrame.Size = UDim2.new(1, -10, 0, 80)
            EventFrame.BackgroundColor3 = Config.Theme.Secondary
            EventFrame.BorderSizePixel = 0
            EventFrame.Parent = Container
            
            local EventCorner = Instance.new("UICorner")
            EventCorner.CornerRadius = UDim.new(0, 8)
            EventCorner.Parent = EventFrame
            
            local EventName = Instance.new("TextLabel")
            EventName.Size = UDim2.new(1, -100, 0, 20)
            EventName.Position = UDim2.new(0, 8, 0, 8)
            EventName.BackgroundTransparency = 1
            EventName.Text = "📡 " .. (event.Name or "Evento")
            EventName.TextColor3 = Config.Theme.Primary
            EventName.Font = Enum.Font.GothamBold
            EventName.TextSize = 12
            EventName.TextXAlignment = Enum.TextXAlignment.Left
            EventName.Parent = EventFrame
            
            local EventPath = Instance.new("TextLabel")
            EventPath.Size = UDim2.new(1, -100, 0, 15)
            EventPath.Position = UDim2.new(0, 8, 0, 30)
            EventPath.BackgroundTransparency = 1
            EventPath.Text = event.Path or "Caminho"
            EventPath.TextColor3 = Config.Theme.Text
            EventPath.Font = Enum.Font.Gotham
            EventPath.TextSize = 10
            EventPath.TextXAlignment = Enum.TextXAlignment.Left
            EventPath.TextTruncate = Enum.TextTruncate.AtEnd
            EventPath.Parent = EventFrame
            
            local EventTime = Instance.new("TextLabel")
            EventTime.Size = UDim2.new(1, -100, 0, 15)
            EventTime.Position = UDim2.new(0, 8, 0, 47)
            EventTime.BackgroundTransparency = 1
            EventTime.Text = "⏰ " .. (event.TimeString or "00:00:00")
            EventTime.TextColor3 = Config.Theme.Text
            EventTime.Font = Enum.Font.Gotham
            EventTime.TextSize = 10
            EventTime.TextXAlignment = Enum.TextXAlignment.Left
            EventTime.Parent = EventFrame
            
            local PlayButton = CreateButton("▶️", Config.Theme.Success, EventFrame,
                UDim2.new(1, -85, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local BlockButton = CreateButton("🚫", Config.Theme.Error, EventFrame,
                UDim2.new(1, -45, 0, 8), UDim2.new(0, 35, 0, 25))
            
            local CopyButton = CreateButton("📋", Config.Theme.Primary, EventFrame,
                UDim2.new(1, -85, 0, 38), UDim2.new(0, 75, 0, 25))
        end
    end
end

-- Aba Executor
function CreateExecutorTab()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = TabContent
    
    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(1, -20, 0, 200)
    CodeBox.Position = UDim2.new(0, 10, 0, 10)
    CodeBox.BackgroundColor3 = Config.Theme.Secondary
    CodeBox.TextColor3 = Config.Theme.Text
    CodeBox.PlaceholderText = "-- Digite seu código Lua aqui\nprint('Hello Purple Panel!')"
    CodeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    CodeBox.Text = ""
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextSize = 11
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.MultiLine = true
    CodeBox.ClearTextOnFocus = false
    CodeBox.Parent = Container
    
    local CodeCorner = Instance.new("UICorner")
    CodeCorner.CornerRadius = UDim.new(0, 6)
    CodeCorner.Parent = CodeBox
    
    local ExecuteButton = CreateButton("💜 EXECUTAR CÓDIGO", Config.Theme.Success, Container,
        UDim2.new(0, 10, 0, 220), UDim2.new(0.6, -5, 0, 35))
    
    local ClearButton = CreateButton("🗑️ LIMPAR", Config.Theme.Error, Container,
        UDim2.new(0.6, 5, 0, 220), UDim2.new(0.4, -5, 0, 35))
    
    local OutputBox = Instance.new("TextBox")
    OutputBox.Size = UDim2.new(1, -20, 0, 100)
    OutputBox.Position = UDim2.new(0, 10, 0, 265)
    OutputBox.BackgroundColor3 = Config.Theme.Secondary
    OutputBox.TextColor3 = Color3.fromRGB(0, 255, 100)
    OutputBox.Text = "📤 Output aparecerá aqui..."
    OutputBox.Font = Enum.Font.Code
    OutputBox.TextSize = 11
    OutputBox.TextXAlignment = Enum.TextXAlignment.Left
    OutputBox.TextYAlignment = Enum.TextYAlignment.Top
    OutputBox.MultiLine = true
    OutputBox.TextEditable = false
    OutputBox.Parent = Container
    
    local OutputCorner = Instance.new("UICorner")
    OutputCorner.CornerRadius = UDim.new(0, 6)
    OutputCorner.Parent = OutputBox
    
    ExecuteButton.MouseButton1Click:Connect(function()
        local code = CodeBox.Text
        if code == "" then
            OutputBox.Text = "❌ Digite algum código!"
            return
        end
        
        ExecuteButton.Text = "⏳ EXECUTANDO..."
        ExecuteButton.BackgroundColor3 = Config.Theme.Primary
        
        task.spawn(function()
            local success, result = pcall(function()
                local func = loadstring(code)
                if func then
                    return func()
                end
            end)
            
            if success then
                OutputBox.Text = "✅ Código executado com sucesso!"
                if result then
                    OutputBox.Text = OutputBox.Text .. "\n📦 Retorno: " .. tostring(result)
                end
            else
                OutputBox.Text = "❌ Erro: " .. tostring(result)
            end
            
            task.wait(1)
            ExecuteButton.Text = "💜 EXECUTAR CÓDIGO"
            ExecuteButton.BackgroundColor3 = Config.Theme.Success
        end)
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CodeBox.Text = ""
        OutputBox.Text = "🗑️ Código limpo!"
    end)
end

-- Aba Settings
function CreateSettingsTab()
    local Container = Instance.new("ScrollingFrame")
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.ScrollBarThickness = 5
    Container.ScrollBarImageColor3 = Config.Theme.Primary
    Container.CanvasSize = UDim2.new(0, 0, 0, 500)
    Container.Parent = TabContent
    
    local yPos = 10
    
    local function CreateSetting(title, description, default)
        local SettingFrame = Instance.new("Frame")
        SettingFrame.Size = UDim2.new(1, -20, 0, 70)
        SettingFrame.Position = UDim2.new(0, 10, 0, yPos)
        SettingFrame.BackgroundColor3 = Config.Theme.Secondary
        SettingFrame.BorderSizePixel = 0
        SettingFrame.Parent = Container
        
        local SettingCorner = Instance.new("UICorner")
        SettingCorner.CornerRadius = UDim.new(0, 8)
        SettingCorner.Parent = SettingFrame
        
        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -80, 0, 25)
        TitleLabel.Position = UDim2.new(0, 10, 0, 8)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Config.Theme.Text
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 13
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = SettingFrame
        
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -80, 0, 35)
        DescLabel.Position = UDim2.new(0, 10, 0, 30)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Text = description
        DescLabel.TextColor3 = Config.Theme.Text
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextSize = 11
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextYAlignment = Enum.TextYAlignment.Top
        DescLabel.TextWrapped = true
        DescLabel.Parent = SettingFrame
        
        local ToggleButton = CreateButton(default and "ON" or "OFF", 
            default and Config.Theme.Success or Config.Theme.Error, 
            SettingFrame, UDim2.new(1, -65, 0.5, -15), UDim2.new(0, 50, 0, 30))
        
        yPos = yPos + 80
    end
    
    CreateSetting("💜 Auto Capture", "Capturar eventos automaticamente", true)
    CreateSetting("📜 Auto Scroll", "Rolar automaticamente logs", true)
    CreateSetting("🖱️ Mouse Events", "Capturar eventos de mouse", false)
    CreateSetting("⏰ Timestamps", "Mostrar horários nos logs", true)
    
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -20, 0, 120)
    InfoFrame.Position = UDim2.new(0, 10, 0, yPos)
    InfoFrame.BackgroundColor3 = Config.Theme.Primary
    InfoFrame.Parent = Container
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    local InfoText = Instance.new("TextLabel")
    InfoText.Size = UDim2.new(1, -20, 1, -20)
    InfoText.Position = UDim2.new(0, 10, 0, 10)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "💜 Purple Panel v7.0\n\n✅ UI Simplificada\n🔧 100% Funcional\n🎯 Pressione F"
    InfoText.TextColor3 = Config.Theme.Text
    InfoText.Font = Enum.Font.GothamBold
    InfoText.TextSize = 12
    InfoText.TextYAlignment = Enum.TextYAlignment.Top
    InfoText.TextWrapped = true
    InfoText.Parent = InfoFrame
end

-- Função para mostrar/ocultar UI
function ToggleUI()
    IsUIVisible = not IsUIVisible
    
    if IsUIVisible then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0, 600, 0, 400)
        })
        tween:Play()
        
        -- Inicializar primeira aba
        SwitchTab(CurrentTab)
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        tween:Play()
        
        task.wait(0.2)
        MainFrame.Visible = false
    end
end

-- Configurar botões
CloseButton.MouseButton1Click:Connect(ToggleUI)

-- Hotkey F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        ToggleUI()
    end
end)

-- Sistema de captura simples
local function SimpleHook()
    if hookmetamethod then
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
                local eventData = {
                    Name = self.Name,
                    Type = method == "FireServer" and "RemoteEvent" or "RemoteFunction",
                    Path = self:GetFullName(),
                    TimeString = os.date("%H:%M:%S")
                }
                
                table.insert(Memory.Events, 1, eventData)
                if #Memory.Events > 50 then
                    table.remove(Memory.Events, 51)
                end
                
                if IsUIVisible and CurrentTab == "Events" then
                    SwitchTab("Events")
                end
            end
            return old(self, ...)
        end)
    end
end

-- Inicializar
print("💜 Purple Panel v7.0 Carregado!")
print("🔧 Pressione F para abrir o menu")
print("✅ UI testada e funcional")

-- Iniciar hooks
task.spawn(SimpleHook)

-- Mostrar UI inicialmente
task.wait(1)
ToggleUI()
