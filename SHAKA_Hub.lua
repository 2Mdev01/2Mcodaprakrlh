-- SHAKA Hub - Loader Premium
local PlaceId = game.PlaceId

-- Configurações Premium SHAKA Hub
local HUB_CONFIG = {
    NOME = "SHAKA",
    COR_PRINCIPAL = Color3.fromRGB(128, 0, 128),
    COR_SECUNDARIA = Color3.fromRGB(0, 0, 0),
    VERSAO = "v3.0 Premium",
    AUTOR = "Malik Siqueira"
}

-- Lista de jogos suportados
local JogosSuportados = {
    ["Blox Fruits"] = {
        Ids = {2753915549, 7449423635},
        Url = "https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/BloxFruits"
    },
    ["King Legacy"] = {
        Ids = {4520749081},
        Url = "https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/king%20legacy"
    },
    ["Pet Simulator 99"] = {
        Ids = {8737899170},
        Url = "https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/PetSimulator99"
    }
}

local URL_RESERVA = "https://raw.githubusercontent.com/Tsuo7/TsuoHub/main/Universal"

-- Sistema de logging
local function Log(mensagem, tipo)
    local prefixos = {
        sucesso = "🟣 [SHAKA] ✅ ",
        erro = "🟣 [SHAKA] ❌ ",
        info = "🟣 [SHAKA] 🔷 ",
        aviso = "🟣 [SHAKA] ⚠️ "
    }
    print((prefixos[tipo] or "🟣 [SHAKA] ") .. mensagem)
end

-- Detector de jogos
local function DetectarJogo()
    Log("Procurando jogo... PlaceId: " .. PlaceId, "info")
    
    for nomeJogo, dados in pairs(JogosSuportados) do
        for _, id in ipairs(dados.Ids) do
            if id == PlaceId then
                Log("Jogo encontrado: " .. nomeJogo, "sucesso")
                return dados.Url, nomeJogo
            end
        end
    end
    
    Log("Jogo não suportado", "aviso")
    return nil, "Universal"
end

-- Carregador de scripts
local function CarregarScript(url)
    if not url then
        Log("URL inválida", "erro")
        return false
    end
    
    Log("Baixando script: " .. url, "info")
    
    local sucesso, conteudo = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not sucesso then
        Log("Falha ao baixar", "erro")
        return false
    end
    
    -- Personalizar conteúdo
    local conteudoModificado = conteudo:gsub("Tsuo Hub", "SHAKA Hub")
                                      :gsub("TsuoHub", "SHAKAHub")
                                      :gsub("Tsuo", "SHAKA")
    
    local execSucesso, erroExec = pcall(function()
        loadstring(conteudoModificado)()
    end)
    
    if execSucesso then
        Log("Script carregado com sucesso!", "sucesso")
        return true
    else
        Log("Erro: " .. tostring(erroExec), "erro")
        return false
    end
end

-- Interface inicial
local function MostrarBanner()
    Log("══════════════════════════════════", "info")
    Log("🎮 SHAKA HUB PREMIUM v3.0", "sucesso")
    Log("🎨 Cores: Preto & Roxo Forte", "info")
    Log("👨‍💻 Por: Malik Siqueira", "info")
    Log("══════════════════════════════════", "info")
end

-- Função principal
local function IniciarSHAKA()
    MostrarBanner()
    
    local urlScript, nomeJogo = DetectarJogo()
    
    if urlScript then
        if not CarregarScript(urlScript) then
            Log("Tentando script universal...", "aviso")
            CarregarScript(URL_RESERVA)
        end
    else
        Log("Carregando modo universal...", "info")
        CarregarScript(URL_RESERVA)
    end
end

-- Iniciar
wait(2)
IniciarSHAKA()
