--========================================================
-- TP WALK + MOVE SAFE + MULTI-AREA LARGEST NEST
-- AUTO PROMPT 10x
-- AUTO REPLACE HUMANOID ON RESPAWN
-- DESTROY CLIENT RENDERED ASSETS
-- SERVER HOP
-- LocalScript - StarterPlayerScripts
--========================================================

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

--========================================================
-- SETTINGS
--========================================================

local STAND_POSITION = Vector3.new(
	544.577637,
	92.0762939,
	-364.869049
)

local MIN_SPEED = 1
local MAX_SPEED = 800
local DEFAULT_SPEED = 450

local STAND_DISTANCE = 2
local NEST_DISTANCE = 3
local PROMPT_DISTANCE = 12

local PROMPT_CLICKS = 10
local PROMPT_HOLD_TIME = 0.02

--========================================================
-- STATE
--========================================================

local tpSpeed = DEFAULT_SPEED

local tpEnabled = false
local largestNestEnabled = false
local isAutoMoving = false

local targetPosition = nil
local movementMode = nil

local activePrompt = nil
local draggingSlider = false

-- MULTI-AREA STATE
local selectedAreas = {
	Cosmic = true,       -- Mặc định chọn Cosmic
	Prehistoric = false  -- Mặc định tắt Prehistoric
}

local areaOrder = {"Cosmic", "Prehistoric"}
local currentAreaIndex = 1

--========================================================
-- NOTIFICATION
--========================================================

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Script Loaded",
		Text = "Nhớ nhặt 1 quả trứng bất kỳ trước khi bật auto.",
		Duration = 4
	})
end)

--========================================================
-- PROXIMITY PROMPT
--========================================================

ProximityPromptService.PromptShown:Connect(function(prompt)
	prompt.HoldDuration = 0
end)

--========================================================
-- GUI CREATION
--========================================================

local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("CombinedTPWalkUI")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CombinedTPWalkUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

--========================================================
-- MENU BUTTON
--========================================================

local menuBtn = Instance.new("TextButton")
menuBtn.Name = "MenuButton"
menuBtn.Size = UDim2.new(0, 70, 0, 35)
menuBtn.Position = UDim2.new(0, 10, 0.25, 0)
menuBtn.Text = "MENU"
menuBtn.TextScaled = true
menuBtn.Font = Enum.Font.GothamBold
menuBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.Active = true
menuBtn.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 8)
menuCorner.Parent = menuBtn

--========================================================
-- MAIN FRAME
--========================================================

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 270, 0, 520)
frame.Position = UDim2.new(0.5, -135, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

--========================================================
-- TITLE & CLOSE
--========================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.75, 0, 0, 32)
title.Position = UDim2.new(0.04, 0, 0, 3)
title.Text = "AUTO MOVE"
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 32, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 4)
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

--========================================================
-- BUTTON CREATOR
--========================================================

local function createButton(name, text, y, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0.90, 0, 0, 36)
	button.Position = UDim2.new(0.05, 0, 0, y)
	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	return button
end

--========================================================
-- BUTTONS SETUP
--========================================================

local moveStandBtn     = createButton("MoveStand",     "Move to Safe",              42,  Color3.fromRGB(45, 125, 230))
local stopBtn          = createButton("Stop",          "STOP",                      82,  Color3.fromRGB(210, 50, 50))
local largestNestBtn   = createButton("LargestNest",   "Move to Largest Nest: OFF", 122, Color3.fromRGB(100, 100, 100))
local areaBtn          = createButton("AreaSelect",    "Select Areas (Multi)",      162, Color3.fromRGB(80, 80, 160))
local respawnBtn       = createButton("Respawn",       "Respawn",                   202, Color3.fromRGB(230, 140, 30))
local replaceHumBtn    = createButton("AntiCheat",     "Bypass Anti-Cheat",         242, Color3.fromRGB(180, 60, 60))
local tpWalkBtn        = createButton("TPWalk",        "TP Walk: OFF",              282, Color3.fromRGB(100, 100, 100))
local destroyAssetsBtn = createButton("HidePet",       "Destroy Pet Assets",        322, Color3.fromRGB(160, 60, 60))
local serverHopBtn     = createButton("ServerHop",     "Server Hop",                362, Color3.fromRGB(70, 120, 200))

--========================================================
-- MULTI AREA SELECT FRAME
--========================================================

local areaFrame = Instance.new("Frame")
areaFrame.Name = "AreaFrame"
areaFrame.Size = UDim2.new(0, 210, 0, 140)
areaFrame.Position = UDim2.new(1, 10, 0, 160)
areaFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
areaFrame.BorderSizePixel = 0
areaFrame.Visible = false
areaFrame.Parent = frame

local areaCorner = Instance.new("UICorner")
areaCorner.CornerRadius = UDim.new(0, 10)
areaCorner.Parent = areaFrame

local areaTitle = Instance.new("TextLabel")
areaTitle.Size = UDim2.new(1, 0, 0, 30)
areaTitle.Position = UDim2.new(0, 0, 0, 5)
areaTitle.Text = "CHỌN KHU (MULTI)"
areaTitle.TextScaled = true
areaTitle.Font = Enum.Font.GothamBold
areaTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
areaTitle.BackgroundTransparency = 1
areaTitle.Parent = areaFrame

local cosmicBtn = Instance.new("TextButton")
cosmicBtn.Size = UDim2.new(0.9, 0, 0, 38)
cosmicBtn.Position = UDim2.new(0.05, 0, 0, 40)
cosmicBtn.Text = "[X] Khu 1 - Cosmic"
cosmicBtn.TextScaled = true
cosmicBtn.Font = Enum.Font.GothamBold
cosmicBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
cosmicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cosmicBtn.Parent = areaFrame

local cosmicCorner = Instance.new("UICorner")
cosmicCorner.CornerRadius = UDim.new(0, 8)
cosmicCorner.Parent = cosmicBtn

local prehistoricBtn = Instance.new("TextButton")
prehistoricBtn.Size = UDim2.new(0.9, 0, 0, 38)
prehistoricBtn.Position = UDim2.new(0.05, 0, 0, 86)
prehistoricBtn.Text = "[ ] Khu 2 - Prehistoric"
prehistoricBtn.TextScaled = true
prehistoricBtn.Font = Enum.Font.GothamBold
prehistoricBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
prehistoricBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prehistoricBtn.Parent = areaFrame

local prehistoricCorner = Instance.new("UICorner")
prehistoricCorner.CornerRadius = UDim.new(0, 8)
prehistoricCorner.Parent = prehistoricBtn

areaBtn.MouseButton1Click:Connect(function()
	areaFrame.Visible = not areaFrame.Visible
end)

cosmicBtn.MouseButton1Click:Connect(function()
	selectedAreas.Cosmic = not selectedAreas.Cosmic
	if selectedAreas.Cosmic then
		cosmicBtn.Text = "[X] Khu 1 - Cosmic"
		cosmicBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	else
		cosmicBtn.Text = "[ ] Khu 1 - Cosmic"
		cosmicBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

prehistoricBtn.MouseButton1Click:Connect(function()
	selectedAreas.Prehistoric = not selectedAreas.Prehistoric
	if selectedAreas.Prehistoric then
		prehistoricBtn.Text = "[X] Khu 2 - Prehistoric"
		prehistoricBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	else
		prehistoricBtn.Text = "[ ] Khu 2 - Prehistoric"
		prehistoricBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

--========================================================
-- SPEED SLIDER & LABELS
--========================================================

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.90, 0, 0, 22)
speedLabel.Position = UDim2.new(0.05, 0, 0, 405)
speedLabel.Text = "Speed: " .. tpSpeed
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.BackgroundTransparency = 1
speedLabel.Parent = frame

local sliderTrack = Instance.new("Frame")
sliderTrack.Name = "SpeedSlider"
sliderTrack.Size = UDim2.new(0.90, 0, 0, 8)
sliderTrack.Position = UDim2.new(0.05, 0, 0, 432)
sliderTrack.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
sliderTrack.BorderSizePixel = 0
sliderTrack.Active = true
sliderTrack.Parent = frame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = sliderTrack

local initialScale = (DEFAULT_SPEED - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)

local sliderButton = Instance.new("TextButton")
sliderButton.Name = "SliderButton"
sliderButton.Size = UDim2.new(0, 20, 0, 20)
sliderButton.Position = UDim2.new(initialScale, -10, 0.5, -10)
sliderButton.Text = ""
sliderButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
sliderButton.Parent = sliderTrack

local sliderButtonCorner = Instance.new("UICorner")
sliderButtonCorner.CornerRadius = UDim.new(1, 0)
sliderButtonCorner.Parent = sliderButton

--========================================================
-- STATUS
--========================================================

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.90, 0, 0, 22)
statusLabel.Position = UDim2.new(0.05, 0, 0, 460)
statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = frame

--========================================================
-- INTERACT BUTTON
--========================================================

local interactBtn = Instance.new("TextButton")
interactBtn.Name = "InteractButton"
interactBtn.Size = UDim2.new(0, 190, 0, 42)
interactBtn.Position = UDim2.new(0.5, -95, 0.78, 0)
interactBtn.Text = "Interact Nest"
interactBtn.TextScaled = true
interactBtn.Font = Enum.Font.GothamBold
interactBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
interactBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
interactBtn.Visible = false
interactBtn.Parent = screenGui

local interactCorner = Instance.new("UICorner")
interactCorner.CornerRadius = UDim.new(0, 9)
interactCorner.Parent = interactBtn

--========================================================
-- GUI TOGGLE & DRAG
--========================================================

menuBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

local function makeDraggable(object)
	local dragging = false
	local dragStart, startPosition, dragInput

	object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	object.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart
			object.Position = UDim2.new(
				startPosition.X.Scale, startPosition.X.Offset + delta.X,
				startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(frame)
makeDraggable(menuBtn)
makeDraggable(interactBtn)

--========================================================
-- MOVEMENT LOGIC
--========================================================

local function stopMovement()
	isAutoMoving = false
	targetPosition = nil
	movementMode = nil
	activePrompt = nil
	interactBtn.Visible = false
	statusLabel.Text = "Status: Idle"
end

local function moveToStand()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	targetPosition = STAND_POSITION
	movementMode = "Stand"
	isAutoMoving = true
	activePrompt = nil
	interactBtn.Visible = false
	statusLabel.Text = "Status: Moving → Safe"
end

-- Lấy tên Area tiếp theo trong danh sách đã tích chọn
local function getNextSelectedArea()
	for i = 1, #areaOrder do
		local idx = ((currentAreaIndex - 1 + i - 1) % #areaOrder) + 1
		local areaName = areaOrder[idx]
		if selectedAreas[areaName] then
			currentAreaIndex = idx + 1
			return areaName
		end
	end
	return nil
end

local function getNestsFolder(areaName)
	local objects = workspace:FindFirstChild("__OBJECTS")
	if not objects then return nil end

	local guardAreas = objects:FindFirstChild("Areas") and objects.Areas:FindFirstChild("GuardAreas")
	if not guardAreas then return nil end

	local areaFolder = guardAreas:FindFirstChild(areaName)
	if not areaFolder then return nil end

	return areaFolder:FindFirstChild("Nests")
end

local function getNestPosition(nest)
	if nest:IsA("BasePart") then return nest.Position end
	if nest:IsA("Model") then return nest:GetPivot().Position end
	return nil
end

local function getNestSize(nest)
	if nest:IsA("BasePart") then return nest.Size.Magnitude end
	if nest:IsA("Model") then return nest:GetExtentsSize().Magnitude end
	return 0
end

local function moveToNextLargestNest()
	local areaToFarm = getNextSelectedArea()
	if not areaToFarm then
		statusLabel.Text = "Status: No Area Selected!"
		stopMovement()
		return
	end

	local nestsFolder = getNestsFolder(areaToFarm)
	if not nestsFolder then
		statusLabel.Text = "Status: " .. areaToFarm .. " Nests not found"
		return
	end

	local largestNest, largestSize, largestPosition = nil, 0, nil

	for _, nest in ipairs(nestsFolder:GetChildren()) do
		local position = getNestPosition(nest)
		local size = getNestSize(nest)
		if position and size > largestSize then
			largestSize = size
			largestNest = nest
			largestPosition = position
		end
	end

	if not largestNest then
		statusLabel.Text = "Status: No Nest in " .. areaToFarm
		return
	end

	targetPosition = largestPosition
	movementMode = "Nest"
	isAutoMoving = true
	activePrompt = nil
	interactBtn.Visible = false
	statusLabel.Text = "Status: [" .. areaToFarm .. "] → " .. largestNest.Name
end

--========================================================
-- BUTTON EVENTS
--========================================================

largestNestBtn.MouseButton1Click:Connect(function()
	largestNestEnabled = not largestNestEnabled
	if largestNestEnabled then
		largestNestBtn.Text = "Move to Largest Nest: ON"
		largestNestBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
		moveToStand()
	else
		largestNestBtn.Text = "Move to Largest Nest: OFF"
		largestNestBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		stopMovement()
	end
end)

moveStandBtn.MouseButton1Click:Connect(moveToStand)

stopBtn.MouseButton1Click:Connect(function()
	largestNestEnabled = false
	largestNestBtn.Text = "Move to Largest Nest: OFF"
	largestNestBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	stopMovement()
end)

respawnBtn.MouseButton1Click:Connect(function()
	stopMovement()
	local character = player.Character
	if character and character:FindFirstChildOfClass("Humanoid") then
		character:FindFirstChildOfClass("Humanoid").Health = 0
	end
end)

local function replaceHumanoid()
	local character = player.Character
	if not character then return false end

	local oldHumanoid = character:FindFirstChildOfClass("Humanoid")
	if oldHumanoid then oldHumanoid:Destroy() end

	local newHumanoid = Instance.new("Humanoid")
	newHumanoid.Parent = character
	return true
end

replaceHumBtn.MouseButton1Click:Connect(function()
	if replaceHumanoid() then
		statusLabel.Text = "Status: Humanoid replaced"
	else
		statusLabel.Text = "Status: Character not found"
	end
end)

tpWalkBtn.MouseButton1Click:Connect(function()
	tpEnabled = not tpEnabled
	if tpEnabled then
		tpWalkBtn.Text = "TP Walk: ON"
		tpWalkBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	else
		tpWalkBtn.Text = "TP Walk: OFF"
		tpWalkBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	end
end)

destroyAssetsBtn.MouseButton1Click:Connect(function()
	local assets = workspace:FindFirstChild("ClientRenderedAssets")
	if assets then
		assets:Destroy()
		statusLabel.Text = "Status: Assets Destroyed"
	else
		statusLabel.Text = "Status: Assets not found"
	end
end)

serverHopBtn.MouseButton1Click:Connect(function()
	serverHopBtn.Text = "Hopping..."
	local placeId = game.PlaceId
	local success, result = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
	end)

	if not success then serverHopBtn.Text = "Server Hop"; return end

	local data
	pcall(function() data = HttpService:JSONDecode(result) end)
	if not data then serverHopBtn.Text = "Server Hop"; return end

	local servers = {}
	for _, server in ipairs(data.data or {}) do
		if server.id ~= game.JobId and server.playing < server.maxPlayers then
			table.insert(servers, server)
		end
	end

	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)].id, player)
	else
		serverHopBtn.Text = "No Server Found"
		task.wait(1)
		serverHopBtn.Text = "Server Hop"
	end
end)

--========================================================
-- SLIDER LOGIC
--========================================================

local function updateSlider(inputX)
	local trackX = sliderTrack.AbsolutePosition.X
	local trackWidth = sliderTrack.AbsoluteSize.X
	if trackWidth <= 0 then return end

	local scale = math.clamp((inputX - trackX) / trackWidth, 0, 1)
	tpSpeed = math.floor(MIN_SPEED + ((MAX_SPEED - MIN_SPEED) * scale))
	sliderButton.Position = UDim2.new(scale, -10, 0.5, -10)
	speedLabel.Text = "Speed: " .. tpSpeed
end

sliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
	end
end)

sliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = true
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSlider = false
	end
end)

--========================================================
-- PROMPT SPAMMER
--========================================================

local function getPromptPart(prompt)
	if not prompt then return nil end
	local parent = prompt.Parent
	if parent and parent:IsA("BasePart") then return parent end
	if parent and parent:IsA("Attachment") then return parent.Parent end
	return nil
end

local function findNearbyPrompt(hrp)
	local nearestPrompt = nil
	local nearestDistance = PROMPT_DISTANCE

	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("ProximityPrompt") and object.Enabled then
			local part = getPromptPart(object)
			if part and part:IsA("BasePart") then
				local distance = (hrp.Position - part.Position).Magnitude
				if distance <= nearestDistance then
					nearestDistance = distance
					nearestPrompt = object
				end
			end
		end
	end
	return nearestPrompt
end

local function spamPrompt10x()
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local hrp = character.HumanoidRootPart
	local prompt = findNearbyPrompt(hrp)

	if not prompt or not prompt.Parent or not prompt.Enabled then
		statusLabel.Text = "Status: No Prompt"
		return
	end

	activePrompt = prompt

	for i = 1, PROMPT_CLICKS do
		if not prompt.Parent or not prompt.Enabled then break end
		pcall(function()
			prompt:InputHoldBegin()
			task.wait(PROMPT_HOLD_TIME)
			prompt:InputHoldEnd()
		end)
	end

	activePrompt = nil
end

local function handleNestReached()
	statusLabel.Text = "Status: Prompt 10x"
	spamPrompt10x()
	statusLabel.Text = "Status: Prompt Done"

	if largestNestEnabled then
		task.wait(0.1)
		if largestNestEnabled then moveToStand() end
	end
end

interactBtn.MouseButton1Click:Connect(function()
	local prompt = activePrompt
	if not prompt or not prompt.Parent or not prompt.Enabled then
		activePrompt = nil
		interactBtn.Visible = false
		return
	end

	interactBtn.Visible = false
	pcall(function()
		prompt:InputHoldBegin()
		task.wait(PROMPT_HOLD_TIME)
		prompt:InputHoldEnd()
	end)
	activePrompt = nil
	statusLabel.Text = "Status: Interacted"
end)

--========================================================
-- HEARTBEAT LOOP
--========================================================

RunService.Heartbeat:Connect(function(dt)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	if isAutoMoving and targetPosition then
		local difference = targetPosition - hrp.Position
		local distance = difference.Magnitude
		local arriveDistance = (movementMode == "Nest") and NEST_DISTANCE or STAND_DISTANCE

		if distance <= arriveDistance then
			isAutoMoving = false
			local mode = movementMode
			targetPosition = nil
			movementMode = nil

			if mode == "Stand" then
				statusLabel.Text = "Status: At Safe"
				if largestNestEnabled then
					task.delay(0.2, function()
						if largestNestEnabled then moveToNextLargestNest() end
					end)
				end
			elseif mode == "Nest" then
				statusLabel.Text = "Status: Nest Reached"
				task.spawn(handleNestReached)
			end
			return
		end

		local direction = difference.Unit
		local moveAmount = math.min(tpSpeed * dt, distance)
		hrp.CFrame = hrp.CFrame + direction * moveAmount

		local lookPosition = Vector3.new(targetPosition.X, hrp.Position.Y, targetPosition.Z)
		if (lookPosition - hrp.Position).Magnitude > 0.01 then
			hrp.CFrame = CFrame.new(hrp.Position, lookPosition)
		end

	elseif tpEnabled then
		local direction = humanoid.MoveDirection
		if direction.Magnitude > 0 then
			hrp.CFrame = hrp.CFrame + direction * tpSpeed * dt
		end
	end
end)

--========================================================
-- RESPAWN HANDLER
--========================================================

player.CharacterAdded:Connect(function(character)
	stopMovement()
	statusLabel.Text = "Status: Respawn → Replace Humanoid"
	task.wait(0.5)

	if player.Character ~= character then return end
	replaceHumanoid()
	statusLabel.Text = "Status: Humanoid replaced"

	if largestNestEnabled then
		task.wait(0.5)
		if player.Character == character and largestNestEnabled then
			moveToStand()
		end
	end
end)

print("[CombinedTPWalk] Multi-Area Loaded successfully")
