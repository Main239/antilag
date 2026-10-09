-- ULTRA ANTI-LAG FULL | Iron Soul Dungeon
if getgenv().AntiLagFull then return end
getgenv().AntiLagFull = true

----------------------------------------------------------------
-- CÀI ĐẶT (true/false)
----------------------------------------------------------------
local AN_NGUOI_CHOI       = false -- true = ẩn hẳn người chơi khác
local STOP_ANIM_BAN_THAN  = false -- true = dừng cả animation của bạn (dễ lỗi skill)
local CHONG_NGHIENG       = true  -- chặn camera nghiêng/xoay khi rung
local HIEN_FPS            = true  -- hiện ô FPS

----------------------------------------------------------------
-- DỊCH VỤ
----------------------------------------------------------------
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local WS = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Terrain = WS.Terrain
local LP = Players.LocalPlayer

----------------------------------------------------------------
-- 1) DỌN HIỆU ỨNG / TEXTURE / ÁNH SÁNG
----------------------------------------------------------------
local function clean(v)
    pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
            or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles")
            or v:IsA("Highlight") then
            v.Enabled = false
        elseif v:IsA("Explosion") or v:IsA("ForceField") then
            v:Destroy()
        elseif v:IsA("PostEffect") or v:IsA("Atmosphere")
            or v:IsA("Sky") or v:IsA("Clouds") then
            v:Destroy()
        elseif v:IsA("Light") then
            v.Enabled = false
        elseif v:IsA("MeshPart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
            v.TextureID = ""
            v.RenderFidelity = Enum.RenderFidelity.Performance
        elseif v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture")
            or v:IsA("SurfaceAppearance") then
            v:Destroy()
        end
    end)
end

----------------------------------------------------------------
-- 2) NGƯỜI CHƠI KHÁC
----------------------------------------------------------------
local function nhanVat(char)
    if not char or char == LP.Character then return end
    for _, v in ipairs(char:GetDescendants()) do
        pcall(function()
            if v:IsA("Accessory") or v:IsA("Clothing")
                or v:IsA("ShirtGraphic") or v:IsA("BillboardGui") then
                v:Destroy()
            elseif v:IsA("BasePart") and AN_NGUOI_CHOI then
                v.LocalTransparencyModifier = 1
            end
        end)
    end
end
local function theoDoi(p)
    if p == LP then return end
    p.CharacterAdded:Connect(function(c) task.wait(1) nhanVat(c) end)
    nhanVat(p.Character)
end
for _, p in ipairs(Players:GetPlayers()) do theoDoi(p) end
Players.PlayerAdded:Connect(theoDoi)

----------------------------------------------------------------
-- 3) LIGHTING + BẦU TRỜI + TERRAIN + HỆ THỐNG
----------------------------------------------------------------
local function xoaTroi()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("Clouds") then
            v:Destroy()
        end
    end
    Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
    Lighting.ClockTime = 12
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
end

Lighting.Brightness = 2
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.ShadowSoftness = 0
pcall(function()
    sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
end)
for _, v in ipairs(Lighting:GetChildren()) do clean(v) end
xoaTroi()
Lighting.ChildAdded:Connect(function() task.defer(xoaTroi) end)

pcall(function()
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
    Terrain.Decoration = false
end)

pcall(function()
    local r = settings().Rendering
    r.QualityLevel = Enum.QualityLevel.Level01
    r.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
    settings().Physics.AllowSleep = true
end)
pcall(function() setfpscap(60) end)

----------------------------------------------------------------
-- 4) ÂM THANH
----------------------------------------------------------------
pcall(function() UserSettings():GetService("UserGameSettings").MasterVolume = 0 end)
pcall(function() SoundService.AmbientReverb = Enum.ReverbType.NoReverb end)
local function muteSound(s)
    pcall(function() s.Volume = 0 s:Stop() end)
end
for _, v in ipairs(game:GetDescendants()) do
    if v:IsA("Sound") then muteSound(v) end
end
game.DescendantAdded:Connect(function(v)
    if v:IsA("Sound") then task.defer(muteSound, v) end
end)

----------------------------------------------------------------
-- 5) ANIMATION (CHUYỂN ĐỘNG)
----------------------------------------------------------------
local function freezeAnimator(a)
    pcall(function()
        local char = a:FindFirstAncestorOfClass("Model")
        if not STOP_ANIM_BAN_THAN and char == LP.Character then return end
        for _, t in ipairs(a:GetPlayingAnimationTracks()) do t:Stop(0) end
        a.AnimationPlayed:Connect(function(t) t:Stop(0) end)
    end)
end
for _, v in ipairs(WS:GetDescendants()) do
    if v:IsA("Animator") then freezeAnimator(v) end
end
WS.DescendantAdded:Connect(function(v)
    if v:IsA("Animator") then task.defer(freezeAnimator, v) end
end)

----------------------------------------------------------------
-- 6) CHẶN RUNG MÀN HÌNH + BLUR
----------------------------------------------------------------
pcall(function() RunService:UnbindFromRenderStep("NoShake") end)
RunService:BindToRenderStep("NoShake", Enum.RenderPriority.Camera.Value + 1, function()
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
        if CHONG_NGHIENG then
            local cam = WS.CurrentCamera
            local pos = cam.CFrame.Position
            cam.CFrame = CFrame.lookAt(pos, pos + cam.CFrame.LookVector)
        end
    end)
end)

local function noBlur(v)
    if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect")
        or v:IsA("DepthOfFieldEffect") or v:IsA("BloomEffect")
        or v:IsA("SunRaysEffect") then
        v:Destroy()
    end
end
local cam = WS.CurrentCamera
if cam then
    for _, v in ipairs(cam:GetChildren()) do noBlur(v) end
    cam.ChildAdded:Connect(noBlur)
end

----------------------------------------------------------------
-- 7) DỌN TOÀN MAP + HIỆU ỨNG MỚI + QUÉT LẠI
----------------------------------------------------------------
task.spawn(function()
    local n = 0
    for _, v in ipairs(WS:GetDescendants()) do
        clean(v)
        n += 1
        if n % 200 == 0 then task.wait() end
    end
end)

WS.DescendantAdded:Connect(function(v) task.defer(clean, v) end)
Lighting.DescendantAdded:Connect(function(v)
    task.defer(clean, v)
    task.defer(noBlur, v)
end)

task.spawn(function()
    while task.wait(10) do
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        for _, v in ipairs(Lighting:GetChildren()) do clean(v) end
    end
end)

----------------------------------------------------------------
-- 8) Ô FPS (BO GÓC, KÉO THẢ)
----------------------------------------------------------------
if HIEN_FPS then
    task.spawn(function()
        local parent
        pcall(function() parent = gethui and gethui() end)
        if not parent then
            local ok = pcall(function() parent = game:GetService("CoreGui") end)
            if not ok or not parent then
                parent = LP:WaitForChild("PlayerGui")
            end
        end
        local old = parent:FindFirstChild("FPSBox")
        if old then old:Destroy() end

        local gui = Instance.new("ScreenGui")
        gui.Name = "FPSBox"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999
        gui.Parent = parent

        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(90, 34)
        frame.Position = UDim2.new(0, 120, 0, 60)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        frame.BackgroundTransparency = 0.25
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 255, 255)
        stroke.Transparency = 0.7
        stroke.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 16
        label.TextColor3 = Color3.fromRGB(0, 255, 120)
        label.Text = "FPS: --"
        label.Parent = frame

        local frames, last = 0, os.clock()
        RunService.RenderStepped:Connect(function()
            frames += 1
            local now = os.clock()
            if now - last >= 0.5 then
                local fps = math.floor(frames / (now - last))
                label.Text = "FPS: " .. fps
                label.TextColor3 = fps >= 50 and Color3.fromRGB(0, 255, 120)
                    or fps >= 30 and Color3.fromRGB(255, 200, 0)
                    or Color3.fromRGB(255, 70, 70)
                frames, last = 0, now
            end
        end)

        local dragging, dragStart, startPos
        frame.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch
                or i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = i.Position
                startPos = frame.Position
                i.Changed:Connect(function()
                    if i.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UIS.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.Touch
                or i.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = i.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end)
end

print("Anti-lag FULL đã bật!")
