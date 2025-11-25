--[[
    Painel de Dump e Monitoramento para Roblox
    Funcionalidades: Dump de scripts, logs de eventos, bloqueio, replay e executor de código
    Controle: F para abrir/fechar
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Interface Principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvancedDumpPanel"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 800, 0, 600)
MainFrame.Position = UDim2.new(0.5, -400, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false  -- Inicia invisível
MainFrame.Parent = ScreenGui

-- Barra de título
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Advanced Dump Panel v2.0 - [F] para Abrir/Fechar"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.Parent = TitleBar

-- Botão de fechar
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -30, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = TitleBar

-- Abas principais
local TabButtons = Instance.new("Frame")
TabButtons.Size = UDim2.new(1, 0, 0, 40)
TabButtons.Position = UDim2.new(0, 0, 0, 30)
TabButtons.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TabButtons.Parent = MainFrame

-- Conteúdo das abas
local TabContent = Instance.new("Frame")
TabContent.Size = UDim2.new(1, 0, 1, -70)
TabContent.Position = UDim2.new(0, 0, 0, 70)
TabContent.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TabContent.Parent = MainFrame

-- Variáveis globais
local CurrentTab = "Dump"
local CapturedEvents = {}
local BlockedEvents = {}
local ScriptCache = {}
local IsUIVisible = false

-- Função para alternar a visibilidade da UI
local function ToggleUI()
    IsUIVisible = not IsUIVisible
    MainFrame.Visible = IsUIVisible
    
    if IsUIVisible then
        -- Atualizar a interface quando abrir
        SwitchTab(CurrentTab)
    end
end

-- Configurar hotkey F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        ToggleUI()
    end
end)

-- Botão de fechar
CloseButton.MouseButton1Click:Connect(function()
    ToggleUI()
end)

-- Criar botões das abas
local Tabs = {
    "Dump",
    "Event Logs", 
    "Key Logs",
    "Code Executor",
    "Settings"
}

local function CreateTabButton(name, index)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0, 120, 1, 0)
    Button.Position = UDim2.new(0, (index-1)*120, 0, 0)
    Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Button.Text = name
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.Gotham
    Button.TextSize = 12
    Button.Parent = TabButtons
    
    Button.MouseButton1Click:Connect(function()
        SwitchTab(name)
    end)
end

-- Função para trocar de aba
function SwitchTab(tabName)
    CurrentTab = tabName
    
    -- Limpar conteúdo anterior
    for _, child in pairs(TabContent:GetChildren()) do
        child:Destroy()
    end
    
    -- Criar conteúdo baseado na aba
    if tabName == "Dump" then
        CreateDumpTab()
    elseif tabName == "Event Logs" then
        CreateEventLogsTab()
    elseif tabName == "Key Logs" then
        CreateKeyLogsTab()
    elseif tabName == "Code Executor" then
        CreateCodeExecutorTab()
    elseif tabName == "Settings" then
        CreateSettingsTab()
    end
end

-- ABA DUMP
function CreateDumpTab()
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    ScrollFrame.ScrollBarThickness = 8
    ScrollFrame.Parent = TabContent
    
    local DumpButton = Instance.new("TextButton")
    DumpButton.Size = UDim2.new(0.9, 0, 0, 40)
    DumpButton.Position = UDim2.new(0.05, 0, 0, 10)
    DumpButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    DumpButton.Text = "INICIAR DUMP COMPLETO"
    DumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DumpButton.Font = Enum.Font.GothamBold
    DumpButton.TextSize = 14
    DumpButton.Parent = ScrollFrame
    
    local OutputBox = Instance.new("TextBox")
    OutputBox.Size = UDim2.new(0.9, 0, 0, 400)
    OutputBox.Position = UDim2.new(0.05, 0, 0, 60)
    OutputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    OutputBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    OutputBox.Text = "Aguardando dump...\nPressione F para abrir/fechar este painel"
    OutputBox.Font = Enum.Font.Code
    OutputBox.TextSize = 11
    OutputBox.TextXAlignment = Enum.TextXAlignment.Left
    OutputBox.TextYAlignment = Enum.TextYAlignment.Top
    OutputBox.TextWrapped = true
    OutputBox.MultiLine = true
    OutputBox.Parent = ScrollFrame
    
    DumpButton.MouseButton1Click:Connect(function()
        PerformFullDump(OutputBox)
    end)
end

-- Função de dump completo
function PerformFullDump(outputBox)
    outputBox.Text = "Iniciando dump completo...\n"
    
    local function DumpGameStructure(parent, indent, path)
        indent = indent or ""
        path = path or ""
        
        for _, obj in pairs(parent:GetChildren()) do
            local objPath = path .. "/" .. obj.Name
            local line = indent .. obj.Name .. " (" .. obj.ClassName .. ")"
            
            outputBox.Text = outputBox.Text .. line .. "\n"
            
            -- Salvar scripts para cache
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                ScriptCache[objPath] = {
                    Object = obj,
                    Path = objPath,
                    ClassName = obj.ClassName
                }
            end
            
            -- Recursão para objetos filhos
            DumpGameStructure(obj, indent .. "  ", objPath)
        end
    end
    
    -- Dump de serviços principais
    outputBox.Text = outputBox.Text .. "\n=== SERVIÇOS DO JOGO ===\n"
    for _, service in pairs(game:GetChildren()) do
        outputBox.Text = outputBox.Text .. "Serviço: " .. service.Name .. "\n"
        DumpGameStructure(service, "  ", service.Name)
    end
    
    outputBox.Text = outputBox.Text .. "\n=== DUMP CONCLUÍDO ===\n"
    outputBox.Text = outputBox.Text .. "Scripts encontrados: " .. tostring(#ScriptCache) .. "\n"
end

-- ABA EVENT LOGS
function CreateEventLogsTab()
    local MainScroll = Instance.new("ScrollingFrame")
    MainScroll.Size = UDim2.new(1, 0, 1, 0)
    MainScroll.CanvasSize = UDim2.new(0, 0, 3, 0)
    MainScroll.ScrollBarThickness = 8
    MainScroll.Parent = TabContent
    
    local StartButton = Instance.new("TextButton")
    StartButton.Size = UDim2.new(0.4, 0, 0, 30)
    StartButton.Position = UDim2.new(0.05, 0, 0, 10)
    StartButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    StartButton.Text = "INICIAR CAPTURA"
    StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartButton.Font = Enum.Font.GothamBold
    StartButton.TextSize = 12
    StartButton.Parent = MainScroll
    
    local ClearButton = Instance.new("TextButton")
    ClearButton.Size = UDim2.new(0.4, 0, 0, 30)
    ClearButton.Position = UDim2.new(0.55, 0, 0, 10)
    ClearButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    ClearButton.Text = "LIMPAR LOGS"
    ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearButton.Font = Enum.Font.GothamBold
    ClearButton.TextSize = 12
    ClearButton.Parent = MainScroll
    
    local EventsList = Instance.new("ScrollingFrame")
    EventsList.Size = UDim2.new(0.9, 0, 0, 400)
    EventsList.Position = UDim2.new(0.05, 0, 0, 50)
    EventsList.CanvasSize = UDim2.new(0, 0, 2, 0)
    EventsList.ScrollBarThickness = 8
    EventsList.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    EventsList.Parent = MainScroll
    
    local IsCapturing = false
    
    -- Hook para capturar eventos
    local function HookRemoteEvents()
        for _, obj in pairs(game:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not obj:GetAttribute("Hooked") then
                obj:SetAttribute("Hooked", true)
                
                local oldFireServer = obj.FireServer
                local oldInvokeServer = obj.InvokeServer
                
                if obj:IsA("RemoteEvent") then
                    obj.FireServer = function(self, ...)
                        local args = {...}
                        local eventData = {
                            Object = obj,
                            Arguments = args,
                            Timestamp = os.time(),
                            Type = "RemoteEvent"
                        }
                        
                        table.insert(CapturedEvents, eventData)
                        UpdateEventsList(EventsList)
                        
                        if not BlockedEvents[obj] then
                            return oldFireServer(self, unpack(args))
                        else
                            print("Evento bloqueado: " .. obj:GetFullName())
                        end
                    end
                else
                    obj.InvokeServer = function(self, ...)
                        local args = {...}
                        local eventData = {
                            Object = obj,
                            Arguments = args,
                            Timestamp = os.time(),
                            Type = "RemoteFunction"
                        }
                        
                        table.insert(CapturedEvents, eventData)
                        UpdateEventsList(EventsList)
                        
                        if not BlockedEvents[obj] then
                            return oldInvokeServer(self, unpack(args))
                        else
                            print("Função bloqueada: " .. obj:GetFullName())
                            return nil
                        end
                    end
                end
            end
        end
    end
    
    StartButton.MouseButton1Click:Connect(function()
        IsCapturing = not IsCapturing
        if IsCapturing then
            StartButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            StartButton.Text = "PARAR CAPTURA"
            HookRemoteEvents()
        else
            StartButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
            StartButton.Text = "INICIAR CAPTURA"
        end
    end)
    
    ClearButton.MouseButton1Click:Connect(function()
        CapturedEvents = {}
        UpdateEventsList(EventsList)
    end)
    
    -- Atualizar hook periodicamente
    spawn(function()
        while wait(5) do
            if IsCapturing then
                HookRemoteEvents()
            end
        end
    end)
end

function UpdateEventsList(eventsList)
    for _, child in pairs(eventsList:GetChildren()) do
        child:Destroy()
    end
    
    local yPos = 0
    for i, event in pairs(CapturedEvents) do
        local EventFrame = Instance.new("Frame")
        EventFrame.Size = UDim2.new(1, 0, 0, 80)
        EventFrame.Position = UDim2.new(0, 0, 0, yPos)
        EventFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        EventFrame.BorderSizePixel = 1
        EventFrame.Parent = eventsList
        
        local EventName = Instance.new("TextLabel")
        EventName.Size = UDim2.new(0.7, 0, 0, 20)
        EventName.Position = UDim2.new(0, 5, 0, 5)
        EventName.BackgroundTransparency = 1
        EventName.Text = event.Object:GetFullName() .. " (" .. event.Type .. ")"
        EventName.TextColor3 = Color3.fromRGB(255, 255, 255)
        EventName.Font = Enum.Font.Gotham
        EventName.TextSize = 12
        EventName.TextXAlignment = Enum.TextXAlignment.Left
        EventName.Parent = EventFrame
        
        local BlockButton = Instance.new("TextButton")
        BlockButton.Size = UDim2.new(0.2, 0, 0, 20)
        BlockButton.Position = UDim2.new(0.7, 5, 0, 5)
        BlockButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        BlockButton.Text = "BLOQUEAR"
        BlockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        BlockButton.Font = Enum.Font.GothamBold
        BlockButton.TextSize = 10
        BlockButton.Parent = EventFrame
        
        local ReplayButton = Instance.new("TextButton")
        ReplayButton.Size = UDim2.new(0.2, 0, 0, 20)
        ReplayButton.Position = UDim2.new(0.7, 5, 0, 30)
        ReplayButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
        ReplayButton.Text = "REPLAY"
        ReplayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ReplayButton.Font = Enum.Font.GothamBold
        ReplayButton.TextSize = 10
        ReplayButton.Parent = EventFrame
        
        local ArgsLabel = Instance.new("TextLabel")
        ArgsLabel.Size = UDim2.new(0.7, 0, 0, 50)
        ArgsLabel.Position = UDim2.new(0, 5, 0, 25)
        ArgsLabel.BackgroundTransparency = 1
        ArgsLabel.Text = "Args: " .. tostring(#event.Arguments) .. " argumentos"
        ArgsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        ArgsLabel.Font = Enum.Font.Gotham
        ArgsLabel.TextSize = 10
        ArgsLabel.TextXAlignment = Enum.TextXAlignment.Left
        ArgsLabel.TextYAlignment = Enum.TextYAlignment.Top
        ArgsLabel.TextWrapped = true
        ArgsLabel.Parent = EventFrame
        
        BlockButton.MouseButton1Click:Connect(function()
            BlockedEvents[event.Object] = not BlockedEvents[event.Object]
            BlockButton.BackgroundColor3 = BlockedEvents[event.Object] and Color3.fromRGB(60, 180, 80) or Color3.fromRGB(180, 60, 60)
            BlockButton.Text = BlockedEvents[event.Object] and "DESBLOQUEAR" or "BLOQUEAR"
        end)
        
        ReplayButton.MouseButton1Click:Connect(function()
            if event.Type == "RemoteEvent" then
                event.Object:FireServer(unpack(event.Arguments))
            else
                event.Object:InvokeServer(unpack(event.Arguments))
            end
        end)
        
        yPos = yPos + 85
    end
    
    eventsList.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

-- ABA KEY LOGS
function CreateKeyLogsTab()
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    ScrollFrame.Parent = TabContent
    
    local KeyLogsBox = Instance.new("TextBox")
    KeyLogsBox.Size = UDim2.new(0.9, 0, 0, 500)
    KeyLogsBox.Position = UDim2.new(0.05, 0, 0, 10)
    KeyLogsBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    KeyLogsBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    KeyLogsBox.Text = "Key Logs aparecerão aqui...\nPressione F para abrir/fechar o painel\n"
    KeyLogsBox.Font = Enum.Font.Code
    KeyLogsBox.TextSize = 11
    KeyLogsBox.TextXAlignment = Enum.TextXAlignment.Left
    KeyLogsBox.TextYAlignment = Enum.TextYAlignment.Top
    KeyLogsBox.TextWrapped = true
    KeyLogsBox.MultiLine = true
    KeyLogsBox.Parent = ScrollFrame
    
    -- Captura de input do usuário
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            local keyText = "Input: " .. tostring(input.KeyCode) .. " | Tipo: " .. tostring(input.UserInputType) .. " | Time: " .. os.date("%X") .. "\n"
            KeyLogsBox.Text = KeyLogsBox.Text .. keyText
        end
    end)
end

-- ABA CODE EXECUTOR
function CreateCodeExecutorTab()
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
    ScrollFrame.Parent = TabContent
    
    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(0.9, 0, 0, 300)
    CodeBox.Position = UDim2.new(0.05, 0, 0, 10)
    CodeBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    CodeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    CodeBox.Text = "-- Cole seu código aqui ou modifique eventos capturados\n-- Pressione F para abrir/fechar o painel\n\nprint(\"Executor Pronto!\")\n"
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextSize = 11
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.TextWrapped = true
    CodeBox.MultiLine = true
    CodeBox.Parent = ScrollFrame
    
    local ExecuteButton = Instance.new("TextButton")
    ExecuteButton.Size = UDim2.new(0.9, 0, 0, 40)
    ExecuteButton.Position = UDim2.new(0.05, 0, 0, 320)
    ExecuteButton.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    ExecuteButton.Text = "EXECUTAR CÓDIGO"
    ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteButton.Font = Enum.Font.GothamBold
    ExecuteButton.TextSize = 14
    ExecuteButton.Parent = ScrollFrame
    
    local OutputBox = Instance.new("TextBox")
    OutputBox.Size = UDim2.new(0.9, 0, 0, 150)
    OutputBox.Position = UDim2.new(0.05, 0, 0, 370)
    OutputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    OutputBox.TextColor3 = Color3.fromRGB(0, 255, 0)
    OutputBox.Text = "Output aparecerá aqui...\n"
    OutputBox.Font = Enum.Font.Code
    OutputBox.TextSize = 11
    OutputBox.TextXAlignment = Enum.TextXAlignment.Left
    OutputBox.TextYAlignment = Enum.TextYAlignment.Top
    OutputBox.TextWrapped = true
    OutputBox.MultiLine = true
    OutputBox.Parent = ScrollFrame
    
    ExecuteButton.MouseButton1Click:Connect(function()
        local code = CodeBox.Text
        local success, result = pcall(function()
            return loadstring(code)()
        end)
        
        if success then
            OutputBox.Text = OutputBox.Text .. "[SUCESSO] Código executado\n"
            if result then
                OutputBox.Text = OutputBox.Text .. "Retorno: " .. tostring(result) .. "\n"
            end
        else
            OutputBox.Text = OutputBox.Text .. "[ERRO] " .. tostring(result) .. "\n"
        end
    end)
end

-- ABA SETTINGS
function CreateSettingsTab()
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
    ScrollFrame.Parent = TabContent
    
    local AutoHookToggle = Instance.new("TextButton")
    AutoHookToggle.Size = UDim2.new(0.9, 0, 0, 40)
    AutoHookToggle.Position = UDim2.new(0.05, 0, 0, 10)
    AutoHookToggle.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
    AutoHookToggle.Text = "AUTO HOOK: ATIVADO"
    AutoHookToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    AutoHookToggle.Font = Enum.Font.GothamBold
    AutoHookToggle.TextSize = 14
    AutoHookToggle.Parent = ScrollFrame
    
    local SaveLogsButton = Instance.new("TextButton")
    SaveLogsButton.Size = UDim2.new(0.9, 0, 0, 40)
    SaveLogsButton.Position = UDim2.new(0.05, 0, 0, 60)
    SaveLogsButton.BackgroundColor3 = Color3.fromRGB(80, 160, 120)
    SaveLogsButton.Text = "SALVAR LOGS EM ARQUIVO"
    SaveLogsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveLogsButton.Font = Enum.Font.GothamBold
    SaveLogsButton.TextSize = 14
    SaveLogsButton.Parent = ScrollFrame
    
    local ClearAllButton = Instance.new("TextButton")
    ClearAllButton.Size = UDim2.new(0.9, 0, 0, 40)
    ClearAllButton.Position = UDim2.new(0.05, 0, 0, 110)
    ClearAllButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    ClearAllButton.Text = "LIMPAR TUDO"
    ClearAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearAllButton.Font = Enum.Font.GothamBold
    ClearAllButton.TextSize = 14
    ClearAllButton.Parent = ScrollFrame
    
    local HotkeyInfo = Instance.new("TextLabel")
    HotkeyInfo.Size = UDim2.new(0.9, 0, 0, 60)
    HotkeyInfo.Position = UDim2.new(0.05, 0, 0, 160)
    HotkeyInfo.BackgroundTransparency = 1
    HotkeyInfo.Text = "📝 Controles:\n• F - Abrir/Fechar Painel\n• Botão X - Fechar Painel\n• Clique nas abas para navegar"
    HotkeyInfo.TextColor3 = Color3.fromRGB(200, 200, 255)
    HotkeyInfo.Font = Enum.Font.Gotham
    HotkeyInfo.TextSize = 12
    HotkeyInfo.TextXAlignment = Enum.TextXAlignment.Left
    HotkeyInfo.TextYAlignment = Enum.TextYAlignment.Top
    HotkeyInfo.TextWrapped = true
    HotkeyInfo.Parent = ScrollFrame
end

-- Inicializar interface
for i, tabName in pairs(Tabs) do
    CreateTabButton(tabName, i)
end

SwitchTab("Dump")

-- Notificação inicial
print("🎮 Advanced Dump Panel Carregado!")
print("📢 Pressione F para abrir/fechar o painel")
print("🔧 Desenvolvido para análise e debugging")

-- Função de utilidade para salvar logs
function SaveLogsToFile()
    -- Esta função seria implementada dependendo do ambiente de execução
    print("Função de salvar logs - implementação específica do ambiente")
end
