--============================================================
-- KAIHUBZ V12 CLEAN
-- Auto Match + Auto Replay + Uptime
-- AFK Monitor Removed
--============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--============================================================
-- REMOTES
--============================================================

local network = ReplicatedStorage
    :WaitForChild("shared")
    :WaitForChild("network")
    :WaitForChild("global_remote_container")

local startSearchRemote = network
    :WaitForChild("matchmaking")
    :WaitForChild("startSearch")

local matchFolder = network:WaitForChild("match")
local matchFoundRemote = matchFolder:WaitForChild("matchFound")
local matchStartedRemote = matchFolder:WaitForChild("matchStarted")
local matchEndedRemote = matchFolder:WaitForChild("matchEnded")

--============================================================
-- SETTINGS
--============================================================

local RETRY_DELAY = 10
local REPLAY_DELAY = 3

local PURPLE = Color3.fromRGB(135, 55, 255)
local DARK = Color3.fromRGB(15, 13, 27)
local PANEL = Color3.fromRGB(25, 22, 43)
local CARD = Color3.fromRGB(35, 30, 57)
local MUTED = Color3.fromRGB(165, 155, 195)
local WHITE = Color3.fromRGB(245, 242, 255)
local GREEN = Color3.fromRGB(45, 220, 135)
local RED = Color3.fromRGB(255, 85, 105)

--============================================================
-- STATE
--============================================================

local autoMatchEnabled = false
local autoReplayEnabled = false

local searching = false
local matchFound = false
local inMatch = false
local scriptEnded = false

local currentMatchId = nil
local retryToken = 0
local startTime = os.clock()

local connections = {}

local function track(connection)
    table.insert(connections, connection)
    return connection
end

local function disconnectAll()
    for _, connection in ipairs(connections) do
        if connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(connections)
end

--============================================================
-- CLEAN OLD UI
--============================================================

local oldGui = playerGui:FindFirstChild("AutoMatchUI")
if oldGui then
    oldGui:Destroy()
end

--============================================================
-- UI HELPERS
--============================================================

local function corner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object
    return c
end

local function stroke(object, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = object
    return s
end

local function gradient(object, color1, color2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    g.Rotation = rotation or 0
    g.Parent = object
    return g
end

local function label(parent, name, text, position, size, textSize, color, font)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Position = position
    l.Size = size
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or WHITE
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextWrapped = true
    l.Parent = parent
    return l
end

local function button(parent, name, text, position, size, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Position = position
    b.Size = size
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = WHITE
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = true
    b.Parent = parent
    corner(b, 9)
    return b
end

--============================================================
-- SCREEN GUI
--============================================================

local gui = Instance.new("ScreenGui")
gui.Name = "AutoMatchUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = playerGui

--============================================================
-- KAIHUBZ WATERMARK
--============================================================

local watermark = Instance.new("Frame")
watermark.Name = "KaiHubzWatermark"
watermark.Position = UDim2.fromOffset(18, 18)
watermark.Size = UDim2.fromOffset(175, 48)
watermark.BackgroundColor3 = DARK
watermark.Parent = gui
corner(watermark, 13)
stroke(watermark, PURPLE, 1.5, 0.1)

local watermarkIcon = Instance.new("Frame")
watermarkIcon.Position = UDim2.fromOffset(8, 7)
watermarkIcon.Size = UDim2.fromOffset(34, 34)
watermarkIcon.BackgroundColor3 = PURPLE
watermarkIcon.Parent = watermark
corner(watermarkIcon, 10)

label(
    watermarkIcon,
    "Icon",
    "K",
    UDim2.new(0, 0, 0, 0),
    UDim2.new(1, 0, 1, 0),
    21,
    WHITE,
    Enum.Font.GothamBlack
).TextXAlignment = Enum.TextXAlignment.Center

label(
    watermark,
    "Brand",
    "KaiHubz",
    UDim2.fromOffset(50, 4),
    UDim2.fromOffset(115, 25),
    19,
    WHITE,
    Enum.Font.GothamBlack
)

label(
    watermark,
    "Version",
    "AUTOMATION HUB",
    UDim2.fromOffset(51, 27),
    UDim2.fromOffset(115, 13),
    8,
    MUTED,
    Enum.Font.GothamBold
)

--============================================================
-- MAIN WINDOW
--============================================================

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(500, 420)
frame.Position = UDim2.new(0.5, -250, 0.5, -210)
frame.BackgroundColor3 = DARK
frame.BorderSizePixel = 0
frame.Parent = gui
corner(frame, 17)
stroke(frame, PURPLE, 2, 0.05)

gradient(
    frame,
    Color3.fromRGB(27, 20, 49),
    Color3.fromRGB(13, 13, 25),
    45
)

-- HEADER

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 76)
header.BackgroundColor3 = PANEL
header.BorderSizePixel = 0
header.Parent = frame
corner(header, 16)

local headerAccent = Instance.new("Frame")
headerAccent.Position = UDim2.new(0, 0, 1, -3)
headerAccent.Size = UDim2.new(1, 0, 0, 3)
headerAccent.BackgroundColor3 = PURPLE
headerAccent.BorderSizePixel = 0
headerAccent.Parent = header

label(
    header,
    "MainTitle",
    "KAIHUBZ",
    UDim2.fromOffset(20, 10),
    UDim2.fromOffset(260, 30),
    23,
    WHITE,
    Enum.Font.GothamBlack
)

label(
    header,
    "Subtitle",
    "AUTO MATCH CONTROL CENTER",
    UDim2.fromOffset(21, 42),
    UDim2.fromOffset(270, 18),
    10,
    MUTED,
    Enum.Font.GothamBold
)

local version = label(
    header,
    "Version",
    "V12",
    UDim2.new(1, -105, 0, 15),
    UDim2.fromOffset(45, 25),
    12,
    PURPLE,
    Enum.Font.GothamBlack
)
version.TextXAlignment = Enum.TextXAlignment.Center

local minimizeButton = button(
    header,
    "MinimizeButton",
    "−",
    UDim2.new(1, -55, 0, 16),
    UDim2.fromOffset(32, 30),
    Color3.fromRGB(65, 50, 95)
)
minimizeButton.TextSize = 20

local deleteButton = button(
    header,
    "DeleteButton",
    "×",
    UDim2.new(1, -38, 0, 16),
    UDim2.fromOffset(28, 30),
    Color3.fromRGB(130, 40, 65)
)
deleteButton.TextSize = 20

--============================================================
-- CONTENT
--============================================================

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(16, 88)
content.Size = UDim2.new(1, -32, 1, -103)
content.BackgroundTransparency = 1
content.Parent = frame

label(
    content,
    "SectionTitle",
    "FEATURES",
    UDim2.fromOffset(5, 0),
    UDim2.fromOffset(200, 20),
    11,
    MUTED,
    Enum.Font.GothamBold
)

--============================================================
-- FEATURE CARD CREATOR
--============================================================

local function createFeatureCard(name, titleText, description, iconText, y)
    local card = Instance.new("Frame")
    card.Name = name .. "Card"
    card.Position = UDim2.fromOffset(0, y)
    card.Size = UDim2.new(1, 0, 0, 69)
    card.BackgroundColor3 = CARD
    card.BorderSizePixel = 0
    card.Parent = content
    corner(card, 12)
    stroke(card, Color3.fromRGB(75, 60, 110), 1, 0.45)

    local icon = Instance.new("Frame")
    icon.Position = UDim2.fromOffset(10, 10)
    icon.Size = UDim2.fromOffset(48, 48)
    icon.BackgroundColor3 = Color3.fromRGB(65, 35, 125)
    icon.Parent = card
    corner(icon, 14)

    label(
        icon,
        "IconText",
        iconText,
        UDim2.new(0, 0, 0, 0),
        UDim2.new(1, 0, 1, 0),
        22,
        WHITE,
        Enum.Font.GothamBlack
    ).TextXAlignment = Enum.TextXAlignment.Center

    label(
        card,
        "FeatureTitle",
        titleText,
        UDim2.fromOffset(70, 12),
        UDim2.new(1, -195, 0, 22),
        15,
        WHITE,
        Enum.Font.GothamBold
    )

    label(
        card,
        "Description",
        description,
        UDim2.fromOffset(70, 36),
        UDim2.new(1, -195, 0, 22),
        10,
        MUTED,
        Enum.Font.Gotham
    )

    local toggle = button(
        card,
        "Toggle",
        "OFF",
        UDim2.new(1, -94, 0.5, -16),
        UDim2.fromOffset(82, 32),
        Color3.fromRGB(65, 55, 85)
    )

    return card, toggle
end

local autoCard, matchButton = createFeatureCard(
    "AutoMatch",
    "Auto Match",
    "Automatically search for a match.",
    "⚡",
    27
)

local replayCard, replayButton = createFeatureCard(
    "AutoReplay",
    "Auto Replay",
    "Search again after a match ends.",
    "↻",
    104
)

--============================================================
-- MATCH INFORMATION
--============================================================

local infoCard = Instance.new("Frame")
infoCard.Name = "MatchInformation"
infoCard.Position = UDim2.fromOffset(0, 181)
infoCard.Size = UDim2.new(1, 0, 0, 75)
infoCard.BackgroundColor3 = PANEL
infoCard.Parent = content
corner(infoCard, 12)
stroke(infoCard, Color3.fromRGB(75, 60, 110), 1, 0.5)

label(
    infoCard,
    "InfoTitle",
    "MATCH INFORMATION",
    UDim2.fromOffset(12, 5),
    UDim2.new(1, -24, 0, 17),
    9,
    PURPLE,
    Enum.Font.GothamBold
)

local playerLabel = label(
    infoCard,
    "PlayerLabel",
    "Opponent: Not found",
    UDim2.fromOffset(12, 24),
    UDim2.new(1, -24, 0, 18),
    11,
    WHITE,
    Enum.Font.Gotham
)

local teamLabel = label(
    infoCard,
    "TeamLabel",
    "Team: Not found",
    UDim2.fromOffset(12, 43),
    UDim2.new(1, -24, 0, 18),
    11,
    MUTED,
    Enum.Font.Gotham
)

local detailsLabel = label(
    content,
    "MatchDetails",
    "Waiting for matchmaking...",
    UDim2.fromOffset(4, 261),
    UDim2.new(1, -8, 0, 20),
    10,
    MUTED,
    Enum.Font.Gotham
)

--============================================================
-- FOOTER STATUS
--============================================================

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Position = UDim2.new(0, 0, 1, -29)
footer.Size = UDim2.new(1, 0, 0, 25)
footer.BackgroundTransparency = 1
footer.Parent = frame

local statusDot = Instance.new("Frame")
statusDot.Position = UDim2.fromOffset(5, 7)
statusDot.Size = UDim2.fromOffset(10, 10)
statusDot.BackgroundColor3 = RED
statusDot.Parent = footer
corner(statusDot, 20)

local statusLabel = label(
    footer,
    "StatusLabel",
    "STOPPED",
    UDim2.fromOffset(22, 0),
    UDim2.new(0.55, -22, 1, 0),
    10,
    MUTED,
    Enum.Font.GothamBold
)

local uptimeLabel = label(
    footer,
    "UptimeLabel",
    "UPTIME: 00:00",
    UDim2.new(0.58, 0, 0, 0),
    UDim2.new(0.42, -5, 1, 0),
    9,
    MUTED,
    Enum.Font.GothamBold
)
uptimeLabel.TextXAlignment = Enum.TextXAlignment.Right

--============================================================
-- UI STATE HELPERS
--============================================================

local function updateStatus(message, color)
    if scriptEnded then return end

    color = color or MUTED
    statusLabel.Text = tostring(message)
    statusLabel.TextColor3 = color
    statusDot.BackgroundColor3 = color
end

local function clearMatchInfo()
    playerLabel.Text = "Opponent: Not found"
    teamLabel.Text = "Team: Not found"
    detailsLabel.Text = "Waiting for matchmaking..."
end

local function updateToggle(toggle, enabled)
    toggle.Text = enabled and "ON" or "OFF"
    toggle.BackgroundColor3 = enabled
        and PURPLE
        or Color3.fromRGB(65, 55, 85)
end

local function setAutoMatch(enabled)
    autoMatchEnabled = enabled
    updateToggle(matchButton, enabled)
end

local function setAutoReplay(enabled)
    autoReplayEnabled = enabled
    updateToggle(replayButton, enabled)
end

--============================================================
-- MATCH VALIDATION
--============================================================

local function isMyMatch(data)
    if type(data) ~= "table" then return false end

    local home = data.home
    local away = data.away

    if type(home) == "table"
        and tonumber(home.userId) == player.UserId then
        return true
    end

    if type(away) == "table"
        and tonumber(away.userId) == player.UserId then
        return true
    end

    if tonumber(data.ownerId) == player.UserId then
        return data.ownerSide == "home"
            or data.ownerSide == "away"
    end

    return false
end

local function getOpponent(data)
    if not isMyMatch(data) then return nil end

    local home = data.home or {}
    local away = data.away or {}

    if tonumber(home.userId) == player.UserId then
        return away
    elseif tonumber(away.userId) == player.UserId then
        return home
    elseif tonumber(data.ownerId) == player.UserId then
        if data.ownerSide == "home" then
            return away
        elseif data.ownerSide == "away" then
            return home
        end
    end

    return nil
end

local function displayOpponent(data)
    local opponent = getOpponent(data)
    if not opponent then return false end

    playerLabel.Text = "Opponent: "
        .. tostring(opponent.displayName or "Unknown")

    local team = "Unknown Team"

    if type(opponent.club) == "table" then
        team = tostring(opponent.club.name or team)
    elseif type(opponent.club) == "string" then
        team = opponent.club
    end

    teamLabel.Text = "Team: " .. team
    return true
end

--============================================================
-- SEARCH
--============================================================

local startSearch

startSearch = function()
    if scriptEnded or not autoMatchEnabled then return end
    if searching or matchFound or inMatch then return end

    searching = true
    local myToken = retryToken

    updateStatus("SEARCHING...", Color3.fromRGB(255, 195, 75))
    clearMatchInfo()

    task.spawn(function()
        local success, response = pcall(function()
            return startSearchRemote:InvokeServer(nil)
        end)

        if scriptEnded or myToken ~= retryToken then return end
        if matchFound or inMatch then return end

        searching = false

        if success then
            updateStatus("WAITING FOR MATCH", Color3.fromRGB(255, 195, 75))
            detailsLabel.Text = "Search request accepted"
        else
            warn("KaiHubz Auto Match error:", response)

            updateStatus("SEARCH ERROR", RED)
            detailsLabel.Text = "Retrying in " .. RETRY_DELAY .. " seconds"

            task.delay(RETRY_DELAY, function()
                if not scriptEnded
                    and myToken == retryToken
                    and autoMatchEnabled
                    and not matchFound
                    and not inMatch then
                    startSearch()
                end
            end)
        end
    end)
end

--============================================================
-- MATCH FOUND
--============================================================

track(matchFoundRemote.OnClientEvent:Connect(function(data)
    if scriptEnded or not isMyMatch(data) then return end
    if data.id == nil or not displayOpponent(data) then return end

    currentMatchId = tostring(data.id)
    retryToken += 1
    searching = false
    matchFound = true
    inMatch = false

    updateStatus("MATCH FOUND", GREEN)
    detailsLabel.Text = "Match ID: " .. currentMatchId
end))

--============================================================
-- MATCH STARTED
--============================================================

track(matchStartedRemote.OnClientEvent:Connect(function(data)
    if scriptEnded or type(data) ~= "table" then return end
    if not currentMatchId then return end
    if tostring(data.id or "") ~= currentMatchId then return end
    if not isMyMatch(data) or not displayOpponent(data) then return end

    retryToken += 1
    searching = false
    matchFound = true
    inMatch = true

    updateStatus("IN MATCH", GREEN)
    detailsLabel.Text = "Match ID: " .. currentMatchId
end))

--============================================================
-- MATCH ENDED
--============================================================

track(matchEndedRemote.OnClientEvent:Connect(function(matchId, data)
    if scriptEnded or type(data) ~= "table" then return end
    if not currentMatchId then return end
    if tostring(matchId) ~= currentMatchId then return end

    local endedId = currentMatchId

    retryToken += 1
    searching = false
    matchFound = false
    inMatch = false
    currentMatchId = nil

    local result = tostring(data.result or "finished")
    local homeGoals = tonumber(data.homeGoals) or 0
    local awayGoals = tonumber(data.awayGoals) or 0

    updateStatus(
        "MATCH ENDED",
        Color3.fromRGB(100, 180, 255)
    )

    playerLabel.Text = string.format(
        "%s %d - %d %s",
        tostring(data.homeName or "Home"),
        homeGoals,
        awayGoals,
        tostring(data.awayName or "Away")
    )

    teamLabel.Text = string.format(
        "Money: %s | Fans: %s",
        tostring(data.money or 0),
        tostring(data.fans or 0)
    )

    local mvpText = "MVP: Not available"

    if type(data.mvp) == "table"
        and type(data.ratings) == "table" then

        local ratings = data.ratings[data.mvp.side]
        local index = tonumber(data.mvp.index)

        if type(ratings) == "table" and index then
            local mvp = ratings[index]

            if type(mvp) == "table" then
                mvpText = "MVP: " .. tostring(mvp.name or "Unknown")
            end
        end
    end

    detailsLabel.Text = mvpText .. " | ID: " .. endedId
    print("KAIHUBZ MATCH ENDED:", endedId, result)

    if autoReplayEnabled then
        updateStatus("NEXT SEARCH SOON", Color3.fromRGB(100, 180, 255))

        task.delay(REPLAY_DELAY, function()
            if scriptEnded or not autoReplayEnabled then return end

            if not autoMatchEnabled then
                setAutoMatch(true)
            end

            if not matchFound and not inMatch and not searching then
                retryToken += 1
                startSearch()
            end
        end)
    end
end))

--============================================================
-- AUTO MATCH TOGGLE
--============================================================

track(matchButton.Activated:Connect(function()
    if autoMatchEnabled then
        retryToken += 1
        setAutoMatch(false)
        searching = false

        if inMatch then
            updateStatus("IN MATCH", GREEN)
        elseif matchFound then
            updateStatus("MATCH FOUND", GREEN)
        else
            updateStatus("STOPPED", MUTED)
            clearMatchInfo()
        end
    else
        setAutoMatch(true)

        if not inMatch and not matchFound then
            retryToken += 1
            startSearch()
        end
    end
end))

--============================================================
-- AUTO REPLAY TOGGLE
--============================================================

track(replayButton.Activated:Connect(function()
    setAutoReplay(not autoReplayEnabled)

    if autoReplayEnabled
        and not autoMatchEnabled
        and not inMatch
        and not matchFound then

        setAutoMatch(true)
        retryToken += 1
        startSearch()
    end
end))

--============================================================
-- DRAGGING
--============================================================

local dragging = false
local dragStart
local startPosition

track(header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = frame.Position
    end
end))

track(UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        frame.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end))

track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

--============================================================
-- MINIMIZE
--============================================================

local minimized = false

track(minimizeButton.Activated:Connect(function()
    minimized = not minimized

    content.Visible = not minimized
    frame.Size = minimized
        and UDim2.fromOffset(500, 76)
        or UDim2.fromOffset(500, 420)

    minimizeButton.Text = minimized and "+" or "−"
end))

--============================================================
-- RIGHT CONTROL: HIDE / SHOW
--============================================================

track(UserInputService.InputBegan:Connect(function(input, processed)
    if processed or scriptEnded then return end

    if input.KeyCode == Enum.KeyCode.RightControl then
        gui.Enabled = not gui.Enabled
    end
end))

--============================================================
-- DELETE / CLEANUP
--============================================================

track(deleteButton.Activated:Connect(function()
    if scriptEnded then return end

    scriptEnded = true
    retryToken += 1

    autoMatchEnabled = false
    autoReplayEnabled = false

    disconnectAll()
    gui:Destroy()
end))

--============================================================
-- UPTIME TIMER (AFK MONITOR REMOVED)
--============================================================

task.spawn(function()
    while not scriptEnded do
        task.wait(1)

        local elapsed = math.floor(os.clock() - startTime)
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60

        uptimeLabel.Text = string.format(
            "UPTIME: %02d:%02d",
            minutes,
            seconds
        )
    end
end)

--============================================================
-- INITIALIZE
--============================================================

setAutoMatch(false)
setAutoReplay(false)

updateStatus("READY", GREEN)

print("====================================")
print("        KAIHUBZ V12 CLEAN LOADED")
print(" Auto Match: READY")
print(" Auto Replay: READY")
print(" Uptime: READY")
print(" AFK Monitor: REMOVED")
print("====================================")
