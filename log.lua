--[[
    REMOTE EVENT LOGGER v2.0
    Logger funcional para captura de RemoteEvents/Functions
]]

print("🔷 Iniciando Remote Logger v2.0...")

-- ============================================================================
-- DADOS GLOBAIS
-- ============================================================================
local Logger = {
    Events = {},
    Logs = {},
    Blocked = {},
    Stats = {Total = 0, RE = 0, RF = 0},
    UI = {},
    IsOpen = false,
    CurrentTab = 1
}

-- ============================================================================
-- SERVIÇOS
-- ============================================================================
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

-- ============================================================================
-- FUNÇÕES AUXILIARES
-- ============================================================================
local function AddLog(msg, tipo)
    table.insert(Logger.Logs, 1, {
        Time = os.date("%H:%M:%S"),
        Msg = msg,
        Type = tipo or "INFO"
    })
    if #Logger.Logs > 30 then
        table.remove(Logger.Logs)
    end
    print("[LOGGER]", msg)
end

local function FormatArgs(args)
    if not args or #args == 0 then return "{}" end
    local result = {}
    for i = 1, math.min(3, #args) do
        local v = args[i]
        local t = typeof(v)
        if t == "Instance" then
            table.insert(result, v.Name)
        elseif t == "string" then
            table.insert(result, '"'..tostring(v):sub(1,15)..'"')
        elseif t == "number" or t == "boolean" then
            table.insert(result, tostring(v))
        else
            table.insert(result, t)
        end
    end
    if #args > 3 then table.insert(result, "...") end
    return "{"..table.concat(result, ", ").."}"
end

-- ============================================================================
-- CAPTURA DE EVENTOS
-- ============================================================================
function Logger:CaptureEvent(remote, tipo, args)
    if not remote or not remote.Parent then return end
    
    local path = remote:GetFullName()
    
    -- Verificar bloqueio
    if self.Blocked[path] then return end
    
    -- Verificar duplicata recente
    for _, evt in ipairs(self.Events) do
        if evt.Path == path and (tick() - evt.Time) < 1 then
            evt.Count = evt.Count + 1
            return
        end
    end
    
    -- Criar evento
    local event = {
        Name = remote.Name,
        Type = tipo,
        Path = path,
        Remote = remote,
        Args = args or {},
        Time = tick(),
        Count = 1,
        Loop = false
    }
    
    table.insert(self.Events, 1, event)
    
    -- Atualizar stats
    self.Stats.Total = self.Stats.Total + 1
    if tipo == "RE" then
        self.Stats.RE = self.Stats.RE + 1
    else
        self.Stats.RF = self.Stats.RF + 1
    end
    
    -- Limitar eventos
    if #self.Events > 50 then
        table.remove(self.Events)
    end
    
    -- Atualizar UI
    if self.IsOpen and self.CurrentTab == 1 then
        self:UpdateEventsUI()
    end
end

-- ============================================================================
-- SISTEMA DE HOOKS
-- ============================================================================
function Logger:InstallHooks()
    AddLog("Instalando hooks...", "INFO")
    
    local hooked = 0
    
    -- Hook via metamethod
    if hookmetamethod and getnamecallmethod then
        local success = pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                if method == "FireServer" and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                    task.spawn(function()
                        Logger:CaptureEvent(self, "RE", args)
                    end)
                elseif method == "InvokeServer" and typeof(self) == "Instance" and self:IsA("RemoteFunction") then
                    task.spawn(function()
                        Logger:CaptureEvent(self, "RF", args)
                    end)
                end
                
                return old(self, ...)
            end)
            hooked = hooked + 1
        end)
        
        if success then
            AddLog("Hook metamethod OK", "SUCCESS")
        end
    end
    
    AddLog("Hooks instalados: "..hooked, "SUCCESS")
end

-- ============================================================================
-- AÇÕES
-- ============================================================================
function Logger:ReplayEvent(event)
    if not event.Remote or not event.Remote.Parent then
        AddLog("Remote inválido", "ERROR")
        return
    end
    
    local success = pcall(function()
        if event.Type == "RE" then
            event.Remote:FireServer(unpack(event.Args))
        else
            event.Remote:InvokeServer(unpack(event.Args))
        end
    end)
    
    if success then
        AddLog("Replay: "..event.Name, "SUCCESS")
    else
        AddLog("Erro no replay", "ERROR")
    end
end

function Logger:ToggleLoop(event)
    event.Loop = not event.Loop
    
    if event.Loop then
        AddLog("Loop ON: "..event.Name, "INFO")
        task.spawn(function()
            while event.Loop and event.Remote and event.Remote.Parent do
                pcall(function()
                    if event.Type == "RE" then
                        event.Remote:FireServer(unpack(event.Args))
                    else
                        event.Remote:InvokeServer(unpack(event.Args))
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        AddLog("Loop OFF: "..event.Name, "INFO")
    end
end

function Logger:BlockEvent(event)
    local path = event.Path
    self.Blocked[path] = not self.Blocked[path]
    
    if self.Blocked[path] then
        AddLog("Bloqueado: "..event.Name, "WARNING")
    else
        AddLog("Desbloqueado: "..event.Name, "INFO")
    end
end

function Logger:ClearEvents()
    self.Events = {}
    self.Stats = {Total = 0, RE = 0, RF = 0}
    AddLog("Eventos limpos", "INFO")
    self:UpdateEventsUI()
end

-- ============================================================================
-- INTERFACE
-- ============================================================================
function Logger:CreateUI()
    AddLog("Criando UI...", "INFO")
    
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "RemoteLogger"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        sg.Parent = game:GetService("CoreGui")
    end)
    
    if not sg.Parent then
        sg.Parent = Player:WaitForChild("PlayerGui")
    end
    
    self.UI.ScreenGui = sg
    
    -- Frame Principal
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 700, 0, 500)
    main.Position = UDim2.new(0.5, -350, 0.5, -250)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    main.BorderSizePixel = 2
    main.BorderColor3 = Color3.fromRGB(60, 60, 70)
    main.Visible = false
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    
    self.UI.Main = main
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    header.BorderSizePixel = 0
    header.Text = "⚡ REMOTE LOGGER v2.0"
    header.TextColor3 = Color3.fromRGB(100, 150, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 16
    header.Parent = main
    
    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -38, 0, 3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.white
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = header
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -10, 0, 35)
    tabFrame.Position = UDim2.new(0, 5, 0, 45)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = main
    
    local tabs = {"Eventos", "Executor", "Logs"}
    self.UI.TabButtons = {}
    
    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 150, 1, 0)
        btn.Position = UDim2.new(0, (i-1)*155, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(180, 180, 200)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.BorderSizePixel = 0
        btn.Parent = tabFrame
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(i)
        end)
        
        self.UI.TabButtons[i] = btn
    end
    
    -- Content Frame
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -90)
    content.Position = UDim2.new(0, 5, 0, 85)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    self.UI.Content = content
    
    -- Criar páginas
    self:CreateEventsPage(content)
    self:CreateExecutorPage(content)
    self:CreateLogsPage(content)
    
    AddLog("UI criada", "SUCCESS")
end

function Logger:CreateEventsPage(parent)
    local page = Instance.new("Frame")
    page.Name = "Events"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = parent
    
    -- Botões de ação
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, 0, 0, 30)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = page
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 100, 1, 0)
    clearBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    clearBtn.Text = "Limpar"
    clearBtn.TextColor3 = Color3.white
    clearBtn.Font = Enum.Font.Gotham
    clearBtn.TextSize = 12
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = btnFrame
    
    clearBtn.MouseButton1Click:Connect(function()
        self:ClearEvents()
    end)
    
    -- Stats
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(0, 300, 1, 0)
    stats.Position = UDim2.new(0, 110, 0, 0)
    stats.BackgroundTransparency = 1
    stats.Text = "Total: 0 | RE: 0 | RF: 0"
    stats.TextColor3 = Color3.fromRGB(150, 200, 255)
    stats.Font = Enum.Font.Gotham
    stats.TextSize = 11
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = btnFrame
    
    self.UI.Stats = stats
    
    -- Lista de eventos
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -35)
    scroll.Position = UDim2.new(0, 0, 0, 35)
    scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    scroll.BorderSizePixel = 1
    scroll.BorderColor3 = Color3.fromRGB(50, 50, 60)
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = page
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    self.UI.EventsList = scroll
    self.UI.EventsPage = page
end

function Logger:CreateExecutorPage(parent)
    local page = Instance.new("Frame")
    page.Name = "Executor"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = parent
    
    local codeBox = Instance.new("TextBox")
    codeBox.Size = UDim2.new(1, 0, 1, -40)
    codeBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    codeBox.BorderColor3 = Color3.fromRGB(50, 50, 60)
    codeBox.Text = ""
    codeBox.PlaceholderText = "-- Cole seu código aqui"
    codeBox.TextColor3 = Color3.fromRGB(220, 220, 230)
    codeBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    codeBox.Font = Enum.Font.Code
    codeBox.TextSize = 12
    codeBox.TextXAlignment = Enum.TextXAlignment.Left
    codeBox.TextYAlignment = Enum.TextYAlignment.Top
    codeBox.MultiLine = true
    codeBox.ClearTextOnFocus = false
    codeBox.Parent = page
    
    self.UI.CodeBox = codeBox
    
    local execBtn = Instance.new("TextButton")
    execBtn.Size = UDim2.new(1, 0, 0, 35)
    execBtn.Position = UDim2.new(0, 0, 1, -35)
    execBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    execBtn.Text = "EXECUTAR"
    execBtn.TextColor3 = Color3.white
    execBtn.Font = Enum.Font.GothamBold
    execBtn.TextSize = 14
    execBtn.BorderSizePixel = 0
    execBtn.Parent = page
    
    execBtn.MouseButton1Click:Connect(function()
        local code = codeBox.Text
        if code ~= "" then
            AddLog("Executando código...", "INFO")
            local func, err = loadstring(code)
            if func then
                local success, result = pcall(func)
                if success then
                    AddLog("Código executado", "SUCCESS")
                else
                    AddLog("Erro: "..tostring(result), "ERROR")
                end
            else
                AddLog("Erro de sintaxe: "..tostring(err), "ERROR")
            end
        end
    end)
    
    self.UI.ExecutorPage = page
end

function Logger:CreateLogsPage(parent)
    local page = Instance.new("Frame")
    page.Name = "Logs"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = parent
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    scroll.BorderColor3 = Color3.fromRGB(50, 50, 60)
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = page
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = scroll
    
    self.UI.LogsList = scroll
    self.UI.LogsPage = page
end

function Logger:SwitchTab(index)
    self.CurrentTab = index
    
    -- Atualizar botões
    for i, btn in pairs(self.UI.TabButtons) do
        if i == index then
            btn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
            btn.TextColor3 = Color3.white
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.TextColor3 = Color3.fromRGB(180, 180, 200)
        end
    end
    
    -- Atualizar páginas
    self.UI.EventsPage.Visible = (index == 1)
    self.UI.ExecutorPage.Visible = (index == 2)
    self.UI.LogsPage.Visible = (index == 3)
    
    -- Atualizar conteúdo
    if index == 1 then
        self:UpdateEventsUI()
    elseif index == 3 then
        self:UpdateLogsUI()
    end
end

function Logger:UpdateEventsUI()
    if not self.UI.EventsList then return end
    
    -- Limpar
    for _, child in ipairs(self.UI.EventsList:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Atualizar stats
    if self.UI.Stats then
        self.UI.Stats.Text = string.format("Total: %d | RE: %d | RF: %d", 
            self.Stats.Total, self.Stats.RE, self.Stats.RF)
    end
    
    -- Criar cards
    for i, evt in ipairs(self.Events) do
        if i > 15 then break end
        
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -5, 0, 80)
        card.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        card.BorderSizePixel = 1
        card.BorderColor3 = Color3.fromRGB(60, 60, 70)
        card.Parent = self.UI.EventsList
        
        -- Nome
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -10, 0, 18)
        name.Position = UDim2.new(0, 5, 0, 3)
        name.BackgroundTransparency = 1
        name.Text = string.format("[%s] %s x%d", evt.Type, evt.Name, evt.Count)
        name.TextColor3 = evt.Type == "RE" and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 180, 80)
        name.Font = Enum.Font.GothamBold
        name.TextSize = 12
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = card
        
        -- Path
        local path = Instance.new("TextLabel")
        path.Size = UDim2.new(1, -10, 0, 14)
        path.Position = UDim2.new(0, 5, 0, 22)
        path.BackgroundTransparency = 1
        path.Text = evt.Path
        path.TextColor3 = Color3.fromRGB(120, 120, 140)
        path.Font = Enum.Font.Code
        path.TextSize = 9
        path.TextXAlignment = Enum.TextXAlignment.Left
        path.TextTruncate = Enum.TextTruncate.AtEnd
        path.Parent = card
        
        -- Args
        local args = Instance.new("TextLabel")
        args.Size = UDim2.new(1, -10, 0, 14)
        args.Position = UDim2.new(0, 5, 0, 37)
        args.BackgroundTransparency = 1
        args.Text = "Args: "..FormatArgs(evt.Args)
        args.TextColor3 = Color3.fromRGB(255, 200, 100)
        args.Font = Enum.Font.Code
        args.TextSize = 9
        args.TextXAlignment = Enum.TextXAlignment.Left
        args.TextTruncate = Enum.TextTruncate.AtEnd
        args.Parent = card
        
        -- Botões
        local btnY = 55
        local btnX = 5
        
        -- Replay
        local replay = Instance.new("TextButton")
        replay.Size = UDim2.new(0, 40, 0, 20)
        replay.Position = UDim2.new(0, btnX, 0, btnY)
        replay.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        replay.Text = "▶"
        replay.TextColor3 = Color3.white
        replay.Font = Enum.Font.GothamBold
        replay.TextSize = 10
        replay.BorderSizePixel = 0
        replay.Parent = card
        
        replay.MouseButton1Click:Connect(function()
            self:ReplayEvent(evt)
        end)
        
        btnX = btnX + 45
        
        -- Loop
        local loopBtn = Instance.new("TextButton")
        loopBtn.Size = UDim2.new(0, 40, 0, 20)
        loopBtn.Position = UDim2.new(0, btnX, 0, btnY)
        loopBtn.BackgroundColor3 = evt.Loop and Color3.fromRGB(200, 80, 80) or Color3.fromRGB(255, 180, 80)
        loopBtn.Text = evt.Loop and "⏹" or "🔁"
        loopBtn.TextColor3 = Color3.white
        loopBtn.Font = Enum.Font.GothamBold
        loopBtn.TextSize = 10
        loopBtn.BorderSizePixel = 0
        loopBtn.Parent = card
        
        loopBtn.MouseButton1Click:Connect(function()
            self:ToggleLoop(evt)
            task.wait(0.1)
            self:UpdateEventsUI()
        end)
        
        btnX = btnX + 45
        
        -- Block
        local isBlocked = self.Blocked[evt.Path]
        local blockBtn = Instance.new("TextButton")
        blockBtn.Size = UDim2.new(0, 40, 0, 20)
        blockBtn.Position = UDim2.new(0, btnX, 0, btnY)
        blockBtn.BackgroundColor3 = isBlocked and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(200, 80, 80)
        blockBtn.Text = isBlocked and "✓" or "🚫"
        blockBtn.TextColor3 = Color3.white
        blockBtn.Font = Enum.Font.GothamBold
        blockBtn.TextSize = 10
        blockBtn.BorderSizePixel = 0
        blockBtn.Parent = card
        
        blockBtn.MouseButton1Click:Connect(function()
            self:BlockEvent(evt)
            task.wait(0.1)
            self:UpdateEventsUI()
        end)
    end
end

function Logger:UpdateLogsUI()
    if not self.UI.LogsList then return end
    
    -- Limpar
    for _, child in ipairs(self.UI.LogsList:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Criar logs
    for i, log in ipairs(self.Logs) do
        if i > 20 then break end
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -5, 0, 25)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        frame.BorderSizePixel = 0
        frame.Parent = self.UI.LogsList
        
        local color = Color3.fromRGB(180, 180, 200)
        if log.Type == "SUCCESS" then
            color = Color3.fromRGB(100, 200, 100)
        elseif log.Type == "ERROR" then
            color = Color3.fromRGB(255, 100, 100)
        elseif log.Type == "WARNING" then
            color = Color3.fromRGB(255, 180, 80)
        end
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, -10, 1, 0)
        text.Position = UDim2.new(0, 5, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = string.format("[%s] %s", log.Time, log.Msg)
        text.TextColor3 = color
        text.Font = Enum.Font.Code
        text.TextSize = 10
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextTruncate = Enum.TextTruncate.AtEnd
        text.Parent = frame
    end
end

function Logger:Toggle()
    self.IsOpen = not self.IsOpen
    self.UI.Main.Visible = self.IsOpen
    
    if self.IsOpen then
        self:SwitchTab(self.CurrentTab)
    end
end

-- ============================================================================
-- INICIALIZAÇÃO
-- ============================================================================
function Logger:Init()
    AddLog("Iniciando...", "INFO")
    
    self:CreateUI()
    self:InstallHooks()
    
    -- Keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.F then
            self:Toggle()
        end
    end)
    
    AddLog("Logger pronto! Pressione [F]", "SUCCESS")
    
    -- Abrir UI
    task.wait(1)
    self:Toggle()
end

-- Executar
task.spawn(function()
    local ok, err = pcall(function()
        Logger:Init()
    end)
    
    if not ok then
        warn("[LOGGER] ERRO:", err)
    end
end)

return Logger
