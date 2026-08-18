--========================================================
-- TP WALK + MOVE STAND + RANDOM NEST
-- AUTO PROMPT SPAM 0.5s
-- AUTO REPLACE HUMANOID ON RESPAWN
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
local MAX_SPEED = 300
local DEFAULT_SPEED = 50

local STAND_DISTANCE = 2
local NEST_DISTANCE = 3
local PROMPT_DISTANCE = 12

local PROMPT_SPAM_TIME = 0.5
local PROMPT_SPAM_DELAY = 0.05

--========================================================
-- STATE
--========================================================

local tpSpeed = DEFAULT_SPEED

local tpEnabled = false
local randomNestEnabled = false

local isAutoMoving = false

local targetPosition = nil
local movementMode = nil
-- "Stand"
-- "Nest"

local activePrompt = nil
local draggingSlider = false

--========================================================
-- NOTIFICATION
--========================================================

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Combined TP Walk",
		Text = "Loaded",
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
-- GUI
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

menuBtn.BackgroundColor3 =
	Color3.fromRGB(0, 150, 255)

menuBtn.TextColor3 =
	Color3.fromRGB(255, 255, 255)

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

frame.Size = UDim2.new(0, 270, 0, 390)
frame.Position =
	UDim2.new(0.5, -135, 0.5, -195)

frame.BackgroundColor3 =
	Color3.fromRGB(30, 30, 30)

frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

--========================================================
-- TITLE
--========================================================

local title = Instance.new("TextLabel")

title.Size = UDim2.new(0.75, 0, 0, 32)
title.Position = UDim2.new(0.04, 0, 0, 3)

title.Text = "AUTO MOVE"
title.TextScaled = true
title.Font = Enum.Font.GothamBold

title.TextColor3 =
	Color3.fromRGB(255, 255, 255)

title.BackgroundTransparency = 1
title.Parent = frame

--========================================================
-- CLOSE
--========================================================

local closeBtn = Instance.new("TextButton")

closeBtn.Size = UDim2.new(0, 32, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 4)

closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold

closeBtn.BackgroundColor3 =
	Color3.fromRGB(200, 50, 50)

closeBtn.TextColor3 =
	Color3.fromRGB(255, 255, 255)

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

	button.Size =
		UDim2.new(0.90, 0, 0, 38)

	button.Position =
		UDim2.new(0.05, 0, 0, y)

	button.Text = text
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold

	button.BackgroundColor3 = color
	button.TextColor3 =
		Color3.fromRGB(255, 255, 255)

	button.AutoButtonColor = true
	button.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	return button
end

--========================================================
-- BUTTONS
--========================================================

local moveStandBtn = createButton(
	"MoveStand",
	"Move to Stand",
	42,
	Color3.fromRGB(45, 125, 230)
)

local stopBtn = createButton(
	"Stop",
	"STOP",
	84,
	Color3.fromRGB(210, 50, 50)
)

local randomNestBtn = createButton(
	"RandomNest",
	"Random Nest: OFF",
	126,
	Color3.fromRGB(100, 100, 100)
)

local respawnBtn = createButton(
	"Respawn",
	"Respawn",
	168,
	Color3.fromRGB(230, 140, 30)
)

local replaceHumanoidBtn = createButton(
	"ReplaceHumanoid",
	"Replace Humanoid",
	210,
	Color3.fromRGB(180, 60, 60)
)

local tpWalkBtn = createButton(
	"TPWalk",
	"TP Walk: OFF",
	252,
	Color3.fromRGB(100, 100, 100)
)

--========================================================
-- SPEED LABEL
--========================================================

local speedLabel = Instance.new("TextLabel")

speedLabel.Size =
	UDim2.new(0.90, 0, 0, 25)

speedLabel.Position =
	UDim2.new(0.05, 0, 0, 294)

speedLabel.Text =
	"Speed: " .. tpSpeed

speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.GothamBold

speedLabel.TextColor3 =
	Color3.fromRGB(255, 255, 255)

speedLabel.BackgroundTransparency = 1
speedLabel.Parent = frame

--========================================================
-- SLIDER
--========================================================

local sliderTrack = Instance.new("Frame")

sliderTrack.Name = "SpeedSlider"

sliderTrack.Size =
	UDim2.new(0.90, 0, 0, 8)

sliderTrack.Position =
	UDim2.new(0.05, 0, 0, 328)

sliderTrack.BackgroundColor3 =
	Color3.fromRGB(65, 65, 65)

sliderTrack.BorderSizePixel = 0
sliderTrack.Active = true
sliderTrack.Parent = frame

local sliderCorner = Instance.new("UICorner")
sliderCorner.CornerRadius = UDim.new(1, 0)
sliderCorner.Parent = sliderTrack

local initialScale =
	(DEFAULT_SPEED - MIN_SPEED)
	/
	(MAX_SPEED - MIN_SPEED)

local sliderButton = Instance.new("TextButton")

sliderButton.Name = "SliderButton"

sliderButton.Size =
	UDim2.new(0, 20, 0, 20)

sliderButton.Position =
	UDim2.new(
		initialScale,
		-10,
		0.5,
		-10
	)

sliderButton.Text = ""

sliderButton.BackgroundColor3 =
	Color3.fromRGB(0, 150, 255)

sliderButton.Parent = sliderTrack

local sliderButtonCorner = Instance.new("UICorner")
sliderButtonCorner.CornerRadius = UDim.new(1, 0)
sliderButtonCorner.Parent = sliderButton

--========================================================
-- STATUS
--========================================================

local statusLabel = Instance.new("TextLabel")

statusLabel.Size =
	UDim2.new(0.90, 0, 0, 25)

statusLabel.Position =
	UDim2.new(0.05, 0, 0, 355)

statusLabel.Text = "Status: Idle"
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.Gotham

statusLabel.TextColor3 =
	Color3.fromRGB(200, 200, 200)

statusLabel.BackgroundTransparency = 1
statusLabel.Parent = frame

--========================================================
-- INTERACT BUTTON
--========================================================

local interactBtn = Instance.new("TextButton")

interactBtn.Name = "InteractButton"

interactBtn.Size =
	UDim2.new(0, 190, 0, 42)

interactBtn.Position =
	UDim2.new(0.5, -95, 0.78, 0)

interactBtn.Text = "Interact Nest"
interactBtn.TextScaled = true
interactBtn.Font = Enum.Font.GothamBold

interactBtn.BackgroundColor3 =
	Color3.fromRGB(46, 139, 87)

interactBtn.TextColor3 =
	Color3.fromRGB(255, 255, 255)

interactBtn.Visible = false
interactBtn.Parent = screenGui

local interactCorner = Instance.new("UICorner")
interactCorner.CornerRadius = UDim.new(0, 9)
interactCorner.Parent = interactBtn

--========================================================
-- GUI TOGGLE
--========================================================

menuBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
end)

closeBtn.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

--========================================================
-- DRAG SYSTEM
--========================================================

local function makeDraggable(object)

	local dragging = false
	local dragStart = nil
	local startPosition = nil
	local dragInput = nil

	object.InputBegan:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = object.Position

			input.Changed:Connect(function()

				if input.UserInputState ==
					Enum.UserInputState.End then

					dragging = false
				end

			end)
		end
	end)

	object.InputChanged:Connect(function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragInput = input
		end

	end)

	UserInputService.InputChanged:Connect(function(input)

		if dragging and input == dragInput then

			local delta =
				input.Position - dragStart

			object.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,

				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)

		end

	end)
end

makeDraggable(frame)
makeDraggable(menuBtn)
makeDraggable(interactBtn)

--========================================================
-- STOP MOVEMENT
--========================================================

local function stopMovement()

	isAutoMoving = false
	targetPosition = nil
	movementMode = nil
	activePrompt = nil

	interactBtn.Visible = false

	statusLabel.Text = "Status: Idle"

end

--========================================================
-- MOVE TO STAND
--========================================================

local function moveToStand()

	local character = player.Character

	if not character then
		return
	end

	local hrp =
		character:FindFirstChild("HumanoidRootPart")

	if not hrp then
		return
	end

	targetPosition = STAND_POSITION
	movementMode = "Stand"
	isAutoMoving = true

	activePrompt = nil
	interactBtn.Visible = false

	statusLabel.Text =
		"Status: Moving → Stand"

end

--========================================================
-- FIND NEST FOLDER
--========================================================

local function getNestsFolder()

	local objects =
		workspace:FindFirstChild("__OBJECTS")

	if not objects then
		return nil
	end

	local areas =
		objects:FindFirstChild("Areas")

	if not areas then
		return nil
	end

	local guardAreas =
		areas:FindFirstChild("GuardAreas")

	if not guardAreas then
		return nil
	end

	local cosmic =
		guardAreas:FindFirstChild("Cosmic")

	if not cosmic then
		return nil
	end

	return cosmic:FindFirstChild("Nests")
end

--========================================================
-- GET NEST POSITION
--========================================================

local function getNestPosition(nest)

	if nest:IsA("BasePart") then
		return nest.Position
	end

	if nest:IsA("Model") then
		return nest:GetPivot().Position
	end

	return nil
end

--========================================================
-- MOVE RANDOM NEST
--========================================================

local function moveRandomNest()

	if not randomNestEnabled then
		return
	end

	local nestsFolder =
		getNestsFolder()

	if not nestsFolder then

		statusLabel.Text =
			"Status: Nests not found"

		return
	end

	local validNests = {}

	for _, nest in ipairs(
		nestsFolder:GetChildren()
	) do

		local position =
			getNestPosition(nest)

		if position then

			table.insert(validNests, {
				Object = nest,
				Position = position
			})

		end
	end

	if #validNests == 0 then

		statusLabel.Text =
			"Status: No valid Nest"

		return
	end

	local selected =
		validNests[
			math.random(
				1,
				#validNests
			)
		]

	targetPosition =
		selected.Position

	movementMode = "Nest"
	isAutoMoving = true

	activePrompt = nil
	interactBtn.Visible = false

	statusLabel.Text =
		"Status: Moving → "
		.. selected.Object.Name

end

--========================================================
-- RANDOM NEST TOGGLE
--========================================================

randomNestBtn.MouseButton1Click:Connect(function()

	randomNestEnabled =
		not randomNestEnabled

	if randomNestEnabled then

		randomNestBtn.Text =
			"Random Nest: ON"

		randomNestBtn.BackgroundColor3 =
			Color3.fromRGB(46, 139, 87)

		-- Bắt đầu từ Stand
		moveToStand()

	else

		randomNestBtn.Text =
			"Random Nest: OFF"

		randomNestBtn.BackgroundColor3 =
			Color3.fromRGB(100, 100, 100)

		stopMovement()

	end

end)

--========================================================
-- MOVE STAND BUTTON
--========================================================

moveStandBtn.MouseButton1Click:Connect(function()
	moveToStand()
end)

--========================================================
-- STOP BUTTON
--========================================================

stopBtn.MouseButton1Click:Connect(function()
	stopMovement()
end)

--========================================================
-- RESPAWN BUTTON
--========================================================

respawnBtn.MouseButton1Click:Connect(function()

	stopMovement()

	local character = player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid then
		humanoid.Health = 0
	end

end)

--========================================================
-- REPLACE HUMANOID
--========================================================

local function replaceHumanoid()

	local character = player.Character

	if not character then
		return false
	end

	local oldHumanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if oldHumanoid then
		oldHumanoid:Destroy()
	end

	local newHumanoid =
		Instance.new("Humanoid")

	newHumanoid.Parent = character

	return true
end

--========================================================
-- MANUAL REPLACE BUTTON
--========================================================

replaceHumanoidBtn.MouseButton1Click:Connect(function()

	if replaceHumanoid() then

		statusLabel.Text =
			"Status: Humanoid replaced"

	else

		statusLabel.Text =
			"Status: Character not found"

	end

end)

--========================================================
-- TP WALK TOGGLE
--========================================================

tpWalkBtn.MouseButton1Click:Connect(function()

	tpEnabled =
		not tpEnabled

	if tpEnabled then

		tpWalkBtn.Text =
			"TP Walk: ON"

		tpWalkBtn.BackgroundColor3 =
			Color3.fromRGB(46, 139, 87)

	else

		tpWalkBtn.Text =
			"TP Walk: OFF"

		tpWalkBtn.BackgroundColor3 =
			Color3.fromRGB(100, 100, 100)

	end

end)

--========================================================
-- SPEED SLIDER
--========================================================

local function updateSlider(inputX)

	local trackX =
		sliderTrack.AbsolutePosition.X

	local trackWidth =
		sliderTrack.AbsoluteSize.X

	if trackWidth <= 0 then
		return
	end

	local scale =
		math.clamp(
			(inputX - trackX) / trackWidth,
			0,
			1
		)

	tpSpeed =
		math.floor(
			MIN_SPEED +
			(
				(MAX_SPEED - MIN_SPEED)
				* scale
			)
		)

	sliderButton.Position =
		UDim2.new(
			scale,
			-10,
			0.5,
			-10
		)

	speedLabel.Text =
		"Speed: " .. tpSpeed

end

sliderButton.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingSlider = true

	end

end)

sliderTrack.InputBegan:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingSlider = true

		updateSlider(
			input.Position.X
		)

	end

end)

UserInputService.InputChanged:Connect(function(input)

	if not draggingSlider then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		updateSlider(
			input.Position.X
		)

	end

end)

UserInputService.InputEnded:Connect(function(input)

	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingSlider = false

	end

end)

--========================================================
-- GET PROMPT PART
--========================================================

local function getPromptPart(prompt)

	if not prompt then
		return nil
	end

	local parent = prompt.Parent

	if parent and parent:IsA("BasePart") then
		return parent
	end

	if parent and parent:IsA("Attachment") then
		return parent.Parent
	end

	return nil
end

--========================================================
-- FIND NEAREST PROMPT
--========================================================

local function findNearbyPrompt(hrp)

	local nearestPrompt = nil
	local nearestDistance =
		PROMPT_DISTANCE

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("ProximityPrompt")
			and object.Enabled then

			local part =
				getPromptPart(object)

			if part and part:IsA("BasePart") then

				local distance =
					(
						hrp.Position
						- part.Position
					).Magnitude

				if distance <= nearestDistance then

					nearestDistance =
						distance

					nearestPrompt =
						object

				end
			end
		end
	end

	return nearestPrompt
end

--========================================================
-- SPAM PROMPT 0.5 SECONDS
--========================================================

local function spamPromptForHalfSecond()

	local startTime =
		os.clock()

	while
		os.clock() - startTime
		< PROMPT_SPAM_TIME
	do

		local character =
			player.Character

		if not character then
			return
		end

		local hrp =
			character:FindFirstChild(
				"HumanoidRootPart"
			)

		if not hrp then
			return
		end

		local prompt =
			findNearbyPrompt(hrp)

		if prompt
			and prompt.Parent
			and prompt.Enabled then

			activePrompt = prompt

			pcall(function()

				prompt:InputHoldBegin()

				task.wait(
					math.max(
						prompt.HoldDuration,
						0.03
					)
				)

				prompt:InputHoldEnd()

			end)

			activePrompt = nil
		end

		task.wait(
			PROMPT_SPAM_DELAY
		)
	end
end

--========================================================
-- NEST REACHED
--========================================================

local function handleNestReached()

	statusLabel.Text =
		"Status: Spam Prompt 0.5s"

	-- Spam prompt trong đúng 0.5 giây
	spamPromptForHalfSecond()

	activePrompt = nil

	statusLabel.Text =
		"Status: Prompt Done"

	-- Sau khi spam xong:
	-- Nest → Stand
	if randomNestEnabled then

		task.wait(0.1)

		if randomNestEnabled then
			moveToStand()
		end

	end
end

--========================================================
-- MANUAL INTERACT
--========================================================

interactBtn.MouseButton1Click:Connect(function()

	local prompt = activePrompt

	if not prompt then
		return
	end

	if not prompt.Parent
		or not prompt.Enabled then

		activePrompt = nil
		interactBtn.Visible = false

		return
	end

	interactBtn.Visible = false

	pcall(function()

		prompt:InputHoldBegin()

		task.wait(
			math.max(
				prompt.HoldDuration,
				0.05
			)
		)

		prompt:InputHoldEnd()

	end)

	activePrompt = nil

	statusLabel.Text =
		"Status: Interacted"

end)

--========================================================
-- MAIN MOVEMENT LOOP
--========================================================

RunService.Heartbeat:Connect(function(dt)

	local character =
		player.Character

	if not character then
		return
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	local hrp =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not humanoid or not hrp then
		return
	end

	--====================================================
	-- AUTO MOVEMENT
	--====================================================

	if isAutoMoving
		and targetPosition then

		local difference =
			targetPosition - hrp.Position

		local distance =
			difference.Magnitude

		local arriveDistance

		if movementMode == "Nest" then

			arriveDistance =
				NEST_DISTANCE

		else

			arriveDistance =
				STAND_DISTANCE

		end

		--================================================
		-- ARRIVED
		--================================================

		if distance <= arriveDistance then

			isAutoMoving = false

			local mode =
				movementMode

			targetPosition = nil
			movementMode = nil

			--============================================
			-- STAND ARRIVED
			--============================================

			if mode == "Stand" then

				statusLabel.Text =
					"Status: At Stand"

				if randomNestEnabled then

					task.delay(
						0.2,
						function()

							if randomNestEnabled then
								moveRandomNest()
							end

						end
					)

				end

			--============================================
			-- NEST ARRIVED
			--============================================

			elseif mode == "Nest" then

				statusLabel.Text =
					"Status: Nest Reached"

				task.spawn(
					handleNestReached
				)

			end

			return
		end

		--================================================
		-- MOVE
		--================================================

		local direction =
			difference.Unit

		local moveAmount =
			math.min(
				tpSpeed * dt,
				distance
			)

		hrp.CFrame =
			hrp.CFrame
			+ direction * moveAmount

		-- Quay mặt về target
		local lookPosition =
			Vector3.new(
				targetPosition.X,
				hrp.Position.Y,
				targetPosition.Z
			)

		if
			(
				lookPosition
				- hrp.Position
			).Magnitude > 0.01
		then

			hrp.CFrame =
				CFrame.new(
					hrp.Position,
					lookPosition
				)

		end

	--====================================================
	-- NORMAL TP WALK
	--====================================================

	elseif tpEnabled then

		local direction =
			humanoid.MoveDirection

		if direction.Magnitude > 0 then

			hrp.CFrame =
				hrp.CFrame
				+ direction
				* tpSpeed
				* dt

		end
	end

end)

--========================================================
-- AUTO REPLACE HUMANOID ON EVERY RESPAWN
--========================================================

player.CharacterAdded:Connect(function(character)

	stopMovement()

	statusLabel.Text =
		"Status: Respawn → Replace Humanoid"

	task.wait(0.5)

	if player.Character ~= character then
		return
	end

	-- Luôn tự Replace khi respawn
	replaceHumanoid()

	statusLabel.Text =
		"Status: Humanoid replaced"

	-- Nếu Random Nest đang ON:
	-- bắt đầu lại từ Move to Stand
	if randomNestEnabled then

		task.wait(0.5)

		if player.Character == character
			and randomNestEnabled then

			moveToStand()

		end
	end
end)

--========================================================
-- DONE
--========================================================

print(
	"[CombinedTPWalk] Loaded successfully"
)