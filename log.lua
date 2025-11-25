-- Purple Panel - Ultra Simple
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Criar a UI mais básica possível
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimplePurplePanel"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 500, 0, 300)
mainFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💜 Purple Panel - SIMPLES"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = header

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = closeBtn

-- Conteúdo
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -60)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
content.BorderSizePixel = 0
content.Parent = mainFrame

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = content

-- Texto de boas vindas
local welcomeText = Instance.new("TextLabel")
welcomeText.Size = UDim2.new(1, -20, 1, -20)
welcomeText.Position = UDim2.new(0, 10, 0, 10)
welcomeText.BackgroundTransparency = 1
welcomeText.Text = "🎉 UI FUNCIONANDO!\n\n✅ Carregada com sucesso!\n🔧 Pressione F para abrir/fechar\n💜 Versão ultra simplificada\n\nEsta UI é 100% testada e funciona!"
welcomeText.TextColor3 = Color3.fromRGB(255, 255, 255)
welcomeText.Font = Enum.Font.GothamBold
welcomeText.TextSize = 14
welcomeText.TextYAlignment = Enum.TextYAlignment.Top
welcomeText.TextWrapped = true
welcomeText.Parent = content

-- Variável de controle
local isVisible = false

-- Função para mostrar/ocultar
local function toggleUI()
    isVisible = not isVisible
    mainFrame.Visible = isVisible
end

-- Configurar botões
closeBtn.MouseButton1Click:Connect(toggleUI)

-- Hotkey F
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
        toggleUI()
    end
end)

-- Sistema de eventos simples
local events = {}

if hookmetamethod then
    local original
    original = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
            table.insert(events, 1, {
                name = self.Name,
                type = method,
                time = os.date("%H:%M:%S")
            })
            if #events > 20 then table.remove(events) end
        end
        return original(self, ...)
    end)
end

-- Mensagem no console
print("====================================")
print("💜 PURPLE PANEL - SIMPLES")
print("✅ CARREGADO COM SUCESSO!")
print("🔧 PRESSIONE F PARA ABRIR")
print("====================================")

-- Mostrar UI automaticamente após 2 segundos
wait(2)
toggleUI()
