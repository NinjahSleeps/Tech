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
local Holding = false -- This is to check if the player is holding their mouse down whilst the guns equipped

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
local function Beam(StartPos, EndPos, PlrShooting) -- Gets the Start position of where the guns ShootPart is, End position (Where the beam hits), sets the beam color to the player whos shootings beam color.
	-- Create the Beam --
	local beam = Instance.new("Beam") -- Creates Beam
	local Attachment1 = Instance.new("Attachment", workspace.Terrain) -- Creates attachement and parents it to terrain
	local Attachment2 = Instance.new("Attachment", workspace.Terrain) -- Creates second attachement and parents it to terrain

	Attachment1.Name = "Attachment1" -- Names the attachement
	Attachment2.Name = "Attachment2" -- Names the second attachement
	Attachment1.Position = StartPos -- Sets the position first attachement to the Tools Tip
	Attachment2.Position = EndPos -- Sets the position of hte second attachement to wherever the player's shooting

	-- Beam Physical Attributes --
	beam.Name = PlrShooting.Name -- Sets the name of the beam to the Player whos shootings name.
	beam.Color = ColorSequence.new(PlrShooting.TeamColor.Color)
	beam.Attachment0 = Attachment1 -- Sets the beams first attachement to Attachement 1.
	beam.Attachment1 = Attachment2 -- Sets the beams second attachement to Attachement 2 to simulate the beam shooting at somebody
	beam.Parent = workspace -- Parents the beam to workspace after everythings moved to help save render data
	beam.FaceCamera = true -- Sets this to true so the beam looks more 3d
	
	beam.LightEmission = 1 -- Adding light emission to give off the laser beam type vibe
	beam.LightInfluence = 0 -- Sets the light influence to 0 so that the beam doesnt turn dark in a dark environment
	beam.Brightness = 1 -- Adds a brightness to increase the visibility of the beam
	
	if Settings:WaitForChild("DynamicRays").Value == false then -- If Dynamic Rays are off then:
		-- If Dynamic Rays are off then make the beam a solid beam --
		beam.Transparency = NumberSequence.new(0,1) -- Give the beam a nice fade effect
		beam.Texture = 'rbxassetid://2950987178' -- Give it a thin beam texture
		beam.TextureMode = Enum.TextureMode.Stretch -- Sets the beam to stretch
		beam.Width0 = 0.2 -- Sets the width near the tip to be thicker to give the bullet a better look
		beam.Width1 = 0.1 -- Sets the width near the end to be thinner so it looks like if its traveling a farther distance
		Debris:AddItem(beam, .025) -- Adds the beam to debris service to clear it
		Debris:AddItem(Attachment1, .1) -- Adds the attachement to debris service to clear it
		Debris:AddItem(Attachment2, .1) -- Adds the second attachement to debris service to clear it
	else 
		-- If Dynamic Rays are on then it'll play an "Animation" via the beam texture, speed, and length --
		beam.Texture = 'rbxassetid://11226108137' -- Sets the beam texture to an animated one with gaps
		beam.TextureSpeed = 4 -- Gives it a texture speed of 4 to simulate the bullet flying
		beam.Transparency = NumberSequence.new(0,0) -- Sets the transparency to make it fully visible
		beam.TextureMode = Enum.TextureMode.Stretch -- Sets the texture mode to stretch so it stretches across the beam
		beam.TextureLength = .8 -- Gives it a texture length of .8 so itll only simulate 1 bullet per shot
		beam.Width0 = 1.3 -- Sets the first width to be thinner to make the bullet more visible
		beam.Width1 = 1.5 -- Sets the second width to be thicker to improve visibility of it from a farther distance
		Debris:AddItem(beam, .04) -- Adds the beam to debris service for memory reasons
		Debris:AddItem(Attachment1, .04) -- Adds the first attachement to debris service
		Debris:AddItem(Attachment2, .04) -- Adds the second attachement to debris service
	end
end

-- This function increases the amount of "Ammo" via the variable, plays a sound, and updates the ammo bar's circle --
local function Reload()
	IsReloading = true -- Sets the reloading global variable to true
	RELOADDEBOUNCE = true -- Sets the reload global variable to true to prevent double reloading
	ReloadSound:Play() -- Plays the initial reload sound
	while Ammo < MaxAmmo do -- While current ammo is less than the max ammo the gun can hold:
		task.wait(GunSettings.ReloadWait) -- Wait by the "Reload Wait" time inside of the gun settings module
		RELOADDEBOUNCE = true -- Ensure the reload debounce is still true
		Ammo += 1 -- Increase the ammo by one
		ConsistentReload:Play() -- Play the relaod tick sound
		UpdateCircle() -- Update the ammo bar circle
	end
	RELOADDEBOUNCE = false -- Once the gun is done reloading set the reload debounce to false
	IsReloading = false -- Set the global isreloading variable to false
end

-- Spread Handler (provides a random point inside of a cone) --
local function RandomCone(axis, angle) -- axis = direction the cone points (should be UNIT VECTOR), angle = max cone angle (in radians)
	local cosAngle = math.cos(angle) -- Get the cosine of the max angle to uniform the sampling of a cone
	local z = 1 - math.random() * (1 - cosAngle)-- Pick a random Z value between cos(angle) and 1 to randomly pick a point over the surface of the cone
	local phi = math.random() * math.pi * 2 -- Picks a random angle around the circle (0 to 2π) effectively spinning a point across a cone axis
	local r = math.sqrt(1 - z * z)	-- Computes the radius of the circle at height z on the unit sphere


	local x = r * math.cos(phi)	-- Converts the polar coordinates (r, phi) into Cartesian (x, y)
	local y = r * math.sin(phi) -- Same thing as the line above but for the Y axis

	
	local vec = Vector3.new(x, y, z) -- Provides a random vector within the cone

	if axis.Z > 0.9999 then -- If axis is already almost pointing straight up (+Z),
		return vec -- No rotation needed
	end

	if axis.Z < -0.9999 then --if axis is pointing straight down (-Z),
		return -vec -- Flip the vector
	end

	local orth = Vector3.zAxis:Cross(axis) 	-- Finds a perpendicular axis to rotate around
	local rot = math.acos(axis:Dot(Vector3.zAxis))-- Finds an angle between Z-axis and target axis using dot product

	return CFrame.fromAxisAngle(orth, rot) * vec -- Returns the CFrame with spread applied
end

-- Adds a box around the hit part --
local function hitBox(Part) -- Gets the part to add the hitbox at
	if Settings:WaitForChild("Hitboxes").Value == true then -- If the hitbox setting is turned on then
		local hitbox = script:WaitForChild("SelectionBox"):Clone() -- Clone the selectionbox thats a child inside of this script
		if Part.Name == "Head" then -- If the part is called head then:
			hitbox.Color3 = Color3.fromRGB(113, 0, 0) -- Set hte hitbox color to be red
		else -- Otherwise
			hitbox.Color3 = Color3.fromRGB(255, 255, 255) -- Set it to be white
		end
		hitbox.Parent = Part -- Set the hitbox parent to the part
		hitbox.Adornee = Part -- And the adornee so it displays in workspace
		Debris:AddItem(hitbox, 1.1) -- Add the hitbox to debris so it dissappears in case the tweening doesnt work (In the lines below) and for memory reasons
		-- Tweens the transparency of the box --
		local HitboxTween = TweenService:Create(hitbox, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {Transparency = 0}) -- Tweens transparency of hitbox to 0 (It starts off fully transparent by default)
		HitboxTween:Play() -- Plays the tween
		HitboxTween.Completed:Connect(function() -- When the tweens finished:
			TweenService:Create(hitbox, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {Transparency = 1}):Play() -- Tween it to be invisible again
		end)
	end
end


-- Handles the Ray --
local function commitRay(MouseHitPosition, ShellCount, MinDistance, MaxDistance, Spread, Shootpart, ShootSound, HitSound, HeadshotDamage, Damage, Firerate, Charge, ChargeDamage) -- Gets the Position the mouse hit, shell count (Normally set to 1 if its not a shotgun), min distance (Distance the bullet can go before spread is factored in), Max Distance the bullet can travel, bullet spread, the tools tip, the HitSound, HeadShot Damage, Normal Damage, Firerate, Charge, and the Charge Damage of the gun)
	local Hits = {} -- Creates a Hits Table for all shots that hit a player
	local Misses = {} -- Creates a Misses table for all shots that miss a player
	local Origin = Player.Character:WaitForChild("Head").Position -- Sets the origin of the raycast to the head to prevent wall banging
	local Endpoint = MouseHitPosition -- Sets the endpoint to the mousehit position for the raycast
	
	for i=ShellCount, 1, -1 do -- Repeat this for each shell in shellcount
		local Params = RaycastParams.new() -- Creates a new raycast
		Params.FilterDescendantsInstances = {script.Parent, Player.Character} -- Makes sure that you cant shoot yourself or the tool
		Params.FilterType = Enum.RaycastFilterType.Exclude -- This is to exclude the items mentioned above to exlude
		local Axis = (Endpoint - Origin).Unit -- This is the initial raycast axis
		local Direction = RandomCone(Axis, math.rad(Spread)) * MaxDistance -- This is the direction that the raycast is going (With spread applied)
		local AxisLength = (Endpoint-Origin).Magnitude -- This gets how long the beam length is
		if AxisLength <= MinDistance then -- If the beam length is less than min distance then
			-- If the target is close enough, then don't add spread --
			Direction = (Endpoint - Origin).Unit * 10000 -- Eliminate all spread
		end
		local RaycastResult = workspace:Raycast(Origin,Direction,Params) -- The result of the raycast with all of the parameters above
		-- If something gets hit then:
		if RaycastResult then -- If something gets hit then:
			ShootSound:Play() -- Play the shoot sound
			local Hit = RaycastResult.Instance -- Get hte instance that was hit
			local Position = RaycastResult.Position -- Get the position of the raycast

			Beam(Shootpart.Position, Position, Player) -- Simulate the beam, and pas the part that was shot, where the bullet landed, and the player whos shot
			if Hit:IsA("BasePart") then -- If the part that was hit is a basepart then:
				if Hit.Parent:FindFirstChild("Humanoid") or Hit.Parent.Parent:FindFirstChild("Humanoid") then -- Check if its a humanoid

					local Humanoid = Hit.Parent:FindFirstChild("Humanoid") or Hit.Parent.Parent:FindFirstChild("Humanoid") -- If its a humanoid then
					if Humanoid.Health > 0 then -- Check if the humanoid is alive
						if RaycastResult.Instance.Name == "Head" then -- If the head was hit then:
							hitBox(RaycastResult.Instance) -- Add a hitbox around the head
							indicate(RaycastResult.Instance,HeadshotDamage,Firerate, Charge, ChargeDamage)	-- Add a damage indicator prior to firing the remote event
							hitMarker() -- Start the hitmarker thats around your cursor
							HitSound:Play() -- Play the hitsound indicating that a player got hit
						else
							-- Indicates a body shot, thus triggering a hitbox to the body, the damage indicator is modified to a body shot damage indicator, then the hitmarker is triggered along with the hit sound object. --
							ClientServices:hitBox(RaycastResult.Instance) -- Add a hitbox around the part that got shot
							indicate(RaycastResult.Instance,Damage,Firerate, Charge, ChargeDamage)	-- Create a damage indicator for the amount of damage dealt	
							hitMarker(RaycastResult.Instance) -- Start the hitmarker function
							HitSound:Play() -- Play the hitsound
						end
						-- This inserts all hits, the hit player character, the instance of what the raycast has hit, and the position of what was hit --
						table.insert(Hits, {Humanoid.Parent, RaycastResult.Instance, RaycastResult.Position}) -- Insert the part and character that got hit into hits
					else
						-- If the player hit a dead player then it'll count it as a miss --
						table.insert(Misses, RaycastResult.Position) -- Count it as a miss with the position
					end
				else
					-- If the player didnt hit another player then itll count it as a miss --
					table.insert(Misses, RaycastResult.Position) -- Count it as a miss with the position

				end
			end
		else
			-- If the player didnt hit a base part, it'll get where the player would have hit if something were there, and count as a miss --
			ShootSound:Play() -- Play the shootsound
			local Position = Direction+Origin -- Get where the player shouldve landed if something were there (This plays in case they shoot into the void or something)
			table.insert(Misses, Position) -- Add to misses as they didnt hit another player
			Beam(Shootpart.Position, Position, Player) -- Simulates a beam for this as well

		end
	end

	-- Sends to the server once via a remote event to prevent overloading a server, sending everything via its table values, along with the guns properties --
	Event:FireServer(Shootpart.Position, Hits, Misses, Damage, HeadshotDamage, Charge, ChargeDamage)	
end



-- When the gun tool is activated, it checks if the gun's being held, theres enough ammo, and we're not currently reloading --
GUN.Activated:Connect(function() -- When the tool is clicked while equipped:
	Holding = true -- Set the holding variable to tru (Meaning the players mouse is being heald down whilst the gun is equipped)
	while Holding and Ammo > 0 and RELOADDEBOUNCE == false do -- While the mouse is actively being heald down and we're not reloading:
		if not Debounce then -- If theres no debounce then
			Debounce = true -- Set the debounce to true
			-- MouseHitPosition, ShellCount, MinDistance, MaxDistance, Spread, Shootpart, ShootSound, HitSound, HeadshotDamage, Damage, Firerate, Charge, ChargeDamage
			ClientServices:commitRay(Mouse.Hit.Position, GunSettings.ShellCount, GunSettings.MinDistance, GunSettings.MaxDistance, GunSettings.Spread, SHOOTPART, ShootSound, HitSound, GunSettings.HeadshotDamage, GunSettings.Damage, GunSettings.Firerate, nil, nil) -- Run our raycast function to get our players damaged with all of our parameters
			Ammo -= 1 -- Decrease the ammo by one since we shot
			UpdateCircle() -- Update the Ammo Bar
				
			task.delay(GunSettings.Firerate, function() -- Delay setting the debounce to false by firerate seconds
				Debounce = false -- Sets the shoot debounce to false
			end)
		end

		task.wait() -- Waits a frame to prevent script exhaustion
	end

	-- Auto Reload Function --
	if Ammo <= 0 then -- If the player is out of ammo then
		Reload() -- Reload the gun
	end
end)

-- When the gun's equipped it'll initialize the UI --
GUN.Equipped:Connect(function() -- When the guns equipped:
	Equipped = true -- Set the equipped global variable to true
	Sounds:WaitForChild("GunEquip"):Play() -- Play the equip sound
	CanvasGroup:WaitForChild("ToolName").Text = GUN.Name -- Set the toolname inside the ui to the name of the gun
	if IconTweenFrame:FindFirstChild(GUN.Name) then -- Looks for the toolname inside of the GUI inside of the canvas frame that has all of our tool icons
		PageLayout:JumpTo(IconTweenFrame:WaitForChild(GUN.Name)) -- If its visible then just jump to it (It uses a page layout)
	else -- Otherwise
		local GunIcon = script:WaitForChild("Template"):Clone() -- Check for an image template inside of this script and clone it
		GunIcon.Name = GUN.Name -- Set the name of it to the guns name
		GunIcon.Parent = IconTweenFrame -- Parent it to the canvas frame
		PageLayout:JumpTo(GunIcon) -- Jump to it to animate it
	end
	TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play() -- Tweens the ammo percentage to be visible
	TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play() -- Tweens the class text to be visible
	TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 0}):Play() -- Tweens the toolname text to be visible
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {BackgroundTransparency = 1}):Play() -- Tweens the charge background bar to be invisible (As this gun is not a recon)
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"):WaitForChild("Bar"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {BackgroundTransparency = 1}):Play() -- Tweens the charge bar to be invisible (as this gun is not a recon gun)
	TweenService:Create(CanvasGroup.Parent:WaitForChild("ChargeBG"):WaitForChild("ChargeAmt"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Tweens the charge amount to be invisible (As this gun is not a recon gun)

	AmmoCircle.Parent.Parent.Visible = true -- Ensures the ammo circle is visible

	UpdateCircle() -- Updates visuals for the ammo circle bar
end)
-- When gun's not shooting anymore update the variable --
GUN.Deactivated:Connect(function() -- When the guns no longer being "Activated" (AKA Mouse is lifted)
	Holding = false -- Set holding to false (Showing that we're not holding down the button)
end)


-- When gun's unequipped, it'll do the inverese of whats done for the equipped function (Tween most elements visibility to 1)--
GUN.Unequipped:Connect(function() -- When the guns unequipped:
	Equipped = false -- Set equipped global variable to false
	PageLayout:JumpTo(IconTweenFrame:WaitForChild("Blank")) -- Make the ui showing the gun image go to nothing
	AmmoCircle.Transparency = NumberSequence.new( -- Set the transparency of the ammo circle to:
		{
			NumberSequenceKeypoint.new(0,1),-- Make the left side invisible
			NumberSequenceKeypoint.new(1,1), -- And the right side invisible
		}
	)
	AmmoCircle.Parent.Parent.Visible = false -- Make the ammo circle bar invisible
	TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Tween the ammo percentage text to be invisible
	TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Tween the class text to be invisible
	TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play()-- tween the toolname text to be invisible
	-- We dont need to retween the charge bars to be invisible as they were already made invisible upon equipping --
end)

-- When the server returns beam information (Such as other players shooting) to the client, itll simulate the bullets so we can see other player's bullets.
Event.OnClientEvent:Connect(function(plr, Shootpart, Hits, Misses) -- When the beam event is sent to us (Only gets sent to us if another player shoots) then:
	for i,v in pairs(Hits) do -- Get the amount of hits inside of the table
		Beam(Shootpart, v[3], plr) -- Simulate the beam to the position of where the hit landed, and pass the player along with the shootpart to the function
	end
	for i,v in pairs(Misses) do
		Beam(Shootpart, v, plr) -- Simulate the beam to where the hit missed
	end
end)



-- When R's pressed reload --
UIS.InputBegan:Connect(function(Key, IsTyping) -- When a key is pressed, itll check if we're typing
	if Key.KeyCode == Enum.KeyCode.R then -- If the key "R" is pressed then
		if not IsTyping then -- if the player is not typing in chat then
			if IsReloading == false then -- If we're not currently reloading then
				if RELOADDEBOUNCE == false and Ammo < MaxAmmo then -- If the reload debounce isnt on and if we have less than max ammo then
					Reload() -- Play the reload function
				end
			end

		end
	end
end)

-- Initialize --

PageLayout:JumpTo(IconTweenFrame:WaitForChild("Blank")) -- Sets the gun icon to nothing
AmmoCircle.Transparency = NumberSequence.new( -- Sets the ammo circles transparency to
	{
		NumberSequenceKeypoint.new(0,1), -- Invisible on the left
		NumberSequenceKeypoint.new(1,1), --- And invisible on the right
	}
)
AmmoCircle.Parent.Parent.Visible = false -- Sets the ammo circle to be invisible


UpdateCircle() -- Calls the update circle function to initialize it
TweenService:Create(CanvasGroup:WaitForChild("AmmoPercentage"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Sets the ammo percentage text to be invisible
TweenService:Create(CanvasGroup:WaitForChild("Class"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Sets the Class text to be invisible
TweenService:Create(CanvasGroup:WaitForChild("ToolName"), TweenInfo.new(.1,Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0,false,0), {TextTransparency = 1}):Play() -- Sets the toolname textlabel to be invisible
