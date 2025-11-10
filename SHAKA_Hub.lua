-- Box moderno com gradiente
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = SavedStates.ESPColor
        esp.Box.Transparency = 1
        esp.Box.Visible = false
    end
    
    if SavedStates.ESPLine then
        esp.Line = Drawing.new("Line")
        esp.Line.Thickness = 2
        esp.Line.Color = SavedStates.ESPColor
        esp.Line.Transparency = 1
        esp.Line.Visible = false
    end
    
    if SavedStates.ESPName then
        esp.Name = Drawing.new("Text")
        esp.Name.Size = 15
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Color = Color3.new(1, 1, 1)
        esp.Name.Transparency = 1
        esp.Name.Visible = false
        esp.Name.Text = player.Name
        esp.Name.Font = 2
    end
    
    if SavedStates.ESPDistance then
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = 13
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Color = SavedStates.ESPColor
        esp.Distance.Transparency = 1
        esp.Distance.Visible = false
        esp.Distance.Font = 2
    end
    
    if SavedStates.ESPHealth then
        esp.HealthBarBG = Drawing.new("Square")
        esp.HealthBarBG.Thickness = 1
        esp.HealthBarBG.Filled = true
        esp.HealthBarBG.Color = Color3.new(0, 0, 0)
        esp.HealthBarBG.Transparency = 0.5
        esp.HealthBarBG.Visible = false
        
        esp.HealthBar = Drawing.new("Square")
        esp.HealthBar.Thickness = 1
        esp.HealthBar.Filled = true
        esp.HealthBar.Transparency = 1
        esp.HealthBar.Visible = false
    end
    
    if SavedStates.ESPChams then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local highlight = Instance.new("BoxHandleAdornment")
                    highlight.Size = part.Size
                    highlight.Color3 = SavedStates.ESPColor
                    highlight.Transparency = 0.5
                    highlight.AlwaysOnTop = true
                    highlight.ZIndex = 5
                    highlight.Adornee = part
                    highlight.Parent = part
                    
                    if not esp.Chams then
                        esp.Chams = {}
                    end
                    table.insert(esp.Chams, highlight)
                end
            end
        end
    end
    
    ESPObjects[player] = esp
end

local function UpdateESP()
    if not SavedStates.ESPEnabled then return end
    
    for player, esp in pairs(ESPObjects) do
        if not player or not player.Parent or player == LocalPlayer then
            pcall(function()
                if esp.Box then esp.Box:Remove() end
                if esp.Line then esp.Line:Remove() end
                if esp.Name then esp.Name:Remove() end
                if esp.Distance then esp.Distance:Remove() end
                if esp.HealthBar then esp.HealthBar:Remove() end
                if esp.HealthBarBG then esp.HealthBarBG:Remove() end
                if esp.Chams then
                    for _, highlight in pairs(esp.Chams) do
                        highlight:Destroy()
                    end
                end
            end)
            ESPObjects[player] = nil
            continue
        end
        
        local char = player.Character
        if not char then
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
            if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
            continue
        end
        
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
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
                    esp.Box.Color = SavedStates.ESPColor
                    esp.Box.Visible = true
                end
                
                if esp.Line and SavedStates.ESPLine then
                    esp.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    esp.Line.To = Vector2.new(rootPos.X, rootPos.Y)
                    esp.Line.Color = SavedStates.ESPColor
                    esp.Line.Visible = true
                end
                
                if esp.Name and SavedStates.ESPName then
                    esp.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                end
                
                if esp.Distance and SavedStates.ESPDistance and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude
                    esp.Distance.Position = Vector2.new(rootPos.X, legPos.Y + 5)
                    esp.Distance.Text = string.format("%d studs", math.floor(distance))
                    esp.Distance.Color = SavedStates.ESPColor
                    esp.Distance.Visible = true
                end
                
                if esp.HealthBar and esp.HealthBarBG and SavedStates.ESPHealth then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = height * healthPercent
                    
                    esp.HealthBarBG.Size = Vector2.new(4, height)
                    esp.HealthBarBG.Position = Vector2.new(rootPos.X - width/2 - 7, rootPos.Y - height/2)
                    esp.HealthBarBG.Visible = true
                    
                    esp.HealthBar.Size = Vector2.new(4, barHeight)
                    esp.HealthBar.Position = Vector2.new(rootPos.X - width/2 - 7, rootPos.Y + height/2 - barHeight)
                    esp.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    esp.HealthBar.Visible = true
                end
            else
                if esp.Box then esp.Box.Visible = false end
                if esp.Line then esp.Line.Visible = false end
                if esp.Name then esp.Name.Visible = false end
                if esp.Distance then esp.Distance.Visible = false end
                if esp.HealthBar then esp.HealthBar.Visible = false end
                if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
            end
        else
            if esp.Box then esp.Box.Visible = false end
            if esp.Line then esp.Line.Visible = false end
            if esp.Name then esp.Name.Visible = false end
            if esp.Distance then esp.Distance.Visible = false end
            if esp.HealthBar then esp.HealthBar.Visible = false end
            if esp.HealthBarBG then esp.HealthBarBG.Visible = false end
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
-- CRIAÇÃO DA GUI (ESTILO GTA RP)
-- ════════════════════════════════════════════════════════════
local function CreateGUI()
    if GUI then
        GUI:Destroy()
    end
    
    UIElements = {}
    
    GUI = Instance.new("ScreenGui")
    GUI.Name = "SHAKA_HUB"
    GUI.ResetOnSpawn = false
    GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local scale = SavedStates.MenuScale or 1
    
    -- Container Principal (Estilo GTA)
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420 * scale, 0, 500 * scale)
    main.Position = UDim2.new(1, -430 * scale, 0.5, -250 * scale)
    main.BackgroundColor3 = CONFIG.COR_FUNDO
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Parent = GUI
    
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)
    
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = GetCurrentColor()
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.3
    table.insert(UIElements, mainStroke)
    
    -- Header Moderno
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = CONFIG.COR_FUNDO_2
    header.BackgroundTransparency = 0.1
    header.BorderSizePixel = 0
    header.Parent = main
    
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    local headerGradient = Instance.new("UIGradient", header)
    headerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, GetCurrentColor()),
        ColorSequenceKeypoint.new(1, CONFIG.COR_FUNDO_2)
    }
    headerGradient.Rotation = 90
    headerGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(1, 0)
    }
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, -100, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "⬢ SHAKA HUB"
    logo.TextColor3 = CONFIG.COR_TEXTO
    logo.TextSize = 22
    logo.Font = Enum.Font.GothamBold
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = header
    
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 60, 0, 22)
    version.Position = UDim2.new(1, -75, 0, 19)
    version.BackgroundColor3 = GetCurrentColor()
    version.BackgroundTransparency = 0.3
    version.Text = CONFIG.VERSAO
    version.TextColor3 = CONFIG.COR_TEXTO
    version.TextSize = 11
    version.Font = Enum.Font.GothamBold
    version.BorderSizePixel = 0
    version.Parent = header
    version:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, version)
    
    Instance.new("UICorner", version).CornerRadius = UDim.new(0, 6)
    
    -- Tab Bar (Lado Direito Vertical - Estilo GTA)
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Size = UDim2.new(0, 140, 1, -70)
    tabBar.Position = UDim2.new(1, -145, 0, 65)
    tabBar.BackgroundColor3 = CONFIG.COR_FUNDO_2
    tabBar.BackgroundTransparency = 0.2
    tabBar.BorderSizePixel = 0
    tabBar.ScrollBarThickness = 3
    tabBar.ScrollBarImageColor3 = GetCurrentColor()
    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabBar.Parent = main
    
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)
    
    local tabStroke = Instance.new("UIStroke", tabBar)
    tabStroke.Color = CONFIG.COR_FUNDO_3
    tabStroke.Thickness = 1
    tabStroke.Transparency = 0.5
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabBar.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(0, 260, 1, -70)
    contentArea.Position = UDim2.new(0, 5, 0, 65)
    contentArea.BackgroundTransparency = 1
    contentArea.BorderSizePixel = 0
    contentArea.Parent = main
    
    -- Player List
    local playerListContainer = Instance.new("Frame")
    playerListContainer.Size = UDim2.new(1, 0, 0, 120)
    playerListContainer.BackgroundColor3 = CONFIG.COR_FUNDO_2
    playerListContainer.BackgroundTransparency = 0.3
    playerListContainer.BorderSizePixel = 0
    playerListContainer.Visible = false
    playerListContainer.Parent = contentArea
    
    Instance.new("UICorner", playerListContainer).CornerRadius = UDim.new(0, 10)
    
    local playerTitle = Instance.new("TextLabel")
    playerTitle.Size = UDim2.new(1, 0, 0, 30)
    playerTitle.BackgroundColor3 = GetCurrentColor()
    playerTitle.BackgroundTransparency = 0.5
    playerTitle.Text = "👥 JOGADORES"
    playerTitle.TextColor3 = CONFIG.COR_TEXTO
    playerTitle.TextSize = 12
    playerTitle.Font = Enum.Font.GothamBold
    playerTitle.BorderSizePixel = 0
    playerTitle.Parent = playerListContainer
    playerTitle:SetAttribute("ColorUpdate", true)
    table.insert(UIElements, playerTitle)
    
    Instance.new("UICorner", playerTitle).CornerRadius = UDim.new(0, 10)
    
    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1, -10, 0, 25)
    selectedLabel.Position = UDim2.new(0, 5, 0, 35)
    selectedLabel.BackgroundColor3 = CONFIG.COR_FUNDO
    selectedLabel.BackgroundTransparency = 0.3
    selectedLabel.Text = "Nenhum"
    selectedLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
    selectedLabel.TextSize = 10
    selectedLabel.Font = Enum.Font.Gotham
    selectedLabel.BorderSizePixel = 0
    selectedLabel.Parent = playerListContainer
    
    Instance.new("UICorner", selectedLabel).CornerRadius = UDim.new(0, 6)
    
    local playerScroll = Instance.new("ScrollingFrame")
    playerScroll.Size = UDim2.new(1, -10, 0, 55)
    playerScroll.Position = UDim2.new(0, 5, 0, 65)
    playerScroll.BackgroundTransparency = 1
    playerScroll.BorderSizePixel = 0
    playerScroll.ScrollBarThickness = 3
    playerScroll.ScrollBarImageColor3 = GetCurrentColor()
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerScroll.Parent = playerListContainer
    
    local function UpdatePlayerList()
        for _, child in pairs(playerScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("UIListLayout") then
                child:Destroy()
            end
        end
        
        local playerLayout = Instance.new("UIListLayout")
        playerLayout.Padding = UDim.new(0, 3)
        playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
        playerLayout.Parent = playerScroll
        
        playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            playerScroll.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 3)
        end)
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerBtn = Instance.new("TextButton")
                playerBtn.Size = UDim2.new(1, -3, 0, 28)
                playerBtn.BackgroundColor3 = CONFIG.COR_FUNDO
                playerBtn.BackgroundTransparency = 0.4
                playerBtn.Text = " " .. player.Name
                playerBtn.TextColor3 = CONFIG.COR_TEXTO
                playerBtn.TextSize = 10
                playerBtn.Font = Enum.Font.Gotham
                playerBtn.TextXAlignment = Enum.TextXAlignment.Left
                playerBtn.BorderSizePixel = 0
                playerBtn.Parent = playerScroll
                
                Instance.new("UICorner", playerBtn).CornerRadius = UDim.new(0, 6)
                
                if SelectedPlayer == player then
                    playerBtn.BackgroundColor3 = GetCurrentColor()
                    playerBtn.BackgroundTransparency = 0.3
                end
                
                playerBtn.MouseButton1Click:Connect(function()
                    SelectedPlayer = player
                    selectedLabel.Text = player.Name
                    selectedLabel.TextColor3 = GetCurrentColor()
                    UpdatePlayerList()
                end)
                
                playerBtn.MouseEnter:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundTransparency = 0.2}, 0.1)
                    end
                end)
                
                playerBtn.MouseLeave:Connect(function()
                    if SelectedPlayer ~= player then
                        Tween(playerBtn, {BackgroundTransparency = 0.4}, 0.1)
                    end
                end)
            end
        end
    end
    
    UpdatePlayerList()
    
    task.spawn(function()
        while GUI do
            UpdatePlayerList()
            task.wait(3)
        end
    end)
    
    -- Tab Content
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Size = UDim2.new(1, 0, 1, -130)
    tabContent.Position = UDim2.new(0, 0, 0, 125)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 3
    tabContent.ScrollBarImageColor3 = GetCurrentColor()
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContent.Parent = contentArea
    tabContent.Visible = false
    
    -- Tabs (Estilo GTA)
    local tabs = {
        {Name = "Player", Icon = "👤", ShowPlayerList = false},
        {Name = "Combat", Icon = "⚔️", ShowPlayerList = true},
        {Name = "Animações", Icon = "💃", ShowPlayerList = true},
        {Name = "Teleport", Icon = "📍", ShowPlayerList = true},
        {Name = "ESP", Icon = "👁️", ShowPlayerList = false},
        {Name = "Visual", Icon = "✨", ShowPlayerList = false},
        {Name = "Config", Icon = "⚙️", ShowPlayerList = false}
    }
    
    local currentTab = "Player"
    local tabFrames = {}
    
    -- Funções de criação de elementos (Estilo GTA mais compacto)
    local function CreateToggle(name, desc, savedKey, callback, parent)
        local toggle = Instance.new("Frame")
        toggle.Size = UDim2.new(1, -5, 0, 50)
        toggle.BackgroundColor3 = CONFIG.COR_FUNDO_2
        toggle.BackgroundTransparency = 0.4
        toggle.BorderSizePixel = 0
        toggle.Parent = parent
        
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.65, 0, 0, 18)
        nameLabel.Position = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = toggle
        
        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(0.65, 0, 0, 16)
        descLabel.Position = UDim2.new(0, 10, 0, 26)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = desc
        descLabel.TextColor3 = CONFIG.COR_TEXTO_SEC
        descLabel.TextSize = 9
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = toggle
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 45, 0, 22)
        btn.Position = UDim2.new(1, -52, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.Text = ""
        btn.BorderSizePixel = 0
        btn.Parent = toggle
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 2, 0, 2)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = btn
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 9)
        
        local state = SavedStates[savedKey] or false
        
        if state then
            btn.BackgroundColor3 = GetCurrentColor()
            knob.Position = UDim2.new(0, 25, 0, 2)
            btn:SetAttribute("ColorUpdate", true)
            table.insert(UIElements, btn)
        end
        
        btn.MouseButton1Click:Connect(function()
            state = not state
            SavedStates[savedKey] = state
            
            if state then
                Tween(btn, {BackgroundColor3 = GetCurrentColor()}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 25, 0, 2)}, 0.15)
                btn:SetAttribute("ColorUpdate", true)
                table.insert(UIElements, btn)
            else
                Tween(btn, {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}, 0.15)
                Tween(knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.15)
                btn:SetAttribute("ColorUpdate", false)
            end
            
            callback(state)
        end)
        
        return toggle
    end
    
    local function CreateSlider(name, min, max, savedKey, callback, parent)
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -5, 0, 55)
        slider.BackgroundColor3 = CONFIG.COR_FUNDO_2
        slider.BackgroundTransparency = 0.4
        slider.BorderSizePixel = 0
        slider.Parent = parent
        
        Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 8)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 0, 18)
        nameLabel.Position = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = CONFIG.COR_TEXTO
        nameLabel.TextSize = 12
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = slider
        
        local default = SavedStates[savedKey] or min
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.4, 0, 0, 18)
        valueLabel.Position = UDim2.new(0.6, 0, 0, 6)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = GetCurrentColor()
        valueLabel.TextSize = 12
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = slider
        valueLabel:SetAttribute("TextColorUpdate", true)
        table.insert(UIElements, valueLabel)
        
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -20, 0, 5)
        track.Position = UDim2.new(0, 10, 0, 35)
        track.BackgroundColor3 = CONFIG.COR_FUNDO
        track.BackgroundTransparency = 0.3
        track.BorderSizePixel = 0
        track.Parent = slider
        
        Instance.new("UICorner", track).CornerRadius = UDim.new(0, 2.5)
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = GetCurrentColor()
        fill.BorderSizePixel = 0
        fill.Parent = track
        fill:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, fill)
        
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2.5)
        
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 12, 0, 12)
        knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
        knob.BackgroundColor3 = CONFIG.COR_TEXTO
        knob.BorderSizePixel = 0
        knob.Parent = track
        
        Instance.new("UICorner", knob).CornerRadius = UDim.new(0, 6)
        
        local dragging = false
        
        local function update(input)
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * pos)
            
            fill.Size = UDim2.new(pos, 0, 1, 0)
            knob.Position = UDim2.new(pos, -6, 0.5, -6)
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
        btn.Size = UDim2.new(1, -5, 0, 35)
        btn.BackgroundColor3 = GetCurrentColor()
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.TextColor3 = CONFIG.COR_TEXTO
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = parent
        btn:SetAttribute("ColorUpdate", true)
        table.insert(UIElements, btn)
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = GetCurrentColor()
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        table.insert(UIElements, stroke)
        
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundTransparency = 0}, 0.15)
        end)
        
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundTransparency = 0.2}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        
        return btn
    end
    
    -- Criar tabs (estilo GTA)
    for i, tab in ipairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, -10, 0, 45)
        tabBtn.BackgroundColor3 = CONFIG.COR_FUNDO_3
        tabBtn.BackgroundTransparency = 0.5
        tabBtn.Text = tab.Icon .. "\n" .. tab.Name
        tabBtn.TextColor3 = CONFIG.COR_TEXTO
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabBar
        
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 8)
        
        local tabStroke = Instance.new("UIStroke", tabBtn)
        tabStroke.Color = CONFIG.COR_FUNDO_3
        tabStroke.Thickness = 1
        
        local tabFrame = Instance.new("Frame")
        tabFrame.Size = UDim2.new(1, 0, 1, 0)
        tabFrame.BackgroundTransparency = 1
        tabFrame.BorderSizePixel = 0
        tabFrame.Visible = false
        tabFrame.Parent = tabContent
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tabFrame
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 5)
        end)
        
        tabFrames[tab.Name] = tabFrame
        
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = tab.Name
            
            playerListContainer.Visible = tab.ShowPlayerList
            tabContent.Visible = true
            
            if tab.ShowPlayerList then
                tabContent.Size = UDim2.new(1, 0, 1, -130)
                tabContent.Position = UDim2.new(0, 0, 0, 125)
            else
                tabContent.Size = UDim2.new(1, 0, 1, -5)
                tabContent.Position = UDim2.new(0, 0, 0, 0)
            end
            
            for name, frame in pairs(tabFrames) do
                frame.Visible = (name == tab.Name)
            end
            
            for _, btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    Tween(btn, {BackgroundTransparency = 0.5}, 0.15)
                    btn.TextColor3 = CONFIG.COR_TEXTO
                end
            end
            
            Tween(tabBtn, {BackgroundTransparency = 0}, 0.15)
            tabBtn.TextColor3 = GetCurrentColor()
        end)
        
        if i == 1 then
            tabBtn.BackgroundTransparency = 0
            tabBtn.TextColor3 = GetCurrentColor()
            tabFrame.Visible = true
            tabContent.Visible = true
            tabContent.Size = UDim2.new(1, 0, 1, -5)
            tabContent.Position = UDim2.new(0, 0, 0, 0)
        end
    end
    
    -- ═══════════════ ABA PLAYER ═══════════════
    CreateToggle("✈️ Fly", "Voar livremente", "FlyEnabled", ToggleFly, tabFrames["Player"])
    CreateSlider("🚀 Velocidade Fly", 10, 300, "FlySpeed", function(value)
        SavedStates.FlySpeed = value
    end, tabFrames["Player"])
    
    CreateToggle("👻 Noclip", "Atravessar paredes", "NoclipEnabled", ToggleNoclip, tabFrames["Player"])
    CreateToggle("🦘 Pulo Infinito", "Pular infinitamente", "InfJumpEnabled", ToggleInfJump, tabFrames["Player"])
    
    CreateSlider("🏃 Velocidade", 16, 400, "WalkSpeed", function(value)
        SavedStates.WalkSpeed = value
    end, tabFrames["Player"])
    
    CreateSlider("⬆️ Força do Pulo", 50, 700, "JumpPower", function(value)
        SavedStates.JumpPower = value
    end, tabFrames["Player"])
    
    CreateToggle("🛡️ God Mode", "Vida infinita", "GodMode", ToggleGodMode, tabFrames["Player"])
    CreateToggle("👁️ Invisível", "Ficar invisível", "InvisibleEnabled", ToggleInvisible, tabFrames["Player"])
    CreateToggle("🪂 Sem Dano de Queda", "Sem dano ao cair", "NoFallDamage", ToggleNoFallDamage, tabFrames["Player"])
    
    CreateButton("💺 Sentar/Levantar", SitPlayer, tabFrames["Player"])
    CreateButton("🎩 Remover Acessórios", RemoveAccessories, tabFrames["Player"])
    CreateButton("🔄 Resetar Personagem", function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("🔄 Personagem resetado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Player"])
    
    -- ═══════════════ ABA COMBAT ═══════════════
    CreateButton("💀 Eliminar Jogador", function()
        if not SelectedPlayer or not SelectedPlayer.Parent then
            Notify("⚠️ Selecione um jogador!", CONFIG.COR_ERRO)
            return
        end
        local targetChar = SelectedPlayer.Character
        if targetChar then
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
                Notify("💀 " .. SelectedPlayer.Name .. " eliminado", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Combat"])
    
    CreateButton("🌪️ Arremessar (Fling)", FlingPlayer, tabFrames["Combat"])
    CreateButton("👔 Copiar Roupa", CopyOutfit, tabFrames["Combat"])
    
    -- ═══════════════ ABA ANIMAÇÕES ═══════════════
    CreateButton("👁️ Espectar Jogador", SpectatePlayer, tabFrames["Animações"])
    CreateButton("🚫 Parar de Espectar", StopSpectate, tabFrames["Animações"])
    CreateButton("😤 Grunhir no Jogador", GrunhirNoJogador, tabFrames["Animações"])
    CreateButton("💃 Rebolar no Jogador", RebolarNoJogador, tabFrames["Animações"])
    CreateButton("🚶 Seguir Jogador", SeguirJogador, tabFrames["Animações"])
    CreateButton("🕺 Dançar com Jogador", DancarComJogador, tabFrames["Animações"])
    
    -- ═══════════════ ABA TELEPORT ═══════════════
    CreateButton("🚀 Teleportar para Jogador", TeleportToPlayer, tabFrames["Teleport"])
    
    CreateButton("🏠 Voltar ao Spawn", function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
                if spawn then
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                else
                    root.CFrame = CFrame.new(0, 50, 0)
                end
                Notify("🏠 Teleportado para spawn", CONFIG.COR_SUCESSO)
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
    
    CreateButton("📍 Voltar à Posição", function()
        if not SavedStates.SavedPosition then
            Notify("⚠️ Nenhuma posição salva!", CONFIG.COR_ERRO)
            return
        end
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = SavedStates.SavedPosition
                Notify("📍 Teleportado!", CONFIG.COR_SUCESSO)
            end
        end
    end, tabFrames["Teleport"])
    
    -- ═══════════════ ABA ESP ═══════════════
    CreateToggle("👁️ Ativar ESP", "Liga/desliga ESP", "ESPEnabled", ToggleESP, tabFrames["ESP"])
    CreateToggle("📦 Box", "Caixas", "ESPBox", function(state)
        SavedStates.ESPBox = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📏 Linhas", "Tracers", "ESPLine", function(state)
        SavedStates.ESPLine = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📝 Nome", "Mostrar nomes", "ESPName", function(state)
        SavedStates.ESPName = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("📍 Distância", "Mostrar distância", "ESPDistance", function(state)
        SavedStates.ESPDistance = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("❤️ Vida", "Barra de vida", "ESPHealth", function(state)
        SavedStates.ESPHealth = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    CreateToggle("✨ Chams", "Destacar através de paredes", "ESPChams", function(state)
        SavedStates.ESPChams = state
        if SavedStates.ESPEnabled then
            ToggleESP(false)
            task.wait(0.1)
            ToggleESP(true)
        end
    end, tabFrames["ESP"])
    
    -- ═══════════════ ABA VISUAL ═══════════════
    CreateToggle("💡 Fullbright", "Iluminação máxima", "Fullbright", ToggleFullbright, tabFrames["Visual"])
    CreateToggle("🌫️ Remover Fog", "Remover neblina", "RemoveFog", function(state)
        SavedStates.RemoveFog = state
        Lighting.FogEnd = state and 1e10 or 1e5
        Notify(state and "🌫️ Fog removido" or "🌫️ Fog restaurado", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO)
    end, tabFrames["Visual"])
    
    CreateToggle("🌑 Remover Sombras", "Desativar sombras", "RemoveShadows", function(state)
        SavedStates.RemoveShadows = state
        Lighting.GlobalShadows = not state
        Notify(state and "🌑 Sombras removidas" or "🌑 Sombras restauradas", state and CONFIG.COR_SUCESSO or CONFIG.COR_ERRO)
    end, tabFrames["Visual"])
    
    CreateSlider("☀️ Brilho", 0, 10, "Brightness", function(value)
        SavedStates.Brightness = value
        Lighting.Brightness = value
    end, tabFrames["Visual"])
    
    CreateSlider("🔭 FOV", 70, 120, "FOV", function(value)
        SavedStates.FOV = value
        Camera.FieldOfView = value
    end, tabFrames["Visual"])
    
    -- ═══════════════ ABA CONFIG ═══════════════
    CreateToggle("🌈 Modo Rainbow", "Cores animadas", "RainbowMode", function(state)
        SavedStates.RainbowMode = state
        
        if Connections.MenuRainbow then
            Connections.MenuRainbow:Disconnect()
            Connections.MenuRainbow = nil
        end
        
        if state then
            Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
                RainbowHue = (RainbowHue + 0.003) % 1
                UpdateAllColors()
            end)
            Notify("🌈 Modo Rainbow ativado!", CONFIG.COR_SUCESSO)
        else
            SavedStates.CustomColor = nil
            UpdateAllColors()
            Notify("🌈 Modo Rainbow desativado", CONFIG.COR_ERRO)
        end
    end, tabFrames["Config"])
    
    CreateSlider("📏 Tamanho Menu", 60, 120, "MenuScale", function(value)
        SavedStates.MenuScale = value / 100
        Notify("📏 Reabra o menu (INSERT) para aplicar", CONFIG.COR_AVISO)
    end, tabFrames["Config"])
    
    local presetColors = {
        {Name = "🟣 Roxo", Color = Color3.fromRGB(139, 0, 255)},
        {Name = "🔴 Vermelho", Color = Color3.fromRGB(255, 50, 80)},
        {Name = "🔵 Azul", Color = Color3.fromRGB(50, 150, 255)},
        {Name = "🟢 Verde", Color = Color3.fromRGB(0, 255, 100)},
        {Name = "💗 Rosa", Color = Color3.fromRGB(255, 100, 200)}
    }
    
    for _, preset in ipairs(presetColors) do
        CreateButton(preset.Name, function()
            if SavedStates.RainbowMode then
                Notify("⚠️ Desative o Rainbow!", CONFIG.COR_ERRO)
                return
            end
            SavedStates.CustomColor = preset.Color
            UpdateAllColors()
            Notify("🎨 Cor alterada!", CONFIG.COR_SUCESSO)
        end, tabFrames["Config"])
    end
    
    CreateButton("📊 Estatísticas", function()
        local info = string.format([[🟣 SHAKA Hub %s
━━━━━━━━━━━━━━━━
📊 FPS: %d
👥 Jogadores: %d
⚡ Ping: %d ms]],
            CONFIG.VERSAO,
            math.floor(workspace:GetRealPhysicsFPS()),
            #Players:GetPlayers(),
            math.floor(LocalPlayer:GetNetworkPing() * 1000)
        )
        Notify(info, GetCurrentColor())
    end, tabFrames["Config"])
    
    CreateButton("🔄 Resetar Config", function()
        SavedStates.RainbowMode = false
        SavedStates.CustomColor = nil
        if Connections.MenuRainbow then
            Connections.MenuRainbow:Disconnect()
            Connections.MenuRainbow = nil
        end
        UpdateAllColors()
        Notify("🔄 Configurações resetadas!", CONFIG.COR_SUCESSO)
    end, tabFrames["Config"])
    
    -- Animação de entrada (slide da direita)
    main.Position = UDim2.new(1, 50, 0.5, -250 * scale)
    Tween(main, {Position = UDim2.new(1, -430 * scale, 0.5, -250 * scale)}, 0.4)
    
    Log("Menu carregado com sucesso!")
    Notify("🟣 SHAKA Hub " .. CONFIG.VERSAO .. " - GTA Style\nPressione INSERT para fechar/abrir", GetCurrentColor())
end

-- ════════════════════════════════════════════════════════════
-- RECARREGAR ESTADOS
-- ════════════════════════════════════════════════════════════
local function ReloadSavedStates()
    task.wait(0.5)
    
    if SavedStates.FlyEnabled then ToggleFly(true) end
    if SavedStates.NoclipEnabled then ToggleNoclip(true) end
    if SavedStates.InfJumpEnabled then ToggleInfJump(true) end
    if SavedStates.GodMode then ToggleGodMode(true) end
    if SavedStates.ESPEnabled then ToggleESP(true) end
    if SavedStates.Fullbright then ToggleFullbright(true) end
    if SavedStates.RemoveFog then Lighting.FogEnd = 1e10 end
    if SavedStates.RemoveShadows then Lighting.GlobalShadows = false end
    if SavedStates.InvisibleEnabled then ToggleInvisible(true) end
    if SavedStates.NoFallDamage then ToggleNoFallDamage(true) end
    
    Camera.FieldOfView = SavedStates.FOV
    Lighting.Brightness = SavedStates.Brightness
    
    if SavedStates.RainbowMode then
        if Connections.MenuRainbow then Connections.MenuRainbow:Disconnect() end
        Connections.MenuRainbow = RunService.Heartbeat:Connect(function()
            RainbowHue = (RainbowHue + 0.003) % 1
            UpdateAllColors()
        end)
    end
end

-- ════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ════════════════════════════════════════════════════════════
Log("════════════════════════════════════════")
Log("  🟣 SHAKA Hub Premium " .. CONFIG.VERSAO)
Log("  🎮 GTA Style Edition")
Log("════════════════════════════════════════")

task.wait(0.3)
CreateGUI()
ReloadSavedStates()

-- ════════════════════════════════════════════════════════════
-- CONTROLES
-- ════════════════════════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        if GUI then
            local main = GUI:FindFirstChild("Main")
            if main then
                Tween(main, {Position = UDim2.new(1, 50, 0.5, -250)}, 0.3)
                task.wait(0.3)
            end
            GUI:Destroy()
            GUI = nil
            Log("Menu fechado")
        else
            CreateGUI()
            ReloadSavedStates()
            Log("Menu aberto")
        end
    end
end)

-- ════════════════════════════════════════════════════════════
-- EVENTOS
-- ════════════════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ReloadSavedStates()
end)

Players.PlayerAdded:Connect(function(player)
    if SavedStates.ESPEnabled then
        task.wait(1)
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Chams then
                for _, highlight in pairs(esp.Chams) do
                    highlight:Destroy()
                end
            end
        end)
        ESPObjects[player] = nil
    end
    
    if SelectedPlayer == player then
        SelectedPlayer = nil
    end
end)

Log("✅ Sistema carregado!")
Log("⌨️  Pressione INSERT para abrir/fechar")
Log("🎨 Design estilo GTA RP")
Log("💃 Novas animações e trollagens")
Log("👁️ ESP melhorado e customizável")
Log("📐 Menu compacto e otimizado")
Log("════════════════════════════════════════")-- SHAKA Hub Premium v9.0 - GTA Style Edition
-- Design estilo GTA RP | Sistema Completo | Ultra Otimizado
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
    VERSAO = "v9.0",
    COR_ROXO = Color3.fromRGB(139, 0, 255),
    COR_FUNDO = Color3.fromRGB(12, 12, 16),
    COR_FUNDO_2 = Color3.fromRGB(18, 18, 24),
    COR_FUNDO_3 = Color3.fromRGB(24, 24, 32),
    COR_TEXTO = Color3.fromRGB(255, 255, 255),
    COR_TEXTO_SEC = Color3.fromRGB(160, 160, 170),
    COR_SUCESSO = Color3.fromRGB(0, 255, 100),
    COR_ERRO = Color3.fromRGB(255, 50, 80),
    COR_AVISO = Color3.fromRGB(255, 200, 0)
}

-- ════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ════════════════════════════════════════════════════════════
local GUI = nil
local Connections = {}
local SelectedPlayer = nil
local RainbowHue = 0
local UIElements = {}

local SavedStates = {
    -- Player
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    WalkSpeed = 16,
    JumpPower = 50,
    GodMode = false,
    InvisibleEnabled = false,
    NoFallDamage = false,
    SwimSpeedMultiplier = 1,
    
    -- ESP
    ESPEnabled = false,
    ESPBox = true,
    ESPLine = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    ESPChams = false,
    ESPColor = Color3.fromRGB(255, 0, 255),
    
    -- Visual
    Fullbright = false,
    RemoveFog = false,
    RemoveShadows = false,
    FOV = 70,
    Brightness = 1,
    
    -- Config
    RainbowMode = false,
    CustomColor = nil,
    MenuScale = 1
}

local ESPObjects = {}

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE COR
-- ════════════════════════════════════════════════════════════
local function GetCurrentColor()
    if SavedStates.RainbowMode then
        return Color3.fromHSV(RainbowHue, 1, 1)
    elseif SavedStates.CustomColor then
        return SavedStates.CustomColor
    else
        return CONFIG.COR_ROXO
    end
end

local function UpdateAllColors()
    if not GUI then return end
    local currentColor = GetCurrentColor()
    
    for _, element in pairs(UIElements) do
        if element and element.Parent then
            pcall(function()
                if element:GetAttribute("ColorUpdate") then
                    TweenService:Create(element, TweenInfo.new(0.2), {BackgroundColor3 = currentColor}):Play()
                elseif element:GetAttribute("TextColorUpdate") then
                    TweenService:Create(element, TweenInfo.new(0.2), {TextColor3 = currentColor}):Play()
                elseif element:IsA("UIStroke") then
                    TweenService:Create(element, TweenInfo.new(0.2), {Color = currentColor}):Play()
                end
            end)
        end
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
        notif.Size = UDim2.new(0, 300, 0, 70)
        notif.Position = UDim2.new(1, -310, 1, 10)
        notif.BackgroundColor3 = CONFIG.COR_FUNDO_2
        notif.BorderSizePixel = 0
        notif.Parent = GUI
        notif.ZIndex = 1000
        
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)
        
        local stroke = Instance.new("UIStroke", notif)
        stroke.Color = color or GetCurrentColor()
        stroke.Thickness = 2
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 45, 0, 45)
        icon.Position = UDim2.new(0, 12, 0.5, -22.5)
        icon.BackgroundColor3 = color or GetCurrentColor()
        icon.Text = color == CONFIG.COR_SUCESSO and "✓" or (color == CONFIG.COR_ERRO and "✕" or "!")
        icon.TextColor3 = CONFIG.COR_TEXTO
        icon.TextSize = 24
        icon.Font = Enum.Font.GothamBold
        icon.BorderSizePixel = 0
        icon.Parent = notif
        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 1, -10)
        label.Position = UDim2.new(0, 62, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = CONFIG.COR_TEXTO
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextWrapped = true
        label.Parent = notif
        
        Tween(notif, {Position = UDim2.new(1, -310, 1, -80)}, 0.3)
        task.wait(3.5)
        Tween(notif, {Position = UDim2.new(1, 10, 1, -80)}, 0.3)
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
    if not root then return end
    
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
            
            if bodyVelocity and bodyVelocity.Parent then
                bodyVelocity.Velocity = moveVector
            end
            if bodyGyro and bodyGyro.Parent then
                bodyGyro.CFrame = Camera.CFrame
            end
        end)
        
        Notify("✈️ Fly ativado! Use WASD + Space/Shift", CONFIG.COR_SUCESSO)
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
                if humanoid and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end
        end)
        Notify("🛡️ God Mode ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🛡️ God Mode desativado", CONFIG.COR_ERRO)
    end
end

local function ToggleInvisible(state)
    SavedStates.InvisibleEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    
    if state then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
                if part.Name == "Head" then
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then face.Transparency = 1 end
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 1 end
            end
        end
        Notify("👻 Você está invisível!", CONFIG.COR_SUCESSO)
    else
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
                if part.Name == "Head" then
                    local face = part:FindFirstChildOfClass("Decal")
                    if face then face.Transparency = 0 end
                end
            elseif part:IsA("Accessory") then
                local handle = part:FindFirstChild("Handle")
                if handle then handle.Transparency = 0 end
            end
        end
        Notify("👤 Visível novamente", CONFIG.COR_ERRO)
    end
end

local function ToggleNoFallDamage(state)
    SavedStates.NoFallDamage = state
    
    if Connections.NoFall then
        Connections.NoFall:Disconnect()
        Connections.NoFall = nil
    end
    
    if state then
        Connections.NoFall = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local falling = humanoid:GetState() == Enum.HumanoidStateType.Freefall
                    if falling then
                        humanoid:ChangeState(Enum.HumanoidStateType.Flying)
                    end
                end
            end
        end)
        Notify("🪂 Sem dano de queda ativado", CONFIG.COR_SUCESSO)
    else
        Notify("🪂 Sem dano de queda desativado", CONFIG.COR_ERRO)
    end
end

local function RemoveAccessories()
    local char = LocalPlayer.Character
    if char then
        for _, item in pairs(char:GetChildren()) do
            if item:IsA("Accessory") then
                item:Destroy()
            end
        end
        Notify("🎩 Acessórios removidos", CONFIG.COR_SUCESSO)
    end
end

local function SitPlayer()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = not humanoid.Sit
            Notify(humanoid.Sit and "💺 Sentado" or "🚶 Em pé", CONFIG.COR_SUCESSO)
        end
    end
end

-- Manter velocidade e pulo
task.spawn(function()
    while true do
        pcall(function()
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
        end)
        task.wait(0.1)
    end
end)

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE TELEPORTE
-- ════════════════════════════════════════════════════════════
local function TeleportToPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador válido!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
        Notify("🚀 Teleportado para " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
    else
        Notify("❌ Erro ao teleportar", CONFIG.COR_ERRO)
    end
end

-- ════════════════════════════════════════════════════════════
-- FUNÇÕES DE ANIMAÇÃO/TROLL
-- ════════════════════════════════════════════════════════════
local function SpectatePlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    Camera.CameraSubject = SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")
    Notify("👁️ Espectando " .. SelectedPlayer.Name .. "\nPressione ESC para parar", CONFIG.COR_SUCESSO)
end

local function StopSpectate()
    Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    Notify("👁️ Espectação parada", CONFIG.COR_ERRO)
end

local function GrunhirNoJogador()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end
    
    -- Fazer o personagem gruñir (movimento de cabeça)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for i = 1, 5 do
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2) * CFrame.Angles(0, math.rad(180), 0)
            task.wait(0.3)
            root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2) * CFrame.Angles(0, math.rad(180), math.rad(30))
            task.wait(0.3)
        end
    end
    
    Notify("😤 Grunhindo em " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
end

local function RebolarNoJogador()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    if Connections.Rebolar then
        Connections.Rebolar:Disconnect()
        Connections.Rebolar = nil
        Notify("💃 Parou de rebolar", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end
    
    Connections.Rebolar = RunService.Heartbeat:Connect(function()
        if not targetChar or not targetChar.Parent then
            Connections.Rebolar:Disconnect()
            Connections.Rebolar = nil
            return
        end
        
        local angle = tick() * 10
        root.CFrame = targetRoot.CFrame * CFrame.new(math.sin(angle) * 2, 0, -3) * CFrame.Angles(0, math.rad(180), math.sin(angle * 2) * 0.5)
    end)
    
    Notify("💃 Rebolando em " .. SelectedPlayer.Name .. "!\nClique novamente para parar", CONFIG.COR_SUCESSO)
end

local function SeguirJogador()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    if Connections.Seguir then
        Connections.Seguir:Disconnect()
        Connections.Seguir = nil
        Notify("🚶 Parou de seguir", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end
    
    Connections.Seguir = RunService.Heartbeat:Connect(function()
        if not targetChar or not targetChar.Parent then
            Connections.Seguir:Disconnect()
            Connections.Seguir = nil
            return
        end
        
        root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    end)
    
    Notify("🚶 Seguindo " .. SelectedPlayer.Name .. "!\nClique novamente para parar", CONFIG.COR_SUCESSO)
end

local function DancarComJogador()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    if Connections.Dancar then
        Connections.Dancar:Disconnect()
        Connections.Dancar = nil
        Notify("🕺 Parou de dançar", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then return end
    
    Connections.Dancar = RunService.Heartbeat:Connect(function()
        if not targetChar or not targetChar.Parent then
            Connections.Dancar:Disconnect()
            Connections.Dancar = nil
            return
        end
        
        local angle = tick() * 5
        local radius = 4
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        
        root.CFrame = targetRoot.CFrame * CFrame.new(x, 0, z) * CFrame.Angles(0, -angle, 0)
    end)
    
    Notify("🕺 Dançando com " .. SelectedPlayer.Name .. "!\nClique novamente para parar", CONFIG.COR_SUCESSO)
end

local function CopyOutfit()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador primeiro!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            item:Destroy()
        end
    end
    
    for _, item in pairs(targetChar:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") then
            local clone = item:Clone()
            clone.Parent = char
        end
    end
    
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            local targetPart = targetChar:FindFirstChild(part.Name)
            if targetPart and targetPart:IsA("BasePart") then
                part.BrickColor = targetPart.BrickColor
                part.Color = targetPart.Color
            end
        end
    end
    
    Notify("👔 Roupa copiada de " .. SelectedPlayer.Name, CONFIG.COR_SUCESSO)
end

local function FlingPlayer()
    if not SelectedPlayer or not SelectedPlayer.Parent then
        Notify("⚠️ Selecione um jogador válido!", CONFIG.COR_ERRO)
        return
    end
    
    local char = LocalPlayer.Character
    local targetChar = SelectedPlayer.Character
    
    if not char or not targetChar then
        Notify("❌ Personagens não encontrados", CONFIG.COR_ERRO)
        return
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not targetRoot then
        Notify("❌ Erro ao arremessar", CONFIG.COR_ERRO)
        return
    end
    
    local originalPos = root.CFrame
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.Massless = true
        end
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root
    
    for i = 1, 5 do
        root.CFrame = targetRoot.CFrame
        bodyVelocity.Velocity = Vector3.new(
            math.random(-100, 100),
            math.random(100, 200),
            math.random(-100, 100)
        )
        task.wait(0.1)
    end
    
    bodyVelocity:Destroy()
    root.CFrame = originalPos
    
    task.wait(0.5)
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
            part.Massless = false
        end
    end
    
    Notify("🌪️ " .. SelectedPlayer.Name .. " arremessado!", CONFIG.COR_SUCESSO)
end

-- ════════════════════════════════════════════════════════════
-- SISTEMA DE ESP (MELHORADO E BONITO)
-- ════════════════════════════════════════════════════════════
local function ClearESP()
    for _, esp in pairs(ESPObjects) do
        pcall(function()
            if esp.Box then esp.Box:Remove() end
            if esp.Line then esp.Line:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.Health then esp.Health:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Chams then esp.Chams:Destroy() end
        end)
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
        Health = nil,
        HealthBar = nil,
        HealthBarBG = nil,
        Chams = nil
    }
    
    -- Box moderno com gradiente
    if SavedStates.ESPBox then
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = 2
        esp.Box.Filled = false
        esp.Box.Color = SavedStates.ESP
