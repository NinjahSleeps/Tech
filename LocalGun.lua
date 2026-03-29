-- Services --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-- Initial Scripts --
local GUN = script.Parent
local SHOOTPART = GUN:WaitForChild("Shootpart")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Modules --
local ClientServices = require(ReplicatedStorage:WaitForChild("ClientServices"))
local GunSettings = require(GUN:WaitForChild("GunLocal"):WaitForChild("GunSettings"))

-- Gun Settings --
local Ammo = GunSettings.Ammo
local MaxAmmo = GunSettings.MaxAmmo

-- Gun Variables
local totalDamage = 0
local fadeTimerId = 0
local indicatorVisible = false
local CurrentRotation = -180
local Debounce = false
local RELOADDEBOUNCE = false
local IsReloading = false
local Equipped = false
local totalDamage
local FadeDelay = 1
local FadeTime = 0.1
local ShowTIme = 0.85
local fadeTimerId = 0
local totalDamage = 0
local indicatorVisible = false
local Holding = false

-- Remote Events --
local RemoteEvents= ReplicatedStorage:WaitForChild("RemoteEvents")
local Event:RemoteEvent = RemoteEvents:WaitForChild("Shoot")
local KillmarkerEvent:RemoteEvent = RemoteEvents:WaitForChild("KillEvent")

-- UI --
local StarterGui = Player.PlayerGui
local Main = StarterGui:WaitForChild("UI")
local AmmoBar = Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("AmmoBar")
local AmmoCircle = AmmoBar:WaitForChild("UIStroke"):WaitForChild("UIGradient")
local CanvasGroup = Main:WaitForChild("Main"):WaitForChild("CanvasGroup")
local IconTweenFrame = Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("IconTween")
local PageLayout = IconTweenFrame:WaitForChild("UIPageLayout")

-- Sounds --
local Sounds = GUN:WaitForChild("Handle"):WaitForChild("Sounds")
local ReloadSound = Sounds:WaitForChild("Reload")
local ShootSound = Sounds:WaitForChild("Shoot")
local ConsistentReload = Sounds:WaitForChild("ConsistentReload")
local HitSound = Sounds:WaitForChild("Hit")

-- Setting Values --
local Settings = Player:WaitForChild("Settings")
local HitmarkerTypeSetting:StringValue = Settings:WaitForChild("HitmarkerType")
local KillmarkerSetting:BoolValue = Settings:WaitForChild("Killmarker")

-- Cursor UI --
local CursorUi = StarterGui:WaitForChild("CursorUi")
local CursorFrame = CursorUi:WaitForChild("Frame")
local KillMarker = CursorFrame:WaitForChild("KillMarker")
local KillMarkerStroke = KillMarker:WaitForChild("UIStroke")
local HitmarkerUi = CursorFrame:WaitForChild("Hitmarker")
local HitmarkerImage = HitmarkerUi:WaitForChild("HitmarkerIcon")

-- Hitmarker UI -- 
local HitmarkerUi = CursorFrame:WaitForChild("Hitmarker")
local HitmarkerImage = HitmarkerUi:WaitForChild("HitmarkerIcon")

-- Functions --

-- Updates the ammo bar ui (Which is a circle --
function ClientServices:UpdateCircle(Ammo, MaxAmmo)
	if Equipped == true then
		AmmoCircle.Parent.Color = Color3.fromRGB(255, 255, 255)
	
		if Ammo < MaxAmmo then
	
			-- Edits the transparency of the "AmmoCircle" (Which is the ui gradient for the stroke of the "Ammo Bar UI")--
			AmmoCircle.Transparency = NumberSequence.new(
				{
					NumberSequenceKeypoint.new(0,0),
					NumberSequenceKeypoint.new(Ammo/MaxAmmo,0),
					NumberSequenceKeypoint.new((Ammo/MaxAmmo)+.001,1),
					NumberSequenceKeypoint.new(1,1),
				}
	
			)
		elseif Ammo == MaxAmmo then
			-- If the ammo is max itll just make the circle appear full --
			AmmoCircle.Transparency = NumberSequence.new(
				{
					NumberSequenceKeypoint.new(0,0),
					NumberSequenceKeypoint.new(1,0),
				}
	
			)
		elseif Ammo == 0 then
			-- If the ammo is empty itll 0 it --
			AmmoCircle.Transparency = NumberSequence.new(
				{
					NumberSequenceKeypoint.new(0,1),
					NumberSequenceKeypoint.new(1,1),
				}
	
			)
		end
		local Percentage = (Ammo/MaxAmmo)*100
	
		-- This converts the ammo from an amount to a percentage --
		Main:WaitForChild("Main"):WaitForChild("CanvasGroup"):WaitForChild("AmmoPercentage").Text = math.round(Percentage) .. "%"
	end
end

-- Damage Indicator --
local function indicate(Part, Damage, Firerate, Charge, ChargeDamage)
	-- Checks if the Damage Indicator Setting is true --
	if Settings:WaitForChild("DmgIndicator").Value == true then
		-- If the setting value is stack, then: --
		if Settings:WaitForChild("Stack").Value == true then
			local Shadow = CursorFrame:WaitForChild("Damage")

			-- Tweens the Text Transparency so it becomes visble --
			TweenService:Create(Shadow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {TextTransparency = 0}):Play()

			-- Update Stack Amount --
			totalDamage = Damage + totalDamage
			print(totalDamage)
			if Charge and ChargeDamage > 0 then
				if Charge >= 1 then
					Shadow.Text = tostring(ChargeDamage)
				else
					Shadow.Text = tostring(totalDamage)
				end
			else
				Shadow.Text = tostring(totalDamage)
			end
			
			if Shadow then
				-- Charge is only applicable when a recon gun is selected (Aka a sniper) --
				if Charge and ChargeDamage > 0 then
					if Charge >= 1 then
						Shadow.Text = tostring(ChargeDamage)
					else
						Shadow.Text = tostring(totalDamage)
					end	
				else
					Shadow.Text = tostring(totalDamage)
				end
			end

			-- Change Color on Heaadshot --
			if Part.Name == "Head" then
				Shadow.TextColor3 = Color3.fromRGB(255, 70, 70)
			else
				Shadow.TextColor3 = Color3.fromRGB(255, 255, 255)
			end

			-- Keep TextStroke visible only on main text --
			Shadow.TextStrokeTransparency = 0
			if Shadow then
				Shadow.TextStrokeTransparency = 1
			end

			-- Tween visible (main text only, not the shadow) --
			if not indicatorVisible then
				indicatorVisible = true
				ClientServices:tweenTransparency(Shadow, 0, ShowTime)
			end

			-- Fade timer logic --
			fadeTimerId = Firerate + fadeTimerId
			local thisTimerId = fadeTimerId

			task.delay(FadeDelay, function()
				if thisTimerId == fadeTimerId then
					-- Fade out main text only, keep shadow --
					tweenTransparency(Shadow, 1, FadeTime)
					indicatorVisible = false
					totalDamage = 0
					print("Resetting Damage")
					TweenService:Create(Shadow, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {TextTransparency = 1}):Play()

				end
			end)
		else
			-- If the stacking setting isnt enabled, then it'll make a physical damage indicator as opposed to a UI one, and parent it to the character of the hit player --
			local indicator = script:WaitForChild("DmgIndicator"):Clone()
			indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage
			if Charge then
				if Charge >= 1 then
					indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = tostring(ChargeDamage)
				else
					indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage			
				end
			else
				indicator:WaitForChild("Frame"):WaitForChild("Damage").Text = Damage			

			end
			
			indicator.Enabled = true
			if Part.Name == "Head" then
				indicator:WaitForChild("Frame"):WaitForChild("Damage").TextColor3 = Color3.fromRGB(255, 70, 70)
			end
			local Attachment = Instance.new("Part")
			Attachment.Transparency = 1
			Attachment.Anchored = true
			Attachment.CanCollide = false
			Attachment.CanQuery = false
			Attachment.Position = Part.Position
			Attachment.Parent = workspace
			Attachment.Size = Vector3.new(0.001,0.001,0.001)
			indicator.Parent = Attachment
			local Ran1 = math.random(1,2)
			local RandomSide
			if Ran1 == 1 then
				indicator.SizeOffset = Vector2.new(1,0)
				RandomSide = Vector2.new(3,0)
			else
				indicator.SizeOffset = Vector2.new(-1,0)
				RandomSide = Vector2.new(-3,0)
			end
			Debris:AddItem(indicator, 1.1)

			local IndicatorTween = TweenService:Create(indicator, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {SizeOffset = RandomSide})
			IndicatorTween:Play()
			IndicatorTween.Completed:Connect(function()
				local IndicatorTween = TweenService:Create(indicator, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0,false,0), {Size = UDim2.new(0,0,0,0)}):Play()
			end)
		end
	end
end

-- This is the Hit Marker thats stuck to the cursor via the UI, it'll play whenever you hit something --
local function hitMarker(Part)
	if Settings:WaitForChild("Hitmarker").Value == true then
		if HitmarkerTypeSetting.Value == "Expand" then
			-- If the option is expand it'll play a tween animation that expands the size of the hitmarker, then tweens the transparency simultaniously--
			HitmarkerImage.Rotation = 0
			HitmarkerImage.Size = UDim2.new(.4,0,.4,0)
			HitmarkerImage.ImageTransparency = 0
			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
			local SizeTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {Size = UDim2.new(1.5,0,1.5,0)})
			TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play()
			SizeTween:Play()
			SizeTween.Completed:Connect(function()
				HitmarkerImage.ImageTransparency = 1
				HitmarkerImage.Size = UDim2.new(.4,0,.4,0)
			end)
		elseif HitmarkerTypeSetting.Value == "Rotate" then
			-- If the option is rotate then it'll rotate the hitmarker, if the rotation is 180 or greater than 180 then it'll reset the cursors rotation --
			HitmarkerImage.Size = UDim2.new(1,0,1,0)
			HitmarkerImage.ImageTransparency = 0
			if CurrentRotation >= 180 then
				CurrentRotation = -180
				HitmarkerImage.Rotation = CurrentRotation
			end
			CurrentRotation = CurrentRotation + 20
			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
			local RotationTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.1,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {Rotation = CurrentRotation})
			RotationTween:Play()

			TweenService:Create(HitmarkerImage, TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play()
			RotationTween.Completed:Connect(function()
				HitmarkerImage.ImageTransparency = 1

			end)
		elseif HitmarkerTypeSetting.Value == "Fade" then
			-- If the option is fade it'll just make the hitmarker fade in, then fade out via its image transparency --
			HitmarkerImage.Rotation = 0
			HitmarkerImage.Size = UDim2.new(1,0,1,0)
			HitmarkerImage.ImageTransparency = .1


			HitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)


			local FadeTween = TweenService:Create(HitmarkerImage, TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 0})
			FadeTween:Play()

			FadeTween.Completed:Connect(function()
				TweenService:Create(HitmarkerImage, TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut, 0,false,0), {ImageTransparency = 1}):Play()
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
