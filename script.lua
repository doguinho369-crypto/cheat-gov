--[[
    KGS SCRIPTS v5 | Governo Brasileiro BR
    Design futurista | 5 abas
]]

local Players        = game:GetService("Players")
local UIS            = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local StarterGui     = game:GetService("StarterGui")
local Lighting       = game:GetService("Lighting")
local TweenService   = game:GetService("TweenService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ══════════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════════
local CFG = {
    speed    = 18,
    distStop = 3.5,
    cooldown = 65,
    delayMin = 1.2,
    delayMax = 2.8,
    preMin   = 0.3,
    preMax   = 0.9,
}
local SPEED_CAP = 26

local autoFarm   = false
local espAtivo   = false
local espCD      = false   -- mostrar cooldown diferenciado
local espNames   = false   -- nome em cima do NPC
local antiAfk    = false
local highlights = {}
local cooldowns  = {}
local afkConn    = nil

local function rand(a, b) return a + math.random()*(b-a) end
local function emCooldown(npc)
    local t = cooldowns[npc.Name]
    return t and (tick()-t) < CFG.cooldown
end
local function tempoRestante(npc)
    local t = cooldowns[npc.Name]
    if not t then return 0 end
    return math.max(0, math.ceil(CFG.cooldown-(tick()-t)))
end
local function getNPCs()
    local p = workspace:FindFirstChild("PopulacaoNPC")
    return p and p:GetChildren() or {}
end
local function getNPCMaisProximo()
    local best, bestD = nil, math.huge
    for _, npc in ipairs(getNPCs()) do
        if emCooldown(npc) then continue end
        local r = npc:FindFirstChild("HumanoidRootPart")
        if r then
            local d = (r.Position-hrp.Position).Magnitude
            if d < bestD then bestD=d best=npc end
        end
    end
    return best
end

-- ══════════════════════════════════════════
--  FARM
-- ══════════════════════════════════════════
local function dispararPrompt(npc)
    local root = npc:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local prompt = root:FindFirstChild("ConversarPrompt")
    if not prompt then return end
    task.wait(rand(CFG.preMin, CFG.preMax))
    local ok = pcall(fireproximityprompt, prompt)
    if not ok then pcall(function()
        prompt:InputHoldBegin() task.wait(0.15) prompt:InputHoldEnd()
    end) end
end

local function farmLoop()
    while autoFarm do
        task.wait(0.2)
        if not hrp or not hum or hum.Health <= 0 then task.wait(2) continue end
        local npc = getNPCMaisProximo()
        if not npc then task.wait(2) continue end
        local root = npc:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        hum.WalkSpeed = math.min(CFG.speed + rand(-2,2), SPEED_CAP)
        local t0 = tick()
        local chegou = false
        while autoFarm and tick()-t0 < 15 do
            if not root.Parent then break end
            if (hrp.Position-root.Position).Magnitude <= CFG.distStop then chegou=true break end
            hum:MoveTo(root.Position)
            task.wait(0.1)
        end
        if not autoFarm then break end
        if chegou then
            dispararPrompt(npc)
            cooldowns[npc.Name] = tick()
            task.wait(rand(CFG.delayMin, CFG.delayMax))
        end
    end
    if hum then hum.WalkSpeed = 16 end
end

-- ══════════════════════════════════════════
--  ESP
-- ══════════════════════════════════════════
local billboards = {}

local function atualizarHighlights()
    for _, npc in ipairs(getNPCs()) do
        -- SelectionBox
        if espAtivo then
            if not highlights[npc] then
                local hl = Instance.new("SelectionBox")
                hl.Adornee = npc
                hl.LineThickness = 0.06
                hl.SurfaceTransparency = 0.75
                hl.Parent = workspace.CurrentCamera
                highlights[npc] = hl
            end
            local hl = highlights[npc]
            if emCooldown(npc) then
                hl.Color3 = Color3.fromRGB(220,100,20)
                hl.SurfaceColor3 = Color3.fromRGB(100,40,10)
            else
                hl.Color3 = Color3.fromRGB(130,50,255)
                hl.SurfaceColor3 = Color3.fromRGB(60,15,140)
            end
        else
            if highlights[npc] then highlights[npc]:Destroy() highlights[npc]=nil end
        end

        -- BillboardGui (nome + distância)
        if espNames then
            if not billboards[npc] then
                local root = npc:FindFirstChild("HumanoidRootPart")
                if root then
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0,120,0,36)
                    bb.StudsOffset = Vector3.new(0,3,0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = root
                    bb.Parent = workspace.CurrentCamera
                    local lbl = Instance.new("TextLabel", bb)
                    lbl.Size = UDim2.new(1,0,1,0)
                    lbl.BackgroundTransparency = 1
                    lbl.TextColor3 = Color3.new(1,1,1)
                    lbl.TextSize = 13
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextStrokeTransparency = 0
                    lbl.TextStrokeColor3 = Color3.fromRGB(80,0,160)
                    lbl.Name = "Label"
                    billboards[npc] = bb
                end
            end
            local bb = billboards[npc]
            if bb then
                local lbl = bb:FindFirstChild("Label")
                if lbl then
                    local root = npc:FindFirstChild("HumanoidRootPart")
                    local d = root and math.floor((root.Position-hrp.Position).Magnitude) or "?"
                    local cd = emCooldown(npc) and " ⏱"..tempoRestante(npc).."s" or " ✓"
                    lbl.Text = npc.Name.."\n"..d.."m"..cd
                    lbl.TextColor3 = emCooldown(npc)
                        and Color3.fromRGB(220,120,40)
                        or Color3.fromRGB(160,100,255)
                end
            end
        else
            if billboards[npc] then billboards[npc]:Destroy() billboards[npc]=nil end
        end
    end
end

-- ══════════════════════════════════════════
--  ANTI-AFK
-- ══════════════════════════════════════════
local function ligarAntiAfk()
    afkConn = RunService.Heartbeat:Connect(function()
        -- simula input virtual para não ser kickado
        local v = VirtualUser
        if v then
            pcall(function() v:CaptureController() v:ClickButton2(Vector2.new()) end)
        end
    end)
    -- fallback: rotaciona câmera levemente a cada 4min
    task.spawn(function()
        while antiAfk do
            task.wait(240)
            if not antiAfk then break end
            local cam = workspace.CurrentCamera
            if cam then
                cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(1), 0)
            end
        end
    end)
end
local function desligarAntiAfk()
    if afkConn then afkConn:Disconnect() afkConn=nil end
end

-- ══════════════════════════════════════════
--  OTIMIZAÇÃO
-- ══════════════════════════════════════════
local otimizacoes = {
    shadows    = false,
    particles  = false,
    textures   = false,
    outros     = false,
}
local removidos = {particles={}, textures={}}

local function toggleShadows(on)
    Lighting.GlobalShadows = on
end
local function toggleParticles(on)
    if not on then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke")
            or v:IsA("Fire") or v:IsA("Sparkles") then
                table.insert(removidos.particles, {obj=v, prop="Enabled", val=v.Enabled})
                v.Enabled = false
            end
        end
    else
        for _, info in ipairs(removidos.particles) do
            pcall(function() info.obj.Enabled = info.val end)
        end
        removidos.particles = {}
    end
end
local function toggleTextures(on)
    if not on then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Decal") or v:IsA("Texture") then
                table.insert(removidos.textures, {obj=v, prop="Transparency", val=v.Transparency})
                v.Transparency = 1
            end
        end
    else
        for _, info in ipairs(removidos.textures) do
            pcall(function() info.obj.Transparency = info.val end)
        end
        removidos.textures = {}
    end
end
local function toggleOutros(on)
    -- remove renderização de outros jogadores
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == lp then continue end
        if pl.Character then
            for _, part in ipairs(pl.Character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    pcall(function() part.LocalTransparencyModifier = on and 0 or 1 end)
                end
            end
        end
    end
end

-- ══════════════════════════════════════════
--  GUI — ESTRUTURA
-- ══════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name = "KGS_V5"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = lp.PlayerGui

-- paleta
local P = {
    bg0   = Color3.fromRGB(8,  3,  18),   -- fundo mais escuro
    bg1   = Color3.fromRGB(14, 5,  28),   -- fundo painel
    bg2   = Color3.fromRGB(22, 8,  42),   -- fundo card
    top   = Color3.fromRGB(38, 10, 80),   -- topbar
    acc1  = Color3.fromRGB(120, 40, 255), -- roxo principal
    acc2  = Color3.fromRGB(180, 80, 255), -- roxo claro
    acc3  = Color3.fromRGB(220,160, 255), -- lavanda
    glow  = Color3.fromRGB(80, 20, 180),  -- brilho
    white = Color3.new(1,1,1),
    sub   = Color3.fromRGB(160,120,220),
    dim   = Color3.fromRGB(90, 60,140),
    green = Color3.fromRGB(80,220,120),
    orange= Color3.fromRGB(220,120,40),
}

-- janela principal
local win = Instance.new("Frame", sg)
win.Size = UDim2.new(0, 440, 0, 380)
win.Position = UDim2.new(0.5,-220,0.5,-190)
win.BackgroundColor3 = P.bg1
win.BorderSizePixel = 0
win.Active = true
local winC = Instance.new("UICorner",win) winC.CornerRadius = UDim.new(0,14)
local winS = Instance.new("UIStroke",win)
winS.Color = P.acc1 winS.Thickness = 1.5

-- gradiente de fundo
local grad = Instance.new("UIGradient", win)
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, P.bg1),
    ColorSequenceKeypoint.new(1, P.bg0),
}
grad.Rotation = 135

-- topbar
local topbar = Instance.new("Frame", win)
topbar.Size = UDim2.new(1,0,0,42)
topbar.BackgroundColor3 = P.top
topbar.BorderSizePixel = 0
local topC = Instance.new("UICorner",topbar) topC.CornerRadius = UDim.new(0,14)
local topFix = Instance.new("Frame",topbar) -- cobre cantos inferiores do topbar
topFix.Size = UDim2.new(1,0,0.5,0)
topFix.Position = UDim2.new(0,0,0.5,0)
topFix.BackgroundColor3 = P.top
topFix.BorderSizePixel = 0

-- linha brilhante embaixo do topbar
local topLine = Instance.new("Frame", topbar)
topLine.Size = UDim2.new(1,0,0,1)
topLine.Position = UDim2.new(0,0,1,-1)
topLine.BackgroundColor3 = P.acc1
topLine.BorderSizePixel = 0
local tlGrad = Instance.new("UIGradient", topLine)
tlGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0,0,0)),
    ColorSequenceKeypoint.new(0.3, P.acc2),
    ColorSequenceKeypoint.new(0.7, P.acc2),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
}

-- logo
local logo = Instance.new("TextLabel", topbar)
logo.Size = UDim2.new(1,-80,1,0)
logo.Position = UDim2.new(0,16,0,0)
logo.BackgroundTransparency = 1
logo.Text = "✦ KGS SCRIPTS"
logo.TextColor3 = P.white
logo.TextSize = 15
logo.Font = Enum.Font.GothamBold
logo.TextXAlignment = Enum.TextXAlignment.Left

-- versão
local ver = Instance.new("TextLabel", topbar)
ver.Size = UDim2.new(0,60,0,14)
ver.Position = UDim2.new(0,16,1,-16)
ver.BackgroundTransparency = 1
ver.Text = "v5.0 • GovBR"
ver.TextColor3 = P.dim
ver.TextSize = 9
ver.Font = Enum.Font.Gotham
ver.TextXAlignment = Enum.TextXAlignment.Left

-- botões topbar
local function mkTopBtn(txt, xOff)
    local b = Instance.new("TextButton", topbar)
    b.Size = UDim2.new(0,28,0,22)
    b.Position = UDim2.new(1,xOff,0.5,-11)
    b.BackgroundColor3 = P.bg0
    b.TextColor3 = P.sub
    b.Text = txt
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end
local bClose = mkTopBtn("✕", -10)
local bMin   = mkTopBtn("—", -44)

-- ══════════════════════════════════════════
--  ABAS
-- ══════════════════════════════════════════
local ABA_NOMES = {"⚡ Farm", "👁 ESP", "⚙ Optim.", "🛡 Misc", "ℹ Info"}
local abaAtiva  = 1
local abaFrames = {}
local abaBtns   = {}

-- barra de abas
local abaBar = Instance.new("Frame", win)
abaBar.Size = UDim2.new(1,-16,0,32)
abaBar.Position = UDim2.new(0,8,0,48)
abaBar.BackgroundTransparency = 1

local abaLayout = Instance.new("UIListLayout", abaBar)
abaLayout.FillDirection = Enum.FillDirection.Horizontal
abaLayout.Padding = UDim.new(0,4)
abaLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- área de conteúdo
local content = Instance.new("Frame", win)
content.Size = UDim2.new(1,-16,1,-92)
content.Position = UDim2.new(0,8,0,86)
content.BackgroundTransparency = 1

local function mkAbaBtn(nome, idx)
    local b = Instance.new("TextButton", abaBar)
    b.Size = UDim2.new(0, 76, 1, 0)
    b.BackgroundColor3 = P.bg2
    b.TextColor3 = P.dim
    b.Text = nome
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.LayoutOrder = idx
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    local s = Instance.new("UIStroke",b)
    s.Color = P.glow s.Thickness = 1
    return b, s
end

local function mkAbaFrame()
    local f = Instance.new("ScrollingFrame", content)
    f.Size = UDim2.new(1,0,1,0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ScrollBarThickness = 3
    f.ScrollBarImageColor3 = P.acc1
    f.CanvasSize = UDim2.new(0,0,0,0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.Visible = false
    local layout = Instance.new("UIListLayout", f)
    layout.Padding = UDim.new(0,6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    return f
end

for i, nome in ipairs(ABA_NOMES) do
    local btn, stroke = mkAbaBtn(nome, i)
    local frame = mkAbaFrame()
    abaBtns[i] = {btn=btn, stroke=stroke}
    abaFrames[i] = frame
    btn.MouseButton1Click:Connect(function()
        abaAtiva = i
        for j, ab in ipairs(abaBtns) do
            if j == i then
                ab.btn.BackgroundColor3 = P.glow
                ab.btn.TextColor3 = P.white
                ab.stroke.Color = P.acc2
                ab.stroke.Thickness = 1.5
            else
                ab.btn.BackgroundColor3 = P.bg2
                ab.btn.TextColor3 = P.dim
                ab.stroke.Color = P.glow
                ab.stroke.Thickness = 1
            end
        end
        for j, fr in ipairs(abaFrames) do
            fr.Visible = (j == i)
        end
    end)
end

-- ativa aba 1
abaBtns[1].btn.BackgroundColor3 = P.glow
abaBtns[1].btn.TextColor3 = P.white
abaBtns[1].stroke.Color = P.acc2
abaBtns[1].stroke.Thickness = 1.5
abaFrames[1].Visible = true

-- ══════════════════════════════════════════
--  HELPERS DE WIDGETS
-- ══════════════════════════════════════════
local function mkCard(parent, order)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1,0,0,0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = P.bg2
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    local cc = Instance.new("UICorner",card) cc.CornerRadius = UDim.new(0,8)
    local cs = Instance.new("UIStroke",card) cs.Color = P.glow cs.Thickness = 1
    local cp = Instance.new("UIPadding",card)
    cp.PaddingLeft = UDim.new(0,10)
    cp.PaddingRight = UDim.new(0,10)
    cp.PaddingTop = UDim.new(0,8)
    cp.PaddingBottom = UDim.new(0,8)
    local cl = Instance.new("UIListLayout",card)
    cl.Padding = UDim.new(0,6)
    cl.SortOrder = Enum.SortOrder.LayoutOrder
    return card
end

local function mkLabel(parent, txt, fs, cor, order)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,0,0,fs and fs+2 or 14)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = cor or P.sub
    l.TextSize = fs or 11
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 99
    return l
end

local function mkSectionTitle(parent, txt, order)
    local l = Instance.new("TextLabel", parent)
    l.Size = UDim2.new(1,0,0,16)
    l.BackgroundTransparency = 1
    l.Text = "▸ "..txt
    l.TextColor3 = P.acc2
    l.TextSize = 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0
    return l
end

local function mkToggle(parent, txt, default, order, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1,-52,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = P.sub
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(0,42,0,22)
    track.Position = UDim2.new(1,-42,0.5,-11)
    track.BackgroundColor3 = default and P.acc1 or P.bg0
    track.BorderSizePixel = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)
    local ts = Instance.new("UIStroke",track) ts.Color = P.glow ts.Thickness = 1

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,16,0,16)
    thumb.Position = default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
    thumb.BackgroundColor3 = P.white
    thumb.BorderSizePixel = 0
    Instance.new("UICorner",thumb).CornerRadius = UDim.new(1,0)

    local state = default or false
    local btn = Instance.new("TextButton", row)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and P.acc1 or P.bg0
        }):Play()
        TweenService:Create(thumb, TweenInfo.new(0.15), {
            Position = state
                and UDim2.new(1,-19,0.5,-8)
                or  UDim2.new(0,3,0.5,-8)
        }):Play()
        if onChange then onChange(state) end
    end)
    return row
end

local function mkSlider(parent, txt, min, max, default, order, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,46)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.7,0,0,16)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = P.sub
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", row)
    valLbl.Size = UDim2.new(0.3,0,0,16)
    valLbl.Position = UDim2.new(0.7,0,0,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = P.acc2
    valLbl.TextSize = 11
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", row)
    track.Size = UDim2.new(1,0,0,6)
    track.Position = UDim2.new(0,0,0,24)
    track.BackgroundColor3 = P.bg0
    track.BorderSizePixel = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke",track).Color = P.glow

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = P.acc1
    fill.BorderSizePixel = 0
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0,14,0,14)
    thumb.Position = UDim2.new((default-min)/(max-min),0,0.5,-7)
    thumb.AnchorPoint = Vector2.new(0.5,0)
    thumb.BackgroundColor3 = P.white
    thumb.BorderSizePixel = 0
    Instance.new("UICorner",thumb).CornerRadius = UDim.new(1,0)

    local draggingSlider = false
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not draggingSlider then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs = track.AbsolutePosition
        local sz  = track.AbsoluteSize
        local rel = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
        local val = math.floor(min + rel*(max-min))
        fill.Size = UDim2.new(rel,0,1,0)
        thumb.Position = UDim2.new(rel,0,0.5,-7)
        valLbl.Text = tostring(val)
        if onChange then onChange(val) end
    end)
    return row
end

local function mkInputRow(parent, txt, default, order, onChange)
    local row = Instance.new("Frame", parent)
    row.Size = UDim2.new(1,0,0,26)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order or 1

    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = P.sub
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", row)
    box.Size = UDim2.new(0.36,0,0,22)
    box.Position = UDim2.new(0.63,0,0.5,-11)
    box.BackgroundColor3 = P.bg0
    box.TextColor3 = P.white
    box.Text = tostring(default)
    box.TextSize = 11
    box.Font = Enum.Font.GothamMedium
    box.BorderSizePixel = 0
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,4)
    Instance.new("UIStroke",box).Color = P.acc1
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then
            if onChange then onChange(v) end
        else
            box.Text = tostring(default)
        end
    end)
    return row, box
end

local function mkBigBtn(parent, txt, order, onClick)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1,0,0,32)
    b.BackgroundColor3 = P.glow
    b.TextColor3 = P.white
    b.Text = txt
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.LayoutOrder = order or 1
    local bc = Instance.new("UICorner",b) bc.CornerRadius = UDim.new(0,8)
    local bs = Instance.new("UIStroke",b) bs.Color = P.acc2 bs.Thickness = 1
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return b
end

-- ══════════════════════════════════════════
--  ABA 1 — FARM
-- ══════════════════════════════════════════
local f1 = abaFrames[1]

local c1a = mkCard(f1, 1)
mkSectionTitle(c1a, "Auto Farm Prestígio", 1)

local farmBtn = mkBigBtn(c1a, "⚡  Iniciar Farm", 2)
local statusLbl = mkLabel(c1a, "● Aguardando...", 10, P.dim, 3)

mkSectionTitle(c1a, "Configuração", 4)
mkSlider(c1a, "WalkSpeed", 8, SPEED_CAP, CFG.speed, 5, function(v)
    CFG.speed = v
    if hum and autoFarm then hum.WalkSpeed = v end
end)
mkInputRow(c1a, "Cooldown NPC (s)", CFG.cooldown, 6, function(v)
    CFG.cooldown = v
end)
mkInputRow(c1a, "Delay pós-interação min", CFG.delayMin, 7, function(v)
    CFG.delayMin = v
end)
mkInputRow(c1a, "Delay pós-interação max", CFG.delayMax, 8, function(v)
    CFG.delayMax = v
end)

farmBtn.MouseButton1Click:Connect(function()
    autoFarm = not autoFarm
    if autoFarm then
        farmBtn.BackgroundColor3 = P.acc1
        farmBtn.Text = "⛔  Parar Farm"
        task.spawn(farmLoop)
    else
        farmBtn.BackgroundColor3 = P.glow
        farmBtn.Text = "⚡  Iniciar Farm"
        if hum then hum:MoveTo(hrp.Position) hum.WalkSpeed = 16 end
    end
end)

-- ══════════════════════════════════════════
--  ABA 2 — ESP
-- ══════════════════════════════════════════
local f2 = abaFrames[2]
local c2a = mkCard(f2, 1)
mkSectionTitle(c2a, "Highlight (ver através de paredes)", 1)

mkToggle(c2a, "ESP Ativo", false, 2, function(v)
    espAtivo = v
    if not v then
        for _, hl in pairs(highlights) do hl:Destroy() end
        highlights = {}
    end
end)
mkToggle(c2a, "Nomes + Distância", false, 3, function(v)
    espNames = v
    if not v then
        for _, bb in pairs(billboards) do bb:Destroy() end
        billboards = {}
    end
end)

local c2b = mkCard(f2, 2)
mkSectionTitle(c2b, "Legenda", 1)
mkLabel(c2b, "🟣 Roxo — NPC disponível", 10, P.acc3, 2)
mkLabel(c2b, "🟠 Laranja — NPC em cooldown", 10, P.orange, 3)

-- ══════════════════════════════════════════
--  ABA 3 — OTIMIZAÇÃO
-- ══════════════════════════════════════════
local f3 = abaFrames[3]
local c3a = mkCard(f3, 1)
mkSectionTitle(c3a, "Gráficos / FPS", 1)

mkToggle(c3a, "Remover sombras", false, 2, function(v)
    otimizacoes.shadows = v
    toggleShadows(not v)
end)
mkToggle(c3a, "Remover partículas / fogo / fumaça", false, 3, function(v)
    otimizacoes.particles = v
    toggleParticles(not v)
end)
mkToggle(c3a, "Remover decais e texturas", false, 4, function(v)
    otimizacoes.textures = v
    toggleTextures(not v)
end)
mkToggle(c3a, "Ocultar outros jogadores", false, 5, function(v)
    otimizacoes.outros = v
    toggleOutros(v)
end)

mkSlider(c3a, "FPS Cap", 15, 60, 60, 6, function(v)
    -- limita FPS via RenderStepped throttle
    setfpscap(v)  -- função nativa do Delta executor
end)

local c3b = mkCard(f3, 2)
mkSectionTitle(c3b, "Qualidade de Renderização", 1)
mkSlider(c3b, "Nível de qualidade (1–10)", 1, 10, 10, 2, function(v)
    settings().Rendering.QualityLevel = Enum.QualityLevel["Level0"..math.min(v,9)] or Enum.QualityLevel.Level10
end)

-- ══════════════════════════════════════════
--  ABA 4 — MISC
-- ══════════════════════════════════════════
local f4 = abaFrames[4]
local c4a = mkCard(f4, 1)
mkSectionTitle(c4a, "Utilidades", 1)

mkToggle(c4a, "Anti-AFK", false, 2, function(v)
    antiAfk = v
    if v then ligarAntiAfk() else desligarAntiAfk() end
end)

mkToggle(c4a, "Noclip", false, 3, function(v)
    if v then
        RunService.Stepped:Connect(function()
            if not v then return end
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    else
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end)

mkToggle(c4a, "Infinite Jump", false, 4, function(v)
    UIS.JumpRequest:Connect(function()
        if v and hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end)

local c4b = mkCard(f4, 2)
mkSectionTitle(c4b, "Notificações", 1)
mkToggle(c4b, "Aviso ao completar prestígio", true, 2, function(v)
    -- controlado no dispararPrompt
    _G.notifPrestigio = v
end)
mkBigBtn(c4b, "🔔 Testar notificação", 3, function()
    StarterGui:SetCore("SendNotification", {
        Title = "KGS SCRIPTS",
        Text  = "✓ Notificação funcionando!",
        Duration = 3,
    })
end)

-- ══════════════════════════════════════════
--  ABA 5 — INFO
-- ══════════════════════════════════════════
local f5 = abaFrames[5]
local c5a = mkCard(f5, 1)
mkSectionTitle(c5a, "Personagem", 1)

local infoLbls = {
    pos   = mkLabel(c5a, "Posição: ...", 10, P.sub, 2),
    speed = mkLabel(c5a, "Velocidade atual: ...", 10, P.sub, 3),
    hp    = mkLabel(c5a, "HP: ...", 10, P.sub, 4),
    state = mkLabel(c5a, "Estado: ...", 10, P.sub, 5),
}

local c5b = mkCard(f5, 2)
mkSectionTitle(c5b, "Farm", 1)
local farmInfoLbls = {
    total  = mkLabel(c5b, "NPCs disponíveis: ...", 10, P.sub, 2),
    coolcd = mkLabel(c5b, "NPCs em cooldown: ...", 10, P.sub, 3),
    prox   = mkLabel(c5b, "Mais próximo: ...", 10, P.sub, 4),
}

local c5c = mkCard(f5, 3)
mkSectionTitle(c5c, "Script", 1)
mkLabel(c5c, "KGS SCRIPTS v5.0", 11, P.acc3, 2)
mkLabel(c5c, "Governo Brasileiro BR", 10, P.dim, 3)
mkLabel(c5c, "Delta iOS Executor", 10, P.dim, 4)

-- ══════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
topbar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = inp.Position startPos = win.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
topbar.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then dragInput = inp end
end)
UIS.InputChanged:Connect(function(inp)
    if dragging and inp == dragInput then
        local d = inp.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset+d.X,
            startPos.Y.Scale, startPos.Y.Offset+d.Y
        )
    end
end)

bClose.MouseButton1Click:Connect(function() sg:Destroy() end)
bMin.MouseButton1Click:Connect(function()
    local minimized = content.Visible
    content.Visible = not minimized
    abaBar.Visible = not minimized
    win.Size = minimized
        and UDim2.new(0,440,0,42)
        or  UDim2.new(0,440,0,380)
    bMin.Text = minimized and "□" or "—"
end)

-- ══════════════════════════════════════════
--  LOOP DE ATUALIZAÇÃO
-- ══════════════════════════════════════════
task.spawn(function()
    while task.wait(0.5) do
        -- status farm
        if not autoFarm then
            statusLbl.Text = "● Aguardando..."
            statusLbl.TextColor3 = P.dim
        else
            local npc = getNPCMaisProximo()
            if npc then
                local root = npc:FindFirstChild("HumanoidRootPart")
                local d = root and math.floor((root.Position-hrp.Position).Magnitude) or "?"
                statusLbl.Text = "● Farmando → "..npc.Name.." ("..d.."m)"
                statusLbl.TextColor3 = P.green
            else
                local menor = math.huge
                for _, n in ipairs(getNPCs()) do
                    local t = cooldowns[n.Name]
                    if t then local r=CFG.cooldown-(tick()-t) if r>0 and r<menor then menor=r end end
                end
                statusLbl.Text = menor < math.huge
                    and "⏱ cooldown ("..math.ceil(menor).."s)"
                    or "● Sem NPCs disponíveis"
                statusLbl.TextColor3 = P.orange
            end
        end

        -- info personagem
        if hrp then
            local pos = hrp.Position
            infoLbls.pos.Text   = string.format("Posição: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z)
            local vel = hrp.AssemblyLinearVelocity
            infoLbls.speed.Text = string.format("Velocidade: %.1f u/s",
                Vector3.new(vel.X,0,vel.Z).Magnitude)
        end
        if hum then
            infoLbls.hp.Text = string.format("HP: %.0f / %.0f", hum.Health, hum.MaxHealth)
            infoLbls.state.Text = "Estado: "..(autoFarm and "Farmando" or "Idle")
        end

        -- info NPCs
        local npcs = getNPCs()
        local livres, emCD = 0, 0
        local proxNpc, proxDist = nil, math.huge
        for _, npc in ipairs(npcs) do
            if emCooldown(npc) then
                emCD = emCD + 1
            else
                livres = livres + 1
                local root = npc:FindFirstChild("HumanoidRootPart")
                if root then
                    local d = (root.Position-hrp.Position).Magnitude
                    if d < proxDist then proxDist=d proxNpc=npc end
                end
            end
        end
        farmInfoLbls.total.Text  = "NPCs disponíveis: "..livres
        farmInfoLbls.coolcd.Text = "NPCs em cooldown: "..emCD
        farmInfoLbls.prox.Text   = proxNpc
            and ("Mais próximo: "..proxNpc.Name.." ("..math.floor(proxDist).."m)")
            or  "Mais próximo: nenhum livre"

        -- ESP
        atualizarHighlights()
    end
end)
