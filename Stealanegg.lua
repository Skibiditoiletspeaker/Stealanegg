--========================================================
-- UNIVERSAL AUTO FARM HUB
-- SPEED: 1 - 2500 | DEFAULT: 500
-- PROMPT TIMEOUT: 10 SECONDS
-- HUB BUTTON: HIGHER POSITION
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

--========================================================
-- CONFIG
--========================================================

local STAND_POSITION = Vector3.new(
	544.577637,
	92.0762939,
	-364.869049
)

local MIN_SPEED = 1
local MAX_SPEED = 2500
local DEFAULT_SPEED = 325

local PROMPT_TIMEOUT = 10
local RESET_INTERVAL = 60

--========================================================
-- STATES
--========================================================

local tpSpeed = DEFAULT_SPEED

local tpEnabled = false
local autoFarmEnabled = false
local movingSafe = false

local selectedAreas = {}
local areaOrder = {}
local currentAreaIndex = 1

local visitedEggs = {}
local lastResetTime = tick()

local draggingSlider = false

--========================================================
-- CLEAN OLD UI
--========================================================

local playerGui = player:WaitForChild("PlayerGui")

local oldUI = playerGui:FindFirstChild("SimpleAutoFarmUI")

if oldUI then
	oldUI:Destroy()
end

--========================================================
-- SCREEN GUI
--========================================================

local screenGui = Instance.new("ScreenGui")

screenGui.Name = "SimpleAutoFarmUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

--========================================================
-- HUB BUTTON
--========================================================

local openBtn = Instance.new("TextButton")

openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0, 55, 0, 55)

-- Đưa HUB lên cao hơn
openBtn.Position = UDim2.new(0, 15, 0.12, 0)

openBtn.Text = "HUB"
openBtn.Font = Enum.Font.SourceSansBold
openBtn.TextSize = 16

openBtn.BackgroundColor3 =
	Color3.fromRGB(0, 150, 255)

openBtn.TextColor3 =
	Color3.fromRGB(255, 255, 255)

openBtn.Active = true
openBtn.Parent = screenGui

Instance.new("UICorner", openBtn).CornerRadius =
	UDim.new(0, 10)

--========================================================
-- MAIN FRAME
--========================================================

local mainFrame = Instance.new("Frame")

mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 380)

mainFrame.Position =
	UDim2.new(0.5, -160, 0.5, -190)

mainFrame.BackgroundColor3 =
	Color3.fromRGB(25, 25, 30)

mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius =
	UDim.new(0, 10)

--========================================================
-- HEADER
--========================================================

local title = Instance.new("TextLabel")

title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 10, 0, 0)

title.Text = "AUTO FARM HUB"

title.Font = Enum.Font.SourceSansBold
title.TextSize = 18

title.TextColor3 =
	Color3.fromRGB(255, 255, 255)

title.TextXAlignment =
	Enum.TextXAlignment.Left

title.BackgroundTransparency = 1
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")

closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)

closeBtn.Text = "X"

closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16

closeBtn.BackgroundColor3 =
	Color3.fromRGB(200, 50, 50)

closeBtn.TextColor3 =
	Color3.fromRGB(255, 255, 255)

closeBtn.Parent = mainFrame

Instance.new("UICorner", closeBtn).CornerRadius =
	UDim.new(0, 6)

--========================================================
-- TABS
--========================================================

local tabFrame = Instance.new("Frame")

tabFrame.Size = UDim2.new(1, -20, 0, 30)
tabFrame.Position = UDim2.new(0, 10, 0, 40)

tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local function makeTabBtn(text, posScale)

	local b = Instance.new("TextButton")

	b.Size = UDim2.new(0.31, 0, 1, 0)
	b.Position = UDim2.new(posScale, 0, 0, 0)

	b.Text = text

	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 14

	b.BackgroundColor3 =
		Color3.fromRGB(40, 40, 50)

	b.TextColor3 =
		Color3.fromRGB(200, 200, 200)

	b.Parent = tabFrame

	Instance.new("UICorner", b).CornerRadius =
		UDim.new(0, 6)

	return b
end

local tabMainBtn =
	makeTabBtn("Main", 0)

local tabAreaBtn =
	makeTabBtn("Areas", 0.34)

local tabMiscBtn =
	makeTabBtn("Settings", 0.68)

--========================================================
-- PAGES
--========================================================

local container = Instance.new("Frame")

container.Size = UDim2.new(1, -20, 0, 250)
container.Position = UDim2.new(0, 10, 0, 75)

container.BackgroundTransparency = 1
container.Parent = mainFrame

local function createPage()

	local p = Instance.new("ScrollingFrame")

	p.Size = UDim2.new(1, 0, 1, 0)

	p.BackgroundTransparency = 1
	p.ScrollBarThickness = 4

	p.Visible = false
	p.Parent = container

	local layout = Instance.new("UIListLayout")

	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment =
		Enum.HorizontalAlignment.Center

	layout.Parent = p

	layout:GetPropertyChangedSignal(
		"AbsoluteContentSize"
	):Connect(function()

		p.CanvasSize =
			UDim2.new(
				0,
				0,
				0,
				layout.AbsoluteContentSize.Y + 10
			)

	end)

	return p
end

local pageMain = createPage()
local pageArea = createPage()
local pageMisc = createPage()

pageMain.Visible = true

tabMainBtn.BackgroundColor3 =
	Color3.fromRGB(0, 150, 255)

local function showTab(btn, page)

	for _, b in ipairs({
		tabMainBtn,
		tabAreaBtn,
		tabMiscBtn
	}) do

		b.BackgroundColor3 =
			Color3.fromRGB(40, 40, 50)

	end

	for _, p in ipairs({
		pageMain,
		pageArea,
		pageMisc
	}) do

		p.Visible = false

	end

	btn.BackgroundColor3 =
		Color3.fromRGB(0, 150, 255)

	page.Visible = true
end

tabMainBtn.MouseButton1Click:Connect(function()
	showTab(tabMainBtn, pageMain)
end)

tabAreaBtn.MouseButton1Click:Connect(function()
	showTab(tabAreaBtn, pageArea)
end)

tabMiscBtn.MouseButton1Click:Connect(function()
	showTab(tabMiscBtn, pageMisc)
end)

--========================================================
-- STATUS
--========================================================

local statusLabel = Instance.new("TextLabel")

statusLabel.Size =
	UDim2.new(1, -20, 0, 35)

statusLabel.Position =
	UDim2.new(0, 10, 1, -40)

statusLabel.BackgroundColor3 =
	Color3.fromRGB(35, 35, 45)

statusLabel.Text = "Status: Idle"

statusLabel.Font =
	Enum.Font.SourceSansBold

statusLabel.TextSize = 14

statusLabel.TextColor3 =
	Color3.fromRGB(0, 255, 150)

statusLabel.Parent = mainFrame

Instance.new("UICorner", statusLabel).CornerRadius =
	UDim.new(0, 6)

--========================================================
-- HELPERS
--========================================================

local function addToggle(page, text, default, callback)

	local b = Instance.new("TextButton")

	b.Size =
		UDim2.new(1, -4, 0, 35)

	local state = default

	b.Text =
		text .. ": "
		.. (state and "ON" or "OFF")

	b.Font =
		Enum.Font.SourceSansBold

	b.TextSize = 14

	b.BackgroundColor3 =
		state
		and Color3.fromRGB(0, 170, 80)
		or Color3.fromRGB(50, 55, 65)

	b.TextColor3 =
		Color3.fromRGB(255, 255, 255)

	b.Parent = page

	Instance.new("UICorner", b).CornerRadius =
		UDim.new(0, 6)

	b.MouseButton1Click:Connect(function()

		state = not state

		b.Text =
			text .. ": "
			.. (state and "ON" or "OFF")

		b.BackgroundColor3 =
			state
			and Color3.fromRGB(0, 170, 80)
			or Color3.fromRGB(50, 55, 65)

		callback(state)

	end)

end

local function addButton(page, text, color, callback)

	local b = Instance.new("TextButton")

	b.Size =
		UDim2.new(1, -4, 0, 35)

	b.Text = text

	b.Font =
		Enum.Font.SourceSansBold

	b.TextSize = 14

	b.BackgroundColor3 =
		color
		or Color3.fromRGB(50, 55, 65)

	b.TextColor3 =
		Color3.fromRGB(255, 255, 255)

	b.Parent = page

	Instance.new("UICorner", b).CornerRadius =
		UDim.new(0, 6)

	b.MouseButton1Click:Connect(callback)

end

--========================================================
-- CORE FUNCTIONS
--========================================================

local function isEggHeld()

	local pGui =
		player:FindFirstChild("PlayerGui")

	if not pGui then
		return false
	end

	local dropGui =
		pGui:FindFirstChild("DropHeldEgg")

	return dropGui
		and dropGui.Enabled == true
end

local function triggerPrompt(prompt)

	if not prompt
		or not prompt.Parent
		or not prompt.Enabled then

		return
	end

	if fireproximityprompt then

		pcall(function()
			fireproximityprompt(prompt)
		end)

	else

		pcall(function()

			prompt:InputHoldBegin()

			task.wait(0.01)

			prompt:InputHoldEnd()

		end)

	end
end

--========================================================
-- MOVE
--========================================================

local function moveToPosition(targetPos, threshold)

	threshold = threshold or 3

	while autoFarmEnabled or movingSafe do

		local char =
			player.Character

		if not char then
			task.wait()
			continue
		end

		local hrp =
			char:FindFirstChild("HumanoidRootPart")

		if not hrp then
			task.wait()
			continue
		end

		local diff =
			targetPos - hrp.Position

		local dist =
			diff.Magnitude

		if dist <= threshold then
			return true
		end

		local dt =
			RunService.Heartbeat:Wait()

		local moveAmount =
			math.min(
				tpSpeed * dt,
				dist
			)

		if diff.Magnitude > 0 then

			hrp.CFrame =
				hrp.CFrame
				+ diff.Unit * moveAmount

		end
	end

	return false
end

--========================================================
-- PROMPT SPAM + TIMEOUT
--========================================================

local function spamPromptUntilEggHeld()

	local startTime = tick()

	while autoFarmEnabled do

		-- Đã cầm egg
		if isEggHeld() then

			return true

		end

		-- Timeout 10 giây
		if tick() - startTime >= PROMPT_TIMEOUT then

			statusLabel.Text =
				"Status: Prompt Timeout"

			return false

		end

		local char =
			player.Character

		if char
			and char:FindFirstChild(
				"HumanoidRootPart"
			) then

			local hrp =
				char.HumanoidRootPart

			for _, obj in ipairs(
				workspace:GetDescendants()
			) do

				if obj:IsA("ProximityPrompt")
					and obj.Enabled then

					local part =
						obj.Parent

					local pos

					if part:IsA("BasePart") then

						pos = part.Position

					elseif part:IsA("Model") then

						pos =
							part:GetPivot().Position

					end

					if pos then

						local distance =
							(
								hrp.Position - pos
							).Magnitude

						if distance <= 30 then

							triggerPrompt(obj)

						end
					end
				end
			end
		end

		task.wait(0.03)
	end

	return false
end

--========================================================
-- PROMPT SHOWN
--========================================================

ProximityPromptService.PromptShown:Connect(
	function(prompt)

		pcall(function()

			prompt.HoldDuration = 0

		end)

	end
)

--========================================================
-- AREAS
--========================================================

local function refreshAreas()

	for _, c in ipairs(
		pageArea:GetChildren()
	) do

		if c:IsA("TextButton") then
			c:Destroy()
		end

	end

	areaOrder = {}

	local objects =
		workspace:FindFirstChild("__OBJECTS")

	local areas =
		objects
		and objects:FindFirstChild("Areas")

	local guardAreas =
		areas
		and areas:FindFirstChild("GuardAreas")

	if not guardAreas then
		return
	end

	for _, areaFolder in ipairs(
		guardAreas:GetChildren()
	) do

		if areaFolder:FindFirstChild("Nests") then

			local name =
				areaFolder.Name

			table.insert(
				areaOrder,
				name
			)

			if selectedAreas[name] == nil then

				selectedAreas[name] = true

			end

			addToggle(
				pageArea,
				name,
				selectedAreas[name],
				function(s)

					selectedAreas[name] = s

				end
			)
		end
	end
end

refreshAreas()

--========================================================
-- NEST SEARCH
--========================================================

local function getNextAreaName()

	if #areaOrder == 0 then
		return nil
	end

	for i = 1, #areaOrder do

		local idx =
			(
				(
					currentAreaIndex - 1
					+ i - 1
				)
				% #areaOrder
			) + 1

		local name =
			areaOrder[idx]

		if selectedAreas[name] then

			currentAreaIndex =
				(idx % #areaOrder) + 1

			return name

		end
	end

	return nil
end

local function getSortedNestsInArea(areaName)

	local objects =
		workspace:FindFirstChild("__OBJECTS")

	local areas =
		objects
		and objects:FindFirstChild("Areas")

	local guardAreas =
		areas
		and areas:FindFirstChild("GuardAreas")

	local areaFolder =
		guardAreas
		and guardAreas:FindFirstChild(areaName)

	local nestsFolder =
		areaFolder
		and areaFolder:FindFirstChild("Nests")

	if not nestsFolder then
		return {}
	end

	local nestList = {}

	for _, nest in ipairs(
		nestsFolder:GetChildren()
	) do

		local pos
		local size = 0

		if nest:IsA("BasePart") then

			pos = nest.Position
			size = nest.Size.Magnitude

		elseif nest:IsA("Model") then

			pos =
				nest:GetPivot().Position

			size =
				nest:GetExtentsSize().Magnitude

		end

		if pos then

			local alreadyPicked = false

			for _, vPos in ipairs(
				visitedEggs
			) do

				if (
					pos - vPos
				).Magnitude < 3 then

					alreadyPicked = true
					break

				end
			end

			if not alreadyPicked then

				table.insert(
					nestList,
					{
						pos = pos,
						size = size
					}
				)

			end
		end
	end

	table.sort(
		nestList,
		function(a, b)

			return a.size > b.size

		end
	)

	return nestList
end

--========================================================
-- MAIN AUTO FARM
--========================================================

task.spawn(function()

	while true do

		task.wait(0.3)

		if autoFarmEnabled then

			-- Reset visited sau mỗi 60 giây
			if tick() - lastResetTime
				>= RESET_INTERVAL then

				visitedEggs = {}
				lastResetTime = tick()

			end

			local areaName =
				getNextAreaName()

			if areaName then

				statusLabel.Text =
					"Status: Check "
					.. areaName

				local sortedNests =
					getSortedNestsInArea(
						areaName
					)

				if #sortedNests == 0 then

					visitedEggs = {}

					sortedNests =
						getSortedNestsInArea(
							areaName
						)

				end

				if #sortedNests > 0 then

					local target =
						sortedNests[1]

					statusLabel.Text =
						"Status: Going Nest ("
						.. math.floor(
							target.size
						)
						.. ")"

					local reached =
						moveToPosition(
							target.pos,
							3
						)

					if reached
						and autoFarmEnabled then

						statusLabel.Text =
							"Status: Picking..."

						local success =
							spamPromptUntilEggHeld()

						-- Dù thành công hay timeout
						-- đều đánh dấu nest đã xử lý
						table.insert(
							visitedEggs,
							target.pos
						)

						if success
							and autoFarmEnabled then

							statusLabel.Text =
								"Status: Returning..."

							moveToPosition(
								STAND_POSITION,
								2
							)

							if autoFarmEnabled then

								statusLabel.Text =
									"Status: At Safe"

								task.wait(0.5)

							end

						elseif autoFarmEnabled then

							statusLabel.Text =
								"Status: Prompt Timeout"

							task.wait(0.2)

						end
					end
				end
			end
		end
	end
end)

--========================================================
-- MAIN UI
--========================================================

addToggle(
	pageMain,
	"Auto Farm",
	false,
	function(s)

		autoFarmEnabled = s

		if s then

			lastResetTime = tick()

			statusLabel.Text =
				"Status: Starting..."

		else

			statusLabel.Text =
				"Status: Idle"

		end
	end
)

addToggle(
	pageMain,
	"TP Walk",
	false,
	function(s)

		tpEnabled = s

	end
)

addButton(
	pageMain,
	"Move to Safe Position",
	Color3.fromRGB(0, 120, 200),
	function()

		if movingSafe then
			return
		end

		statusLabel.Text =
			"Status: Moving Safe..."

		task.spawn(function()

			movingSafe = true

			-- Tạm dừng farm trong lúc đi safe
			local oldAuto =
				autoFarmEnabled

			autoFarmEnabled = false

			local success =
				moveToPosition(
					STAND_POSITION,
					2
				)

			movingSafe = false

			autoFarmEnabled = oldAuto

			if success then

				statusLabel.Text =
					"Status: At Safe"

			else

				statusLabel.Text =
					"Status: Safe Move Stopped"

			end
		end)
	end
)

--========================================================
-- SPEED SLIDER
--========================================================

local sliderBox = Instance.new("Frame")

sliderBox.Size =
	UDim2.new(1, -4, 0, 48)

sliderBox.BackgroundColor3 =
	Color3.fromRGB(40, 42, 52)

sliderBox.Parent = pageMain

Instance.new("UICorner", sliderBox).CornerRadius =
	UDim.new(0, 6)

local speedText = Instance.new("TextLabel")

speedText.Size =
	UDim2.new(1, -10, 0, 20)

speedText.Position =
	UDim2.new(0, 8, 0, 4)

speedText.Text =
	"Speed: " .. tpSpeed

speedText.Font =
	Enum.Font.SourceSansBold

speedText.TextSize = 13

speedText.TextColor3 =
	Color3.fromRGB(255, 255, 255)

speedText.TextXAlignment =
	Enum.TextXAlignment.Left

speedText.BackgroundTransparency = 1

speedText.Parent = sliderBox

local sliderTrack = Instance.new("Frame")

sliderTrack.Size =
	UDim2.new(1, -16, 0, 8)

sliderTrack.Position =
	UDim2.new(0, 8, 0, 28)

sliderTrack.BackgroundColor3 =
	Color3.fromRGB(60, 65, 80)

sliderTrack.Parent = sliderBox

Instance.new("UICorner", sliderTrack).CornerRadius =
	UDim.new(1, 0)

local sliderBtn = Instance.new("TextButton")

sliderBtn.Size =
	UDim2.new(0, 16, 0, 16)

local initScale =
	(DEFAULT_SPEED - MIN_SPEED)
	/
	(MAX_SPEED - MIN_SPEED)

sliderBtn.Position =
	UDim2.new(
		initScale,
		-8,
		0.5,
		-8
	)

sliderBtn.Text = ""

sliderBtn.BackgroundColor3 =
	Color3.fromRGB(0, 150, 255)

sliderBtn.Parent = sliderTrack

Instance.new("UICorner", sliderBtn).CornerRadius =
	UDim.new(1, 0)

local function updateSpeedSlider(inputX)

	local trackPos =
		sliderTrack.AbsolutePosition.X

	local trackLen =
		sliderTrack.AbsoluteSize.X

	if trackLen <= 0 then
		return
	end

	local scale =
		math.clamp(
			(inputX - trackPos)
			/ trackLen,
			0,
			1
		)

	tpSpeed =
		math.floor(
			MIN_SPEED
			+
			(
				(MAX_SPEED - MIN_SPEED)
				* scale
			)
		)

	sliderBtn.Position =
		UDim2.new(
			scale,
			-8,
			0.5,
			-8
		)

	speedText.Text =
		"Speed: " .. tpSpeed
end

sliderBtn.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			draggingSlider = true

		end
	end
)

sliderTrack.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			draggingSlider = true

			updateSpeedSlider(
				input.Position.X
			)

		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if draggingSlider
			and (
				input.UserInputType ==
					Enum.UserInputType.MouseMovement
				or input.UserInputType ==
					Enum.UserInputType.Touch
			) then

			updateSpeedSlider(
				input.Position.X
			)

		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			draggingSlider = false

		end
	end
)

--========================================================
-- SETTINGS
--========================================================

addButton(
	pageMisc,
	"Bypass Anti-Cheat (New Hum)",
	Color3.fromRGB(180, 60, 60),
	function()

		local char =
			player.Character

		if char then

			local oldHum =
				char:FindFirstChildOfClass(
					"Humanoid"
				)

			if oldHum then
				oldHum:Destroy()
			end

			local newHum =
				Instance.new("Humanoid")

			newHum.Parent = char

			statusLabel.Text =
				"Status: Humanoid Replaced"

		end
	end
)

addButton(
	pageMisc,
	"Destroy Pet Assets",
	Color3.fromRGB(180, 100, 40),
	function()

		local assets =
			workspace:FindFirstChild(
				"ClientRenderedAssets"
			)

		if assets then

			assets:Destroy()

			statusLabel.Text =
				"Status: Assets Destroyed"

		else

			statusLabel.Text =
				"Status: Assets Not Found"

		end
	end
)

addButton(
	pageMisc,
	"Server Hop",
	Color3.fromRGB(40, 100, 180),
	function()

		statusLabel.Text =
			"Status: Hopping..."

		pcall(function()

			TeleportService:Teleport(
				game.PlaceId,
				player
			)

		end)
	end
)

--========================================================
-- DRAG SYSTEM
--========================================================

local function enableDrag(frame)

	local dragging = false
	local dragStart
	local startPos

	frame.InputBegan:Connect(
		function(input)

			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or input.UserInputType ==
				Enum.UserInputType.Touch then

				dragging = true

				dragStart =
					input.Position

				startPos =
					frame.Position

			end
		end
	)

	UserInputService.InputChanged:Connect(
		function(input)

			if dragging
				and (
					input.UserInputType ==
						Enum.UserInputType.MouseMovement
					or input.UserInputType ==
						Enum.UserInputType.Touch
				) then

				local delta =
					input.Position
					- dragStart

				frame.Position =
					UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset
							+ delta.X,

						startPos.Y.Scale,
						startPos.Y.Offset
							+ delta.Y
					)

			end
		end
	)

	UserInputService.InputEnded:Connect(
		function(input)

			if input.UserInputType ==
				Enum.UserInputType.MouseButton1
				or input.UserInputType ==
				Enum.UserInputType.Touch then

				dragging = false

			end
		end
	)
end

enableDrag(mainFrame)
enableDrag(openBtn)

--========================================================
-- HUB ON / OFF
--========================================================

openBtn.MouseButton1Click:Connect(
	function()

		mainFrame.Visible =
			not mainFrame.Visible

	end
)

closeBtn.MouseButton1Click:Connect(
	function()

		mainFrame.Visible = false

	end
)

--========================================================
-- TP WALK
--========================================================

RunService.Heartbeat:Connect(
	function(dt)

		if not tpEnabled
			or autoFarmEnabled
			or movingSafe then

			return

		end

		local char =
			player.Character

		if not char then
			return
		end

		local hum =
			char:FindFirstChildOfClass(
				"Humanoid"
			)

		local hrp =
			char:FindFirstChild(
				"HumanoidRootPart"
			)

		if hum
			and hrp
			and hum.MoveDirection.Magnitude > 0 then

			hrp.CFrame =
				hrp.CFrame
				+
				hum.MoveDirection
				* tpSpeed
				* dt

		end
	end
)

--========================================================
-- FINAL STATUS
--========================================================

statusLabel.Text =
	"Status: Idle"
