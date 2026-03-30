-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Referencing Replicated Storage
local Players = game:GetService("Players") -- Referencing Players
local UIS = game:GetService("UserInputService") -- Referencing User Input Service to get when a player presses a button
local TweenService = game:GetService("TweenService") -- Referencing Tween Service to animate UI
local Debris = game:GetService("Debris") -- Referencing Debris Service to eliminate any instance.new objects

-- Initial Scripts --
local GUN = script.Parent -- Referencing the tool this is attached to so I dont have to constantly copy and paste it
local SHOOTPART = GUN:WaitForChild("Shootpart") -- The part where the beam comes out of
local Player = Players.LocalPlayer -- Referenceing the player
local Mouse = Player:GetMouse() -- Getting the players mouse so we can get where they click

-- Modules --
local GunSettings = require(GUN:WaitForChild("GunLocal"):WaitForChild("GunSettings")) -- The Gun Scripts client settings (For getting max ammo, fire rate etc)

-- Gun Settings --
local Ammo = GunSettings.Ammo -- Copying the guns ammo over to a variable here
local MaxAmmo = GunSettings.MaxAmmo -- Copying the guns max ammo to a variable here

-- Gun Variables
local totalDamage = 0 -- This is the variable for my Stack Damage indicators that shows how much total damage has been dealt prior to resetting
local fadeTimerId = 0 -- This is the variable for my fade timer for how long until the stack damage indicator has until it resets and disappears (Tweens itself to not be visible)
local indicatorVisible = false -- Checking if the damage indicator is currently visible
local CurrentRotation = -180 -- The current rotation for the Hit Marker (If the hitmarker option is set to "Rotate")
local Debounce = false -- This is the debounce variable for the gun in between each shot
local RELOADDEBOUNCE = false -- This is the debounce for each reload tick
local IsReloading = false -- This variable is to check if the player is currently reloading
local Equipped = false -- Checking if the gun is currently equipped
local FadeDelay = 1 -- This is the Delay until the "Stack" damage indicator fades away
local FadeTime = 0.1 -- This is the time the "Stack" damage indicator takes to fade away
local ShowTIme = 0.85 -- This is how long the "Stack" damage indicator is shown for
local indicatorVisible = false -- This is used to help set how long the fade timer is visible for
local Holding = false -- This is to check if the player is holding the gun

-- Remote Events --
local RemoteEvents= ReplicatedStorage:WaitForChild("RemoteEvents") -- Referencing my Remote Events folder
local Event = RemoteEvents:WaitForChild("Shoot") -- Referencing my Shoot Event
local KillmarkerEvent = RemoteEvents:WaitForChild("KillEvent") -- Referencing my Kill Event

-- UI --
local StarterGui = Player.PlayerGui -- Getting the Players UI
local Main = StarterGui:WaitForChild("UI") -- Getting the Main UI for the gun
local AmmoBar = Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("AmmoBar") -- Getting the Ammo bar for the gun
local AmmoCircle = AmmoBar:WaitForChild("UIStroke"):WaitForChild("UIGradient") -- Getting the Ammo "Circle" (Aka the bar around the circle)
local CanvasGroup = Main:WaitForChild("Main"):WaitForChild("CanvasGroup") -- Getting the canvas group that the gun icon is visible for
local IconTweenFrame = Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("IconTween") -- The UI holder which contains all of the gun icons
local PageLayout = IconTweenFrame:WaitForChild("UIPageLayout") -- Getting the page layout from the IconTweenFrame

-- Sounds --
local Sounds = GUN:WaitForChild("Handle"):WaitForChild("Sounds") -- Getting all of the sounds for the gun
local ReloadSound = Sounds:WaitForChild("Reload") -- The Reload Sound
local ShootSound = Sounds:WaitForChild("Shoot") -- The Shoot Sound
local ConsistentReload = Sounds:WaitForChild("ConsistentReload") -- The "Tick" sound in between each pellet being reloaded for the gun
local HitSound = Sounds:WaitForChild("Hit") -- THe hit sound for whenever a player hits another player

-- Setting Values --
local Settings = Player:WaitForChild("Settings") -- The settings folder created by the server, which is parented inside of the Player
local HitmarkerTypeSetting:StringValue = Settings:WaitForChild("HitmarkerType") -- The Setting which determines which Hitmarker Type to use
local KillmarkerSetting:BoolValue = Settings:WaitForChild("Killmarker") -- The setting which determines if the Kill Marker is on or not

-- Cursor UI --
local CursorUi = StarterGui:WaitForChild("CursorUi") -- Getting the UI that constantly follows the cursor 
local CursorFrame = CursorUi:WaitForChild("Frame") -- The frame thats constantly following the cursor
local KillMarker = CursorFrame:WaitForChild("KillMarker") -- The Killmarker Image thats a child inside of the Cursor Frame
local KillMarkerStroke = KillMarker:WaitForChild("UIStroke") -- The stroke of the killmarker

-- Hitmarker UI -- 
local HitmarkerUi = CursorFrame:WaitForChild("Hitmarker") -- The Hit Marker UI Frame
local HitmarkerImage = HitmarkerUi:WaitForChild("HitmarkerIcon") -- The Hitmarker UI Image

-- Functions --
-- This function is for tweening the transparency of the UI 
function tweenTransparency(guiObject, targetTransparency, duration) -- This gets the UI object, what to tween the transparency to, and how long it should take to complete each tween
	for _, obj in ipairs(guiObject:GetDescendants()) do -- for each object inside of the GUI object, get all of the descendents inside
		if obj:IsA("TextLabel")  then -- if the descendant is a text label then: 
			TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = targetTransparency,}):Play() -- Tween the transparency of the text by its duration, set the transparencyt to whatever the target transparency is, with the quad easing style, and out option.
		end
	end
end

-- Updates the ammo bar ui (Which is a circle) --
function ClientServices:UpdateCircle(Ammo, MaxAmmo) --  We get the Ammo/Max Ammo of the gun to see what the size needs to be set to
	if Equipped == true then -- If the gun is currently equipped then:
		AmmoCircle.Parent.Color = Color3.fromRGB(255, 255, 255) -- Change the color of the ammo circle to show its equipped
		
		if Ammo < MaxAmmo then -- If the players ammo isnt fully loaded then:
	
			-- Edits the transparency of the "AmmoCircle" (Which is the ui gradient for the stroke of the "Ammo Bar UI")--
			AmmoCircle.Transparency = NumberSequence.new( -- Change the circles "UI Gradients" transparency
				{
					NumberSequenceKeypoint.new(0,0),-- Set to 0
					NumberSequenceKeypoint.new(Ammo/MaxAmmo,0), -- Set to whatever Ammo/MaxAmmo is (If this is 1 then it'll be full so we divide it to ensure we display how full the gun should be)
					NumberSequenceKeypoint.new((Ammo/MaxAmmo)+.001,1), -- Similar top the top, however we incriment it by .001 so its not exactly the same, and properly displays how much ammo is inside of the gun
					NumberSequenceKeypoint.new(1,1), -- Sets the final keypoint to 1 so that the right side is visible
				}
	
			)
		elseif Ammo == MaxAmmo then -- If the gun's ammo is full then:
			-- If the ammo is max itll just make the circle appear full --
			AmmoCircle.Transparency = NumberSequence.new( -- Edit the circles "UI Gradients" transparency so that:
				{
					NumberSequenceKeypoint.new(0,0),-- The left side is fully visible
					NumberSequenceKeypoint.new(1,0), -- And the right side is fully visible
				}
	
			)
		elseif Ammo == 0 then
			-- If the ammo is empty itll 0 it --
			AmmoCircle.Transparency = NumberSequence.new( -- edit the circles "UI Gradients" transparency to:
				{
					NumberSequenceKeypoint.new(0,1), -- Set the left side to be invisible
					NumberSequenceKeypoint.new(1,1), -- And the right side to be invisible
				}
	
			)
		end
		local Percentage = (Ammo/MaxAmmo)*100 -- This essentially returns a percentage of the Ammo
	
		-- This converts the ammo from an amount to a percentage --
		Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("AmmoPercentage").Text = math.round(Percentage) .. "%"
	end
end

-- Damage Indicator --
local function indicate(Part, Damage, Firerate, Charge, ChargeDamage) -- Here whenever a damage indicator is being made we get: The part it hit, the damage being inflicted, the fire rate of the gun (To properly display our stack indicator for a set amount of time), checking if theres charge (For recon or charge guns), and if there is charge then how much the damage for the charge is.
	-- Checks if the Damage Indicator Setting is true --
	if Settings:WaitForChild("DmgIndicator").Value == true then
		-- If the setting value is stack, then: --
		if Settings:WaitForChild("Stack").Value == true then
			local Shadow = CursorFrame:WaitForChild("Damage") -- There is 2 text labels, a parent text label named shadow (Which is just a dark semi transparent text label), and then a child object inside of the text label.

			-- Tweens the Text Transparency so it becomes visble --
			TweenService:Create(Shadow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {TextTransparency = 0}):Play()

			-- Update Stack Amount --
			totalDamage = Damage + totalDamage -- The total damage variable gets changed to whatever new damage is added on top of the total amount of damage inflicted.
			print(totalDamage) -- Used for debugging incase something goes wrong
			
			
			if Shadow then --if the Shadow text exists then:
				-- Charge is only applicable when a recon gun is selected (Aka a sniper) --
				if Charge and ChargeDamage > 0 then -- If there is charge, and the additional charge damage is greater than 0 then
					if Charge >= 1 then -- if the gun is fully charged when the indicator is made, it will:
						Shadow.Text = tostring(ChargeDamage) -- Make the text show its charge damage
					else -- If the gun isnt fully charged then:
						Shadow.Text = tostring(totalDamage) -- The charge damage wont be factored into the damage indicator
					end
				end
			else
				Shadow.Text = tostring(totalDamage) -- If there is no charge, just show the damage noramlly
			end

			-- Change Color on Heaadshot --
			if Part.Name == "Head" then -- If the part name that got hit is called head then:
				Shadow.TextColor3 = Color3.fromRGB(255, 70, 70) -- Change the text color to be red
			else
				Shadow.TextColor3 = Color3.fromRGB(255, 255, 255) -- Otherwise set it to be white
			end

			-- Keep TextStroke visible only on main text --
			Shadow.TextStrokeTransparency = 0 -- Set the stroke to be 0
			if Shadow then -- if the shadow exists:
				Shadow.TextStrokeTransparency = 1 -- Set its transparency to 1
			end

			-- Tween visible (main text only, not the shadow) --
			if not indicatorVisible then -- If the indicator isnt visible then
				indicatorVisible = true -- Make it visible
				tweenTransparency(Shadow, 0, ShowTime) -- Tween the transparency of the indicator to make it visible
			end

			-- Fade timer logic --
			fadeTimerId = Firerate + fadeTimerId -- Increase the fadeTimer time by the fire rate
			local thisTimerId = fadeTimerId -- Set the current timer for this weapon to fadetimer

			task.delay(FadeDelay, function() -- Wait by "Fade Delay" seconds, then:
				if thisTimerId == fadeTimerId then -- If the current timer is equal to the fade timer ID then:
					-- Fade out main text only, keep shadow --
					tweenTransparency(Shadow, 1, FadeTime) -- Set the damage indicator to be invisible
					indicatorVisible = false -- Variable it to being invisible so the rest of the script knows the damage indicator is no longer visible
					totalDamage = 0 -- Reset the total damage variable to 0
					print("Resetting Damage") -- For debugging
				end
			end)
		else
			-- If the stacking setting isnt enabled, then it'll make a physical damage indicator as opposed to a UI one, and parent it to the character of the hit player --
			local indicator = script:WaitForChild("DmgIndicator"):Clone() -- Clone the "BillboardGUI" object named "DmgIndicator" thats a child inside of this script
			indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage -- Set the Text inside of the frame inside of the Billbaord GUI to whatever damage is being inflicted
			if Charge then -- If there is charge then
				if Charge >= 1 then -- if its fully charged then
					indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = tostring(ChargeDamage) -- Set the text to the charge damage
				else -- Otherwise:
					indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage -- Set the text to only have the normal damage
				end
			else -- If there is no charge then:
				indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage -- Only show the damage normally
			end
			
			indicator.Enabled = true -- Set the billboard UI to be enabled (Since by default its not enabled)
			if Part.Name == "Head" then -- If the part thats being hit is the head then:
				indicator:WaitForChild("Frame"):WaitForChild("Damage").TextColor3 = Color3.fromRGB(255, 70, 70) -- Change the text color to red
			end
			local Attachment = Instance.new("Part") -- Create a new part (This is going to be used as the parent for the damage indicator)
			Attachment.Transparency = 1 -- Set its transparency to 1
			Attachment.Anchored = true -- Anchor it so it doesnt fall
			Attachment.CanCollide = false -- Turn off collisions so that it doesnt interact with anything
			Attachment.CanQuery = false -- Disable its querying so that we cant shoot it
			Attachment.Position = Part.Position -- Set its position to wherever the hit part is
			Attachment.Parent = workspace -- Parent it to workspace so it actually exists
			Attachment.Size = Vector3.new(0.001,0.001,0.001) -- Set its size to be extremely small
			indicator.Parent = Attachment --  Set the parent of the indicator billboard ui clone to the new part we made
			local Ran1 = math.random(1,2) -- This is to get a random number between 1 or 2.
			local RandomSide -- Leaving this asa blank variable for now, but it will be used for which side the damage indicator comes out of
			if Ran1 == 1 then -- If its 1 then:
				indicator.SizeOffset = Vector2.new(1,0) -- Set the Size offset to come via the right side
				RandomSide = Vector2.new(3,0) -- Set the Side that the indicator comes out of to the right
			else
				indicator.SizeOffset = Vector2.new(-1,0) -- Otherwise set the size offset to -1
				RandomSide = Vector2.new(-3,0) -- Change the side it comes out of to the left
			end
			Debris:AddItem(indicator, 1.1) -- After 1.1 seconds, have debris service destroy the indicator billboard clone (Also a fail safe in case for whatever reason the end size tween doesnt work, itll have it destroyed regardless)

			local IndicatorTween = TweenService:Create(indicator, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {SizeOffset = RandomSide}) -- This is the tween that tweens the size offset size (To animate it moving)
			IndicatorTween:Play() -- Plays the indicator tween
			IndicatorTween.Completed:Connect(function() -- When the indicator tween is finished then:
				local IndicatorTween = TweenService:Create(indicator, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {Size = UDim2.new(0,0,0,0)}):Play() -- Tween its size to 0 so it looks smooth
			end)
		end
	end
end

-- This is the Hit Marker thats stuck to the cursor via the UI, it'll play whenever you hit something --
local function hitMarker()
	if Settings:WaitForChild("Hitmarker").Value == true then -- If the Player has hitmarkers turned on then:
		if HitmarkerTypeSetting.Value == "Expand" then 	-- If the option is expand it'll play a tween animation that expands the size of the hitmarker, then tweens the transparency simultaniously
			HitmarkerImage.Rotation = 0 -- Reset the rotation in case the player is swapping from rotation to this
			HitmarkerImage.Size = UDim2.new(.4,0,.4,0) -- Set the size to a really small one
			HitmarkerImage.ImageTransparency = 0 -- Set the image transparency of the hitmarker image to be visible
			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Set the hit markers color to white (It changes to red upon the player getting a kill)
			local SizeTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {Size = UDim2.new(1.5,0,1.5,0)}) -- Tween the size up to 1.5 x 1.5 (Scale)
			TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play() -- Set the image transparency to 1 so that it becomes invisible in .4 seconds
			SizeTween:Play() -- Play the size tween
			SizeTween.Completed:Connect(function() -- When the tween is done:
				HitmarkerImage.ImageTransparency = 1 -- Ensure the transparency is 1
				HitmarkerImage.Size = UDim2.new(.4,0,.4,0) -- Reset its size
			end)
		elseif HitmarkerTypeSetting.Value == "Rotate" then 	-- If the option is rotate then it'll rotate the hitmarker, if the rotation is 180 or greater than 180 then it'll reset the cursors rotation 
			HitmarkerImage.Size = UDim2.new(1,0,1,0) -- Set the size of the hitmarker to default (1x1 scale)
			HitmarkerImage.ImageTransparency = 0 -- Ensure the hitmarkers fully visible
			if CurrentRotation >= 180 then -- If the current rotation is greater than or equal to 180 degrees then:
				CurrentRotation = -180 -- Reset it to -180
				HitmarkerImage.Rotation = CurrentRotation -- Set the hitmarker image's rotation to 0
			end
			CurrentRotation = CurrentRotation + 20 -- Every time the hitMarker() function is called increase the current rotation of the hitmarker by 20 degrees
			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Ensure the image color is white (It changes to red upon the player getting a kill)
			local RotationTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {Rotation = CurrentRotation}) -- Tween the rotation of the hitmarker
			RotationTween:Play() -- Play the RotationTween

			TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play() -- Simultaniously tween the transparency of the hitmarkers image
			RotationTween.Completed:Connect(function() -- When the rotation tween is done,
				HitmarkerImage.ImageTransparency = 1 -- Ensure that the image transparency is set back to 1 just in case

			end)
		elseif HitmarkerTypeSetting.Value == "Fade" then -- If the option is fade it'll just make the hitmarker fade in, then fade out via its image transparency
			HitmarkerImage.Rotation = 0 -- Reset its rotation to 0
			HitmarkerImage.Size = UDim2.new(1,0,1,0) -- Ensure the size is correct
			HitmarkerImage.ImageTransparency = .1 -- Set the image transparency to already be semi transparent


			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Ensure the colors set to white as when you get a kill it changes the hitmarker color to red


			local FadeTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 0}) -- Set the hitmarkers tween to be fully visible
			FadeTween:Play() -- Play the tween

			FadeTween.Completed:Connect(function() -- When this tween is done:
				TweenService:Create(HitmarkerImage, TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play() -- Tween it again so that the Hit Marker is invisible
			end)
		end
	end
end

-- Simulate Beam --
local function Beam(StartPos, EndPos, PlrShooting, plr)
	-- Create the Beam --
	local beam = Instance.new("Beam")
	local Attachment1 = Instance.new("Attachment", workspace.Terrain)
	local Attachment2 = Instance.new("Attachment", workspace.Terrain)

	Attachment1.Name = "Attachment1"
	Attachment2.Name = "Attachment2"
	Attachment1.Position = StartPos
	Attachment2.Position = EndPos

	-- Beam Physical Attributes --
	beam.Name = Player.Name
	beam.Color = ColorSequence.new(PlrShooting.TeamColor.Color)
	beam.Attachment0 = Attachment1
	beam.Attachment1 = Attachment2
	beam.Parent = workspace
	beam.FaceCamera = true
	
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Brightness = 1
	
	if Settings:WaitForChild("DynamicRays").Value == false then
		-- If Dynamic Rays are off then make the beam a solid beam --
		beam.Texture = 0
		beam.TextureSpeed = 0 
		beam.Transparency = NumberSequence.new(0,1)
		beam.Texture = 'rbxassetid://2950987178'
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.TextureSpeed = 4
		beam.Width0 = 0.2
		beam.Width1 = 0.1
		Debris:AddItem(beam, .025)
		Debris:AddItem(Attachment1, .1)
		Debris:AddItem(Attachment2, .1)
	else 
		-- If Dynamic Rays are on then it'll play an "Animation" via the beam texture, speed, and length --
		beam.Texture = 'rbxassetid://11226108137'
		beam.TextureSpeed = 4
		beam.Transparency = NumberSequence.new(0,0)
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.TextureLength = .8
		beam.Width0 = 1.3
		beam.Width1 = 1.5
		Debris:AddItem(beam, .04)
		Debris:AddItem(Attachment1, .04)
		Debris:AddItem(Attachment2, .04)
	end
end

-- This function increases the amount of "Ammo" via the variable, plays a sound, and updates the ammo bar's circle --
local function Reload()
	IsReloading = true
	RELOADDEBOUNCE = true
	ReloadSound:Play()
	while Ammo < MaxAmmo do
		task.wait(GunSettings.ReloadWait)
		RELOADDEBOUNCE = true
		Ammo += 1
		ConsistentReload:Play()
		UpdateCircle()
	end
	RELOADDEBOUNCE = false
	IsReloading = false
end

-- Spread Handler (provides a random point inside of a cone) --
local function RandomCone(axis, angle)
	local cosAngle = math.cos(angle)
	local z = 1 - math.random() * (1 - cosAngle)
	local phi = math.random() * math.pi * 2
	local r = math.sqrt(1 - z * z)
	local x, y = r * math.cos(phi), r * math.sin(phi)
	local vec = Vector3.new(x, y, z)
	if axis.Z > 0.9999 then
		return vec
	elseif axis.Z < -0.9999 then
		return -vec
	end
	local orth = Vector3.zAxis:Cross(axis)
	local rot = math.acos(axis:Dot(Vector3.zAxis))
	return CFrame.fromAxisAngle(orth, rot) * vec
end

-- Adds a box around the hit part --
local function hitBox(Part)
	if Settings:WaitForChild("Hitboxes").Value == true then
		local hitbox = script:WaitForChild("SelectionBox"):Clone()
		if Part.Name == "Head" then
			hitbox.Color3 = Color3.fromRGB(113, 0, 0)
		else
			hitbox.Color3 = Color3.fromRGB(255, 255, 255)
		end
		hitbox.Parent = Part
		hitbox.Adornee = Part
		Debris:AddItem(hitbox, 1.1)
		-- Tweens the transparency of the box --
		local HitboxTween = TweenService:Create(hitbox, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {Transparency = 0})
		HitboxTween:Play()
		HitboxTween.Completed:Connect(function()
			TweenService:Create(hitbox, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {Transparency = 1}):Play()
		end)
	end
end


-- Handles the Ray --
local function commitRay(MouseHitPosition, ShellCount, MinDistance, MaxDistance, Spread, Shootpart, ShootSound, HitSound, HeadshotDamage, Damage, Firerate, Charge, ChargeDamage)
	-- Adds Hits/Misses to a table --
	local Hits = {}
	local Misses = {}
	local Origin = Player.Character:WaitForChild("Head").Position
	local Endpoint = MouseHitPosition
	
	for i=ShellCount, 1, -1 do
		-- Added shell count for shotgun's --
		local Params = RaycastParams.new()
		Params.FilterDescendantsInstances = {script.Parent, Player.Character}
		Params.FilterType = Enum.RaycastFilterType.Exclude
		local Axis = (Endpoint - Origin).Unit
		-- Adds Spread --
		local Direction = RandomCone(Axis, math.rad(Spread)) * MaxDistance
		local AxisLength = (Endpoint-Origin).Magnitude
		if AxisLength <= MinDistance then
			-- If the target is close enough, then don't add spread --
			Direction = (Endpoint - Origin).Unit * 10000
		end
		local RaycastResult = workspace:Raycast(Origin,Direction,Params)
		-- If something gets hit then:
		if RaycastResult then
			-- Play shoot sound and handle raycasts
			ShootSound:Play()
			local Hit = RaycastResult.Instance
			local Position = RaycastResult.Position

			ClientServices:Beam(Shootpart.Position, Position, Player)
			if Hit:IsA("BasePart") then
				if Hit.Parent:FindFirstChild("Humanoid") or Hit.Parent.Parent:FindFirstChild("Humanoid") then

					local Humanoid = Hit.Parent:FindFirstChild("Humanoid") or Hit.Parent.Parent:FindFirstChild("Humanoid")
					if Humanoid.Health > 0 then
						if RaycastResult.Instance.Name == "Head" then
							-- Adds a hitbox around the hit part --
							hitBox(RaycastResult.Instance)

							-- Indicates the damage caused prior to firing to the server so it feels more instant --
							indicate(RaycastResult.Instance,HeadshotDamage,Firerate, Charge, ChargeDamage)

							-- adds a HitMarker --
							hitMarker(RaycastResult.Instance)
							HitSound:Play()

							-- A sound that plays whenever a player gets hit will play --
							local NewHit = HitSound:Clone()
							NewHit.Parent = HitSound.Parent
							NewHit:Play()
							Debris:AddItem(NewHit, 2)	
						else
							-- Indicates a body shot, thus triggering a hitbox to the body, the damage indicator is modified to a body shot damage indicator, then the hitmarker is triggered along with the hit sound object. --
							ClientServices:hitBox(RaycastResult.Instance)
							indicate(RaycastResult.Instance,Damage,Firerate, Charge, ChargeDamage)							
							hitMarker(RaycastResult.Instance)
							HitSound:Play()
							local NewHit = HitSound:Clone()
							NewHit.Parent = HitSound.Parent
							NewHit:Play()
							Debris:AddItem(NewHit, 2)
						end
						-- This inserts all hits, the hit player character, the instance of what the raycast has hit, and the position of what was hit --
						table.insert(Hits, {Humanoid.Parent, RaycastResult.Instance, RaycastResult.Position})
					else
						-- If the player hit a dead player then it'll count it as a miss --
						table.insert(Misses, RaycastResult.Position)
					end
				else
					-- If the player didnt hit another player then itll count it as a miss --
					table.insert(Misses, RaycastResult.Position)

				end
			end
		else
			-- If the player didnt hit a base part, it'll get where the player would have hit if something were there, and count as a miss --
			ShootSound:Play()
			local Position = Direction+Origin
			table.insert(Misses, Position)
			Beam(Shootpart.Position, Position, Player)

		end
	end

	-- Sends to the server once via a remote event to prevent overloading a server, sending everything via its table values, along with the guns properties --
	Event:FireServer(Shootpart.Position, Hits, Misses, Damage, HeadshotDamage, Charge, ChargeDamage)	
end



-- When the gun tool is activated, it checks if the gun's being held, theres enough ammo, and we're not currently reloading --
GUN.Activated:Connect(function()
	Holding = true

	while Holding and Ammo > 0 and RELOADDEBOUNCE == false do
		if not Debounce then
			Debounce = true
			-- MouseHitPosition, ShellCount, MinDistance, MaxDistance, Spread, Shootpart, ShootSound, HitSound, HeadshotDamage, Damage, Firerate, Charge, ChargeDamage
			ClientServices:commitRay(Mouse.Hit.Position, GunSettings.ShellCount, GunSettings.MinDistance, GunSettings.MaxDistance, GunSettings.Spread, SHOOTPART, ShootSound, HitSound, GunSettings.HeadshotDamage, GunSettings.Damage, GunSettings.Firerate, nil, nil)
			Ammo -= 1
			UpdateCircle()
			ShootSound:Play()

			task.delay(GunSettings.Firerate, function()
				Debounce = false
			end)
		end

		task.wait()
	end

	-- Auto Reload Function --
	if Ammo <= 0 then
		Reload()
	end
end)

-- When the gun's equipped it'll initialize the UI --
GUN.Equipped:Connect(function()
	Equipped = true
	Sounds:WaitForChild("GunEquip"):Play()
	CanvasGroup:WaitForChild("ToolName").Text = GUN.Name
	if IconTweenFrame:FindFirstChild(GUN.Name) then
		PageLayout:JumpTo(IconTweenFrame:WaitForChild(GUN.Name))
	else
		local GunIcon = script:WaitForChild("Template"):Clone()
		GunIcon.Name = GUN.Name
		GunIcon.Parent = IconTweenFrame
		PageLayout:JumpTo(GunIcon)
	end
	TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play()
	TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play()
	TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play()
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {BackgroundTransparency = 1}):Play()
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"):WaitForChild("Bar"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {BackgroundTransparency = 1}):Play()
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"):WaitForChild("ChargeAmt"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()

	AmmoCircle.Parent.Parent.Visible = true

	UpdateCircle()
end)
-- When gun's not shooting anymore update the variable --
GUN.Deactivated:Connect(function()
	Holding = false
end)


-- When gun's unequipped, it'll do the inverese of whats done for the equipped function (Tween most elements visibility to 1)--
GUN.Unequipped:Connect(function()
	Equipped = false
	PageLayout:JumpTo(IconTweenFrame:WaitForChild("Blank"))
	AmmoCircle.Transparency = NumberSequence.new(
		{
			NumberSequenceKeypoint.new(0,1),
			NumberSequenceKeypoint.new(1,1),
		}
	)
	AmmoCircle.Parent.Parent.Visible = false
	TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()
	TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()
	TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()	
end)

-- When the server returns beam information (Such as other players shooting) to the client, itll simulate the bullets so we can see other player's bullets.
Event.OnClientEvent:Connect(function(plr, Shootpart, Hits, Misses)
	for i,v in pairs(Hits) do
		Beam(Shootpart, v[3], plr)
	end
	for i,v in pairs(Misses) do
		
		Beam(Shootpart, v, plr)
	end
end)



-- When R's pressed reload --
UIS.InputBegan:Connect(function(Key, IsTyping)
	if Key.KeyCode == Enum.KeyCode.R then
		if not IsTyping then
			if IsReloading == false then
				if RELOADDEBOUNCE == false and Ammo < MaxAmmo then
					Reload()
				end
			end

		end
	end
end)

-- Initialize --

PageLayout:JumpTo(IconTweenFrame:WaitForChild("Blank"))
AmmoCircle.Transparency = NumberSequence.new(
	{
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(1,1),
	}
)
AmmoCircle.Parent.Parent.Visible = false


UpdateCircle()
TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()

TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()
TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()
TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()	
