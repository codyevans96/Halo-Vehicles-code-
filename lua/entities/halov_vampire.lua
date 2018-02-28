ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "Type-29 Vampire"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/vampire.mdl"
ENT.Vehicle = "halov_vampire"
ENT.StartHealth = 1500;
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/banshee_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),FireMain = CurTime()};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_vampire");
	e:SetPos(tr.HitPos + Vector(0,0,50));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*50+self:GetUp()*0+self:GetRight()*-110,
		Right = self:GetPos()+self:GetForward()*50+self:GetUp()*0+self:GetRight()*110,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1200;
	self.ForwardSpeed = 1200;
	self.UpSpeed = 500;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanStrafe = true;
	self.Hover = true;
	self.CanShoot = true;
	self.DontOverheat = true;
	self.Bullet = HALOCreateBulletStructure(50,"plasma");
	self.FireGroup = {"Left","Right",};
	self.AlternateFire = true;
	self.FireDelay = 0.1;
	self.NextBlast = 1;
	self.ExitModifier = {x = 0, y = 100, z = 20};

	self.BaseClass.Initialize(self);
	
end

function ENT:Enter(p)
    self.BaseClass.Enter(self,p);
end
    
function ENT:Exit(kill)
	self.BaseClass.Exit(self,kill);
end

function ENT:Think()

	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
			if(self.Pilot:KeyDown(IN_ATTACK2)) then
				local pos = self:GetPos()+self:GetForward()*150+self:GetUp()*20;
				self:FireBlast(pos,false,8,300,false,40);
			end
		end
	end
	self.BaseClass.Think(self);
end

function ENT:FireBlast(pos,gravity,vel,dmg,white,size,snd)
	if(self.NextUse.FireBlast < CurTime()) then
		local e = ents.Create("vampire_blast");
		
		e.Damage = dmg or 600;
		e.IsWhite = white or false;
		e.StartSize = size or 20;
		e.EndSize = e.StartSize*0.75 or 15;
		local sound = snd or Sound("weapons/beam.wav");
		e:SetPos(pos);
		e:Spawn();
		e:Activate();
		e:Prepare(self,sound,gravity,vel);
		e:SetColor(Color(120,120,255,1));
		
		self.NextUse.FireBlast = CurTime() + 2;
		self:SetNWInt("FireBlast",self.NextUse.FireBlast)
	end
	
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/covenant_fly.wav"),
	}
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingHALOV_Vampire");
		local Sitting = p:GetNWBool("HALOV_VampirePassenger");
		local pos, face;
		local self = p:GetNWEntity("HALOV_Vampire");
	
		
		if(Flying) then
			if(IsValid(self)) then
				local fpvPos = self:GetPos()+self:GetUp()*13+self:GetForward()*125+self:GetRight()*0.4;
				View = HALOVehicleView(self,350,115,fpvPos,true);		
				return View;
			end
		end
		
	end
	hook.Add("CalcView", "HALOV_VampireView", CalcView)
	
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
		for k,v in pairs(self.HALOV_VampireEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.01);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(40);
			heatwv:SetEndSize(1);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local heatwv = self.Emitter:Add("sprites/bluecore",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.05);
			heatwv:SetStartAlpha(95);
			heatwv:SetEndAlpha(5);
			heatwv:SetStartSize(20);
			heatwv:SetEndSize(1);
			heatwv:SetColor(218,160,214);
			heatwv:SetRoll(roll);

		end
	end
	
	function ENT:Think()
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_VampireEnginePos = {
				self:GetPos()+self:GetRight()*-58.5+self:GetUp()*-2+self:GetForward()*-82,
				self:GetPos()+self:GetRight()*8.5+self:GetUp()*-2+self:GetForward()*-82,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_VampireReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Vampire");
		local self = p:GetNWEntity("HALOV_Vampire");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(1500);
			HALO_HeavyReticles(self);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_VampireReticle", HALOV_VampireReticle)

end