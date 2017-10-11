ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "Z-1500 Aggressor"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Other"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/sentinel.mdl"
ENT.Vehicle = "halov_aggressor"
ENT.StartHealth = 2000;
ENT.Allegiance = "Forerunner";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/beam2.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_aggressor");
	e:SetPos(tr.HitPos + Vector(0,0,50));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*100+self:GetUp()*0+self:GetRight()*-8,
		Right = self:GetPos()+self:GetForward()*100+self:GetUp()*0+self:GetRight()*8,
		Top = self:GetPos()+self:GetForward()*100+self:GetUp()*8+self:GetRight()*0,
		Bottom = self:GetPos()+self:GetForward()*100+self:GetUp()*-8+self:GetRight()*0,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 600;
	self.ForwardSpeed = 600;
	self.UpSpeed = 500;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanStrafe = true;
	self.CanStandby = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.DontOverheat = true;
	self.Bullet = HALOCreateBulletStructure(50,"beam");
	self.FireDelay = 1;
	self.NextBlast = 1;
	self.ExitModifier = {x = 0, y = 80, z = 10};
    self.Hover = true;
	self.LandOffset = Vector(0,0,5);

	self.BaseClass.Initialize(self);
	
end

function ENT:Enter(p)
    self.BaseClass.Enter(self,p);
end
    
function ENT:Exit(kill)
	self.BaseClass.Exit(self,kill);
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/banshee_fly.wav"),
	}
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingHALOV_Aggressor");
		local Sitting = p:GetNWBool("HALOV_AggressorPassenger");
		local pos, face;
		local self = p:GetNWEntity("HALOV_Aggressor");
	
		
		if(Flying) then
			if(IsValid(self)) then
				local fpvPos = self:GetPos()+self:GetUp()*13+self:GetForward()*125+self:GetRight()*0.4;
				View = HALOVehicleView(self,200,115,fpvPos,true);		
				return View;
			end
		end
		
	end
	hook.Add("CalcView", "HALOV_AggressorView", CalcView)
	
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
		for k,v in pairs(self.HALOV_AggressorEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.01);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(20);
			heatwv:SetEndSize(1);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);

		end
	end
	
	function ENT:Think()
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_AggressorEnginePos = {
				self:GetPos()+self:GetRight()*-24.5+self:GetUp()*0+self:GetForward()*-22,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_AggressorReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Aggressor");
		local self = p:GetNWEntity("HALOV_Aggressor");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(2000);
			HALO_HeavyReticles(self);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_AggressorReticle", HALOV_AggressorReticle)

end