--========================================================
-- UNIVERSAL AUTO FARM HUB
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- CONFIG
--========================================================

local STAND_POSITION = Vector3.new(
544.577637,
92.0762939,
-364.869049
)

local FARM_START_CFRAME = CFrame.new(
534.314575,
68.5762939,
-369.312347,
1, 0, 0,
0, 1, 0,
0, 0, 1
)

local MIN_SPEED = 1
local MAX_SPEED = 2500
local DEFAULT_SPEED = 325

local PROMPT_TIMEOUT = 10
local MOVE_Z_OFFSET = 5

local TARGET_EGG_TEXTURE =
"rbxassetid://867619398"

local TARGET_EGG_SIZE = 4.03215

local RESET_INTERVAL = 60

--========================================================
-- STATES
--========================================================

local tpSpeed = DEFAULT_SPEED

local tpEnabled = false
local autoFarmEnabled = false
local movingSafe = false
local onlyTargetEgg = false

local destroyPetEnabled = false
local replaceHumanoidEnabled = false
local autoLoadConfig = true

local lastResetTime = tick()
local draggingSlider = false

--========================================================
-- CONFIG STORAGE
--========================================================

local CONFIG = {
Speed = DEFAULT_SPEED,
OnlyTargetEgg = false,
TargetSize = 4.03215,
AutoFarm = false,
TPWalk = false,
DestroyPet = false,
ReplaceHumanoid = false,
AutoLoadConfig = true
}

--========================================================
-- CLEAN OLD UI
--========================================================

local oldUI =
playerGui:FindFirstChild("SimpleAutoFarmUI")

if oldUI then
oldUI:Destroy()
end

--========================================================
-- GUI
--========================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleAutoFarmUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0,55,0,55)
openBtn.Position = UDim2.new(0,15,0.12,0)
openBtn.Text = "HUB"
openBtn.Font = Enum.Font.SourceSansBold
openBtn.TextSize = 16
openBtn.BackgroundColor3 = Color3.fromRGB(0,150,255)
openBtn.TextColor3 = Color3.fromRGB(255,255,255)
openBtn.Active = true
openBtn.Parent = screenGui

Instance.new("UICorner",openBtn).CornerRadius =
UDim.new(0,10)

--========================================================
-- MAIN FRAME
--========================================================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0,320,0,390)
mainFrame.Position = UDim2.new(0.5,-160,0.5,-195)
mainFrame.BackgroundColor3 = Color3.fromRGB(25,25,30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Visible = true
mainFrame.Parent = screenGui

Instance.new("UICorner",mainFrame).CornerRadius =
UDim.new(0,10)

--========================================================
-- HEADER
--========================================================

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-40,0,40)
title.Position = UDim2.new(0,10,0,0)
title.Text = "AUTO FARM HUB"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.BackgroundTransparency = 1
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0,30,0,30)
closeBtn.Position = UDim2.new(1,-35,0,5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Parent = mainFrame

Instance.new("UICorner",closeBtn).CornerRadius =
UDim.new(0,6)

--========================================================
-- TABS
--========================================================

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1,-20,0,30)
tabFrame.Position = UDim2.new(0,10,0,40)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = mainFrame

local function makeTabBtn(text,posScale)

local b = Instance.new("TextButton")  

b.Size = UDim2.new(0.31,0,1,0)  
b.Position = UDim2.new(posScale,0,0,0)  
b.Text = text  
b.Font = Enum.Font.SourceSansBold  
b.TextSize = 14  
b.BackgroundColor3 = Color3.fromRGB(40,40,50)  
b.TextColor3 = Color3.fromRGB(200,200,200)  
b.Parent = tabFrame  

Instance.new("UICorner",b).CornerRadius =  
	UDim.new(0,6)  

return b

end

local tabMainBtn = makeTabBtn("Main",0)
local tabTargetBtn = makeTabBtn("Target",0.34)
local tabMiscBtn = makeTabBtn("Settings",0.68)

--========================================================
-- PAGES
--========================================================

local container = Instance.new("Frame")
container.Size = UDim2.new(1,-20,0,255)
container.Position = UDim2.new(0,10,0,75)
container.BackgroundTransparency = 1
container.Parent = mainFrame

local function createPage()

local p = Instance.new("ScrollingFrame")  

p.Size = UDim2.new(1,0,1,0)  
p.BackgroundTransparency = 1  
p.ScrollBarThickness = 4  
p.Visible = false  
p.Parent = container  

local layout = Instance.new("UIListLayout")  
layout.Padding = UDim.new(0,6)  
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center  
layout.Parent = p  

layout:GetPropertyChangedSignal(  
	"AbsoluteContentSize"  
):Connect(function()  

	p.CanvasSize =  
		UDim2.new(  
			0,0,  
			0,  
			layout.AbsoluteContentSize.Y + 10  
		)  
end)  

return p

end

local pageMain = createPage()
local pageTarget = createPage()
local pageMisc = createPage()

pageMain.Visible = true

tabMainBtn.BackgroundColor3 =
Color3.fromRGB(0,150,255)

--========================================================
-- STATUS
--========================================================

local statusLabel = Instance.new("TextLabel")

statusLabel.Size =
UDim2.new(1,-20,0,35)

statusLabel.Position =
UDim2.new(0,10,1,-40)

statusLabel.BackgroundColor3 =
Color3.fromRGB(35,35,45)

statusLabel.Text = "Status: Idle"

statusLabel.Font =
Enum.Font.SourceSansBold

statusLabel.TextSize = 14

statusLabel.TextColor3 =
Color3.fromRGB(0,255,150)

statusLabel.Parent = mainFrame

Instance.new("UICorner",statusLabel).CornerRadius =
UDim.new(0,6)

--========================================================
-- TAB FUNCTION
--========================================================

local function showTab(btn,page)

for _,b in ipairs({  
	tabMainBtn,  
	tabTargetBtn,  
	tabMiscBtn  
}) do  
	b.BackgroundColor3 =  
		Color3.fromRGB(40,40,50)  
end  

for _,p in ipairs({  
	pageMain,  
	pageTarget,  
	pageMisc  
}) do  
	p.Visible = false  
end  

btn.BackgroundColor3 =  
	Color3.fromRGB(0,150,255)  

page.Visible = true

end

tabMainBtn.MouseButton1Click:Connect(function()
showTab(tabMainBtn,pageMain)
end)

tabTargetBtn.MouseButton1Click:Connect(function()
showTab(tabTargetBtn,pageTarget)
end)

tabMiscBtn.MouseButton1Click:Connect(function()
showTab(tabMiscBtn,pageMisc)
end)

--========================================================
-- UI HELPERS
--========================================================

local function addToggle(page,text,default,callback)

local b = Instance.new("TextButton")  

b.Size = UDim2.new(1,-4,0,35)  

local state = default  

local function refresh()  

	b.Text =  
		text .. ": " ..  
		(state and "ON" or "OFF")  

	b.BackgroundColor3 =  
		state  
		and Color3.fromRGB(0,170,80)  
		or Color3.fromRGB(50,55,65)  
end  

refresh()  

b.Font = Enum.Font.SourceSansBold  
b.TextSize = 14  
b.TextColor3 = Color3.fromRGB(255,255,255)  
b.Parent = page  

Instance.new("UICorner",b).CornerRadius =  
	UDim.new(0,6)  

b.MouseButton1Click:Connect(function()  

	state = not state  
	refresh()  

	callback(state)  

end)  

return b

end

local function addButton(page,text,color,callback)

local b = Instance.new("TextButton")  

b.Size = UDim2.new(1,-4,0,35)  
b.Text = text  
b.Font = Enum.Font.SourceSansBold  
b.TextSize = 14  

b.BackgroundColor3 =  
	color or Color3.fromRGB(50,55,65)  

b.TextColor3 =  
	Color3.fromRGB(255,255,255)  

b.Parent = page  

Instance.new("UICorner",b).CornerRadius =  
	UDim.new(0,6)  

b.MouseButton1Click:Connect(callback)  

return b

end

--========================================================
-- DROP HELD EGG
--========================================================

local function isEggHeld()

local dropGui =  
	playerGui:FindFirstChild("DropHeldEgg")  

return dropGui  
	and dropGui.Enabled == true

end

--========================================================
-- AREA EGG SLOTS
--========================================================

local function getEggSlots()

return workspace:FindFirstChild(  
	"AreaEggSlotsClient"  
)

end

--========================================================
-- EGG TARGETS
--========================================================

local function getEggTargets()

local result = {}  
local slots = getEggSlots()  

if not slots then  
	return result  
end  

for _,egg in ipairs(  
	slots:GetChildren()  
) do  

	local hitbox =  
		egg:FindFirstChild("Hitbox")  

	if hitbox  
		and hitbox:IsA("BasePart") then  

		table.insert(result,egg)  
	end  
end  

return result

end

--========================================================
-- TARGET TEXTURE
--========================================================

local function hasTargetParticle(egg)

if not egg then  
	return false  
end  

for _,obj in ipairs(  
	egg:GetDescendants()  
) do  

	if obj:IsA("ParticleEmitter")  
		and tostring(obj.Texture)  
			== TARGET_EGG_TEXTURE then  

		return true  
	end  
end  

return false

end

--========================================================
-- TARGET SIZE
--========================================================

local function getTargetSize(egg)

if not egg then  
	return nil  
end  

local hitbox =  
	egg:FindFirstChild("Hitbox")  

if not hitbox  
	or not hitbox:IsA("BasePart") then  

	return nil  
end  

local s = hitbox.Size  

return (  
	s.X +  
	s.Y +  
	s.Z  
) / 3

end

--========================================================
-- TARGET FILTER
--========================================================

local function isTargetEgg(egg)

local size =  
	getTargetSize(egg)  

if not size then  
	return false  
end  

if size < TARGET_EGG_SIZE then  
	return false  
end  

if not onlyTargetEgg then  
	return true  
end  

return hasTargetParticle(egg)

end

--========================================================
-- EGG POSITION
--========================================================

local function getEggPosition(egg)

if not egg then  
	return nil  
end  

local hitbox =  
	egg:FindFirstChild("Hitbox")  

if hitbox  
	and hitbox:IsA("BasePart") then  

	return hitbox.Position  
end  

if egg:IsA("BasePart") then  
	return egg.Position  
end  

if egg:IsA("Model") then  
	return egg:GetPivot().Position  
end  

local part =  
	egg:FindFirstChildWhichIsA(  
		"BasePart",  
		true  
	)  

return part and part.Position

end

--========================================================
-- NEAREST TARGET
--========================================================

local function getNearestTarget()

local char =  
	player.Character  

if not char then  
	return nil  
end  

local hrp =  
	char:FindFirstChild(  
		"HumanoidRootPart"  
	)  

if not hrp then  
	return nil  
end  

local nearest  
local nearestDistance = math.huge  

for _,egg in ipairs(  
	getEggTargets()  
) do  

	if isTargetEgg(egg) then  

		local pos =  
			getEggPosition(egg)  

		if pos then  

			local distance =  
				(hrp.Position - pos).Magnitude  

			if distance <  
				nearestDistance then  

				nearestDistance =  
					distance  

				nearest = egg  
			end  
		end  
	end  
end  

return nearest

end

--========================================================
-- SHARED TP MOVEMENT
--========================================================

local function tpMoveTo(
targetPosition,
threshold,
shouldContinue
)

threshold = threshold or 3  

while true do  

	if shouldContinue  
		and not shouldContinue() then  

		return false  
	end  

	local character =  
		player.Character  

	if not character then  
		RunService.Heartbeat:Wait()  
		continue  
	end  

	local hrp =  
		character:FindFirstChild(  
			"HumanoidRootPart"  
		)  

	if not hrp then  
		RunService.Heartbeat:Wait()  
		continue  
	end  

	local offset =  
		targetPosition - hrp.Position  

	local distance =  
		offset.Magnitude  

	if distance <= threshold then  
		return true  
	end  

	local dt =  
		RunService.Heartbeat:Wait()  

	local moveAmount =  
		math.min(  
			tpSpeed * dt,  
			distance  
		)  

	if offset.Magnitude > 0 then  

		hrp.CFrame =  
			hrp.CFrame  
			+ offset.Unit  
			* moveAmount  
	end  
end

end

--========================================================
-- RETURN SAFE
--========================================================

local function returnToSafe()

local oldAuto =  
	autoFarmEnabled  

autoFarmEnabled = false  
movingSafe = true  

statusLabel.Text =  
	"Status: Moving To Safe..."  

local success =  
	tpMoveTo(  
		STAND_POSITION,  
		2,  
		function()  
			return movingSafe  
		end  
	)  

movingSafe = false  

if oldAuto then  
	autoFarmEnabled = true  
end  

if success then  

	statusLabel.Text =  
		oldAuto  
		and "Status: Waiting Egg..."  
		or "Status: At Safe"  

else  

	statusLabel.Text =  
		"Status: Safe Move Stopped"  
end  

return success

end

--========================================================
-- WAIT TARGET
--========================================================

local function waitForTarget()

statusLabel.Text =  
	"Status: Waiting Egg..."  

while autoFarmEnabled do  

	if isEggHeld() then  

		returnToSafe()  
		task.wait(0.1)  
		continue  
	end  

	local target =  
		getNearestTarget()  

	if target then  

		statusLabel.Text =  
			"Status: Egg Found"  

		return target  
	end  

	task.wait(0.1)  
end  

return nil

end

--========================================================
-- NEAREST PROMPT
--========================================================

local function getNearestPrompt(position)

local nearestPrompt  
local nearestDistance = math.huge  

for _,obj in ipairs(  
	workspace:GetDescendants()  
) do  

	if obj:IsA("ProximityPrompt")  
		and obj.Enabled then  

		local parent = obj.Parent  

		if parent  
			and parent:IsA("BasePart") then  

			local distance =  
				(parent.Position - position)  
				.Magnitude  

			if distance <  
				nearestDistance then  

				nearestDistance =  
					distance  

				nearestPrompt =  
					obj  
			end  
		end  
	end  
end  

return nearestPrompt

end

--========================================================
-- TRIGGER PROMPT
--========================================================

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
-- PROMPT TARGET
--========================================================

local function promptTarget(egg)

local startTime = tick()  

while autoFarmEnabled do  

	if isEggHeld() then  
		return true  
	end  

	if not egg  
		or not egg.Parent then  

		return false  
	end  

	local char =  
		player.Character  

	local hrp =  
		char  
		and char:FindFirstChild(  
			"HumanoidRootPart"  
		)  

	if not hrp then  
		task.wait()  
		continue  
	end  

	local prompt =  
		getNearestPrompt(  
			hrp.Position  
		)  

	if prompt then  

		statusLabel.Text =  
			"Status: Spamming Prompt"  

		for i = 1,10 do  

			if not autoFarmEnabled then  
				return false  
			end  

			if isEggHeld() then  
				return true  
			end  

			if prompt  
				and prompt.Parent  
				and prompt.Enabled then  

				triggerPrompt(prompt)  
			end  
		end  

	else  

		statusLabel.Text =  
			"Status: No Prompt Nearby"  
	end  

	if tick() - startTime  
		>= PROMPT_TIMEOUT then  

		statusLabel.Text =  
			"Status: Prompt Timeout"  

		return false  
	end  

	task.wait(0.01)  
end  

return false

end

--========================================================
-- PROMPT HOLD = 0
--========================================================

ProximityPromptService.PromptShown:Connect(
function(prompt)

pcall(function()  
		prompt.HoldDuration = 0  
	end)  
end

)

--========================================================
-- AUTO FARM
--========================================================

task.spawn(function()

while true do  

	task.wait(0.05)  

	if not autoFarmEnabled then  
		continue  
	end  

	--================================================  
	-- FIRST FARM POSITION  
	--================================================  

	statusLabel.Text =  
		"Status: Going To Farm Start..."  

	local reachedStart =  
		tpMoveTo(  
			FARM_START_CFRAME.Position,  
			2,  
			function()  
				return autoFarmEnabled  
			end  
		)  

	if not reachedStart  
		or not autoFarmEnabled then  

		continue  
	end  

	local char =  
		player.Character  

	local hrp =  
		char  
		and char:FindFirstChild(  
			"HumanoidRootPart"  
		)  

	if hrp then  
		hrp.CFrame =  
			FARM_START_CFRAME  
	end  

	--================================================  
	-- FARM LOOP  
	--================================================  

	local target =  
		waitForTarget()  

	if not target  
		or not autoFarmEnabled then  

		continue  
	end  

	local targetPos =  
		getEggPosition(target)  

	if not targetPos then  
		continue  
	end  

	targetPos =  
		targetPos  
		+ Vector3.new(  
			0,  
			0,  
			MOVE_Z_OFFSET  
		)  

	statusLabel.Text =  
		"Status: MoveTo Egg Z+5"  

	local reached =  
		tpMoveTo(  
			targetPos,  
			3,  
			function()  
				return autoFarmEnabled  
			end  
		)  

	if not reached  
		or not autoFarmEnabled then  

		continue  
	end  

	--================================================  
	-- PROMPT  
	--================================================  

	statusLabel.Text =  
		"Status: Prompting..."  

	local success =  
		promptTarget(target)  

	--================================================  
	-- EGG HELD  
	--================================================  

	if success  
		and isEggHeld() then  

		returnToSafe()  
		continue  
	end  

	task.wait(0.1)  
end

end)

--========================================================
-- MAIN TOGGLES
--========================================================

addToggle(
pageMain,
"Auto Farm",
false,
function(state)

autoFarmEnabled = state  

	if state then  

		statusLabel.Text =  
			"Status: Going To Farm Start..."  

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
function(state)

tpEnabled = state  
end

)

--========================================================
-- SAFE BUTTON
--========================================================

addButton(
pageMain,
"Move to Safe Position",
Color3.fromRGB(0,120,200),
function()

if movingSafe then  
		return  
	end  

	task.spawn(function()  

		local oldAuto =  
			autoFarmEnabled  

		autoFarmEnabled = false  
		movingSafe = true  

		statusLabel.Text =  
			"Status: Moving Safe..."  

		local success =  
			tpMoveTo(  
				STAND_POSITION,  
				2,  
				function()  
					return movingSafe  
				end  
			)  

		movingSafe = false  
		autoFarmEnabled = oldAuto  

		statusLabel.Text =  
			success  
			and "Status: At Safe"  
			or "Status: Safe Move Stopped"  
	end)  
end

)

--========================================================
-- SPEED SLIDER
--========================================================

local sliderBox = Instance.new("Frame")

sliderBox.Size =
UDim2.new(1,-4,0,48)

sliderBox.BackgroundColor3 =
Color3.fromRGB(40,42,52)

sliderBox.Parent = pageMain

Instance.new("UICorner",sliderBox).CornerRadius =
UDim.new(0,6)

local speedText =
Instance.new("TextLabel")

speedText.Size =
UDim2.new(1,-10,0,20)

speedText.Position =
UDim2.new(0,8,0,4)

speedText.Text =
"Speed: " .. tpSpeed

speedText.Font =
Enum.Font.SourceSansBold

speedText.TextSize = 13
speedText.TextColor3 =
Color3.fromRGB(255,255,255)

speedText.TextXAlignment =
Enum.TextXAlignment.Left

speedText.BackgroundTransparency = 1
speedText.Parent = sliderBox

local sliderTrack =
Instance.new("Frame")

sliderTrack.Size =
UDim2.new(1,-16,0,8)

sliderTrack.Position =
UDim2.new(0,8,0,28)

sliderTrack.BackgroundColor3 =
Color3.fromRGB(60,65,80)

sliderTrack.Parent = sliderBox

Instance.new("UICorner",sliderTrack).CornerRadius =
UDim.new(1,0)

local sliderBtn =
Instance.new("TextButton")

sliderBtn.Size =
UDim2.new(0,16,0,16)

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
Color3.fromRGB(0,150,255)

sliderBtn.Parent = sliderTrack

Instance.new("UICorner",sliderBtn).CornerRadius =
UDim.new(1,0)

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
		(inputX - trackPos) / trackLen,  
		0,  
		1  
	)  

tpSpeed =  
	math.floor(  
		MIN_SPEED  
		+  
		(MAX_SPEED - MIN_SPEED)  
		* scale  
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

sliderBtn.InputBegan:Connect(function(input)

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

	updateSpeedSlider(  
		input.Position.X  
	)  
end

end)

UserInputService.InputChanged:Connect(function(input)

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
-- TARGET SETTINGS
--========================================================

addToggle(
pageTarget,
"Only Target Egg",
false,
function(state)

onlyTargetEgg = state  

	statusLabel.Text =  
		state  
		and "Status: Target Egg ON"  
		or "Status: Target Egg OFF"  
end

)

--========================================================
-- TARGET SIZE
--========================================================

local sizeBox =
Instance.new("TextBox")

sizeBox.Size =
UDim2.new(1,-4,0,35)

sizeBox.Text =
tostring(TARGET_EGG_SIZE)

sizeBox.PlaceholderText =
"Minimum Average Hitbox Size"

sizeBox.ClearTextOnFocus = false
sizeBox.Font =
Enum.Font.SourceSansBold

sizeBox.TextSize = 14
sizeBox.TextColor3 =
Color3.fromRGB(255,255,255)

sizeBox.BackgroundColor3 =
Color3.fromRGB(50,55,65)

sizeBox.Parent = pageTarget

Instance.new("UICorner",sizeBox).CornerRadius =
UDim.new(0,6)

sizeBox.FocusLost:Connect(function()

local value =  
	tonumber(sizeBox.Text)  

if value and value > 0 then  

	TARGET_EGG_SIZE = value  

	sizeBox.Text =  
		tostring(value)  

	statusLabel.Text =  
		"Status: Min Size = " .. value  

else  

	sizeBox.Text =  
		tostring(TARGET_EGG_SIZE)  
end

end)

--========================================================
-- TARGET INFO
--========================================================

local targetInfo =
Instance.new("TextLabel")

targetInfo.Size =
UDim2.new(1,-4,0,100)

targetInfo.Text =
"Egg: AreaEggSlotsClient children\n"
.. "Name: RANDOM\n"
.. "Size: Average Hitbox X/Y/Z\n"
.. "Texture: "
.. TARGET_EGG_TEXTURE
.. "\nColor: IGNORED\n"
.. "MoveTo: Egg Position + Z5"

targetInfo.Font =
Enum.Font.SourceSansBold

targetInfo.TextSize = 13
targetInfo.TextColor3 =
Color3.fromRGB(220,220,220)

targetInfo.BackgroundColor3 =
Color3.fromRGB(40,42,52)

targetInfo.Parent = pageTarget

Instance.new("UICorner",targetInfo).CornerRadius =
UDim.new(0,6)

--========================================================
-- REPLACE HUMANOID
-- WITH JUMP SUPPORT
--========================================================

local function replaceHumanoid(char)

if not char then  
	return nil  
end  

local oldHumanoid =  
	char:FindFirstChildOfClass("Humanoid")  

if oldHumanoid then  
	oldHumanoid:Destroy()  
end  

local newHumanoid =  
	Instance.new("Humanoid")  

newHumanoid.Name = "Humanoid"  

--====================================================  
-- JUMP  
--====================================================  

newHumanoid.UseJumpPower = true  
newHumanoid.JumpPower = 50  
newHumanoid.JumpHeight = 7.2  
newHumanoid.AutoJumpEnabled = true  

--====================================================  
-- MOVEMENT  
--====================================================  

newHumanoid.WalkSpeed = 16  

--====================================================  
-- PARENT  
--====================================================  

newHumanoid.Parent = char  

--====================================================  
-- ROOT PART  
--====================================================  

local hrp =  
	char:FindFirstChild("HumanoidRootPart")  

if hrp then  
	newHumanoid.RootPart = hrp  
end  

return newHumanoid

end

--========================================================
-- REPLACE HUMANOID TOGGLE
--========================================================

addToggle(
pageMisc,
"Replace Humanoid",
false,
function(state)

replaceHumanoidEnabled = state  

	if state then  

		local char =  
			player.Character  

		if char then  

			local newHumanoid =  
				replaceHumanoid(char)  

			if newHumanoid then  

				statusLabel.Text =  
					"Status: Humanoid Replaced + Jump ON"  

			else  

				statusLabel.Text =  
					"Status: Replace Failed"  

			end  

		else  

			statusLabel.Text =  
				"Status: Character Not Found"  
		end  

	else  

		statusLabel.Text =  
			"Status: Replace Humanoid OFF"  
	end  
end

)

--========================================================
-- DESTROY PET TOGGLE
--========================================================

addToggle(
pageMisc,
"Destroy Pet Assets",
false,
function(state)

destroyPetEnabled = state  

	if state then  

		local assets =  
			workspace:FindFirstChild(  
				"ClientRenderedAssets"  
			)  

		if assets then  
			assets:Destroy()  
		end  

		statusLabel.Text =  
			"Status: Pet Assets Destroyed"  

	else  

		statusLabel.Text =  
			"Status: Destroy Pet OFF"  
	end  
end

)

--========================================================
-- AUTO LOAD CONFIG TOGGLE
--========================================================

addToggle(
pageMisc,
"Auto Load Config",
true,
function(state)

autoLoadConfig = state  
end

)

--========================================================
-- SAVE / LOAD
--========================================================

local function collectConfig()

return {  
	Speed = tpSpeed,  
	OnlyTargetEgg = onlyTargetEgg,  
	TargetSize = TARGET_EGG_SIZE,  
	AutoFarm = autoFarmEnabled,  
	TPWalk = tpEnabled,  
	DestroyPet = destroyPetEnabled,  
	ReplaceHumanoid = replaceHumanoidEnabled,  
	AutoLoadConfig = autoLoadConfig  
}

end

local function applyConfig(data)

if type(data) ~= "table" then  
	return  
end  

if tonumber(data.Speed) then  

	tpSpeed =  
		math.clamp(  
			tonumber(data.Speed),  
			MIN_SPEED,  
			MAX_SPEED  
		)  
end  

if type(data.OnlyTargetEgg) == "boolean" then  
	onlyTargetEgg =  
		data.OnlyTargetEgg  
end  

if tonumber(data.TargetSize)  
	and tonumber(data.TargetSize) > 0 then  

	TARGET_EGG_SIZE =  
		tonumber(data.TargetSize)  
end  

if type(data.TPWalk) == "boolean" then  
	tpEnabled =  
		data.TPWalk  
end  

if type(data.AutoLoadConfig) == "boolean" then  
	autoLoadConfig =  
		data.AutoLoadConfig  
end

end

--========================================================
-- SAVE CONFIG
--========================================================

addButton(
pageMisc,
"Save Config",
Color3.fromRGB(0,130,90),
function()

local data =  
		collectConfig()  

	statusLabel.Text =  
		"Status: Config Ready To Save"  
end

)

--========================================================
-- LOAD CONFIG
--========================================================

addButton(
pageMisc,
"Load Config",
Color3.fromRGB(80,100,180),
function()

statusLabel.Text =  
		"Status: Config Ready To Load"  
end

)

--========================================================
-- SERVER HOP
--========================================================

addButton(
pageMisc,
"Server Hop",
Color3.fromRGB(40,100,180),
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
-- DRAG
--========================================================

local function enableDrag(frame)

local dragging = false  
local dragStart  
local startPos  

frame.InputBegan:Connect(function(input)  

	if input.UserInputType ==  
		Enum.UserInputType.MouseButton1  
		or input.UserInputType ==  
		Enum.UserInputType.Touch then  

		dragging = true  
		dragStart = input.Position  
		startPos = frame.Position  
	end  
end)  

UserInputService.InputChanged:Connect(function(input)  

	if dragging  
		and (  
			input.UserInputType ==  
				Enum.UserInputType.MouseMovement  
			or input.UserInputType ==  
				Enum.UserInputType.Touch  
		) then  

		local delta =  
			input.Position - dragStart  

		frame.Position =  
			UDim2.new(  
				startPos.X.Scale,  
				startPos.X.Offset + delta.X,  
				startPos.Y.Scale,  
				startPos.Y.Offset + delta.Y  
			)  
	end  
end)  

UserInputService.InputEnded:Connect(function(input)  

	if input.UserInputType ==  
		Enum.UserInputType.MouseButton1  
		or input.UserInputType ==  
		Enum.UserInputType.Touch then  

		dragging = false  
	end  
end)

end

enableDrag(mainFrame)
enableDrag(openBtn)

--========================================================
-- HUB BUTTON
--========================================================

openBtn.MouseButton1Click:Connect(function()

mainFrame.Visible =  
	not mainFrame.Visible

end)

closeBtn.MouseButton1Click:Connect(function()

mainFrame.Visible = false

end)

--========================================================
-- MANUAL TP WALK
--========================================================

RunService.Heartbeat:Connect(function(dt)

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
		+ hum.MoveDirection  
		* tpSpeed  
		* dt  
end

end)

--========================================================
-- CHARACTER RESPAWN
--========================================================

player.CharacterAdded:Connect(function(char)

task.wait(1)  

--====================================================  
-- REPLACE HUMANOID + JUMP  
--====================================================  

if replaceHumanoidEnabled then  

	local newHumanoid =  
		replaceHumanoid(char)  

	if newHumanoid then  

		newHumanoid.UseJumpPower = true  
		newHumanoid.JumpPower = 50  
		newHumanoid.JumpHeight = 7.2  
		newHumanoid.AutoJumpEnabled = true  

		statusLabel.Text =  
			"Status: Respawned + Humanoid Replaced"  

	end  
end  

--====================================================  
-- DESTROY PET  
--====================================================  

if destroyPetEnabled then  

	local assets =  
		workspace:FindFirstChild(  
			"ClientRenderedAssets"  
		)  

	if assets then  
		assets:Destroy()  
	end  
end

end)

--========================================================
-- DONE
--========================================================

statusLabel.Text =
"Status: Idle"
