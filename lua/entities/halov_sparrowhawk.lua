ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "AV-22 Sparrowhawk"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/hawk_o.mdl"
ENT.FlyModel = "models/helios/hawk_c.mdl"
ENT.Vehicle = "halov_sparrowhawk"
ENT.StartHealth = 2000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/lightbolt.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_sparrowhawk");
	e:SetPos(tr.HitPos + Vector(0,0,100));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*200+self:GetUp()*-30+self:GetRight()*-70,
		Right = self:GetPos()+self:GetForward()*200+self:GetUp()*-30+self:GetRight()*70,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1800;
	self.ForwardSpeed = 1800;
	self.UpSpeed = 900;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanStrafe = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.DontOverheat = true;
	self.Bullet = HALOCreateBulletStructure(300,"unsc");
	self.FireDelay = 0.25;
	self.NextBlast = 1;
	self.ExitModifier = {x = 0, y = 300, z = 20};
    self.Hover = true;
	self.LandOffset = Vector(0,0,5);
	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=140,z=-15};
	self.PilotAnim = "drive_jeep";

	self.BaseClass.Initialize(self);
	
end

function ENT:Enter(p)
    self.BaseClass.Enter(self,p);
	self:SetModel(self.FlyModel);
end
    
function ENT:Exit(kill)
	self.BaseClass.Exit(self,kill);
	self:SetModel(self.EntModel);
end

function ENT:Think()
 
    if(self.Inflight) then
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 80 + self:GetRight() * 115 + self:GetUp() * 30, //1
						self:GetPos() + self:GetForward() * 80 + self:GetRight() * -115 + self:GetUp() * 30, //1
						self:GetPos() + self:GetForward() * 80 + self:GetRight() * 115 + self:GetUp() * 30, //2
						self:GetPos() + self:GetForward() * 80 + self:GetRight() * -115 + self:GetUp() * 30, //2
						self:GetPos() + self:GetForward() * 80 + self:GetRight() * 115 + self:GetUp() * 30, //3
						self:GetPos() + self:GetForward() * 80 + self:GetRight() * -115 + self:GetUp() * 30, //3
                    }
                    self:FireHALOV_SparrowhawkBlast(self.BlastPositions[self.NextBlast], false, 250, 250, true, 8, Sound("weapons/rocket.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 7) then
						self.NextUse.FireBlast = CurTime()+5;
						self:SetNWBool("OutOfMissiles",true);
						self:SetNWInt("FireBlast",self.NextUse.FireBlast)
						self.NextBlast = 1;
					end
					
					
                end
			end
		end
		
		if(self.NextUse.FireBlast < CurTime()) then
			self:SetNWBool("OutOfMissiles",false);
		end
        self:SetNWInt("Overheat",self.Overheat);
        self:SetNWBool("Overheated",self.Overheated);
    end
    self.BaseClass.Think(self);
end

function ENT:FireHALOV_SparrowhawkBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("missle_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = size or 20;
	e.EndSize = size*0.75 or 15;
	
	local sound = snd or Sound("weapons/rocket.wav");
	
	e:SetPos(pos);
	e:Spawn();
	e:Activate();
	e:Prepare(self,sound,gravity,vel);
	e:SetColor(Color(255,255,255,1));
	
end

end

if CLIENT then
	
	ENT.CanFPV = true;
	ENT.Sounds={
		Engine=Sound("vehicles/hornet_fly.wav"),
	}
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingHALOV_Sparrowhawk");
		local Sitting = p:GetNWBool("HALOV_SparrowhawkPassenger");
		local pos, face;
		local self = p:GetNWEntity("HALOV_Sparrowhawk");
	
		
		if(Flying) then
			if(IsValid(self)) then
				local fpvPos = self:GetPos()+self:GetUp()*13+self:GetForward()*125+self:GetRight()*0.4;
				View = HALOVehicleView(self,500,175,fpvPos,true);		
				return View;
			end
		end
		
	end
	hook.Add("CalcView", "HALOV_SparrowhawkView", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "HALOV_SparrowhawkDrawPlayerModel", function( p )
		local self = p:GetNWEntity("HALOV_Sparrowhawk", NULL);
		local PassengerSeat = p:GetNWEntity("HALOV_SparrowhawkSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_SparrowhawkEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.03);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(45);
			heatwv:SetEndSize(40);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);

		end
	end
	
	function ENT:Think()
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_SparrowhawkEnginePos = {
				self:GetPos()+self:GetRight()*-121.5+self:GetUp()*85+self:GetForward()*-42,
				self:GetPos()+self:GetRight()*71.5+self:GetUp()*85+self:GetForward()*-42,
				self:GetPos()+self:GetRight()*-24.5+self:GetUp()*95+self:GetForward()*-132,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_SparrowhawkReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Sparrowhawk");
		local self = p:GetNWEntity("HALOV_Sparrowhawk");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(2000);
			HALO_UNSCReticles(self);
			HALO_BlastIcon(self,5);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_SparrowhawkReticle", HALOV_SparrowhawkReticle)

end