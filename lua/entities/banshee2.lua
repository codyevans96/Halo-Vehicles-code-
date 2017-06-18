ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-27 Banshee"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/space_banshee/space_banshee.mdl"
ENT.Vehicle = "banshee2"
ENT.StartHealth = 1000;
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/banshee_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("banshee2");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*190+self:GetUp()*20+self:GetRight()*-28,
		Right = self:GetPos()+self:GetForward()*190+self:GetUp()*20+self:GetRight()*28,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2500;
	self.ForwardSpeed = 2500;
	self.UpSpeed = 1000;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanRoll = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.Bullet = HALOCreateBulletStructure(70,"plasma");
	self.FireGroup = {"Left","Right",};
	self.AlternateFire = true;
	self.FireDelay = 0.2;
	self.DontOverheat = true;
	self.ExitModifier = {x = 100, y = -80, z = 115};
    self.Hover = true;

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
				self:FireBlast(pos,false,8,500,false,20);
			end
		end
	end
	self.BaseClass.Think(self);
end

function ENT:FireBlast(pos,gravity,vel,dmg,white,size,snd)
	if(self.NextUse.FireBlast < CurTime()) then
		local e = ents.Create("plasma_blast");
		
		e.Damage = dmg or 600;
		e.IsWhite = white or false;
		e.StartSize = size or 20;
		e.EndSize = e.StartSize*0.75 or 15;
		
		
		local sound = snd or Sound("weapons/banshee_bomb.wav");
		
		e:SetPos(pos);
		e:Spawn();
		e:Activate();
		e:Prepare(self,sound,gravity,vel);
		e:SetColor(Color(20,205,0,1));
		
		self.NextUse.FireBlast = CurTime() + 5;
		
		self:SetNWInt("FireBlast",self.NextUse.FireBlast)
	end
	
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/banshee_fly.wav"),
	}
	
	hook.Add("ScoreboardShow","Banshee2ScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("Banshee2");
		if(Flying) then
			return false;
		end
	end)
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("Banshee2", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*67.5+self:GetForward()*-31;
			View = HALOVehicleView(self,575,175,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "Banshee2View", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.SpaceBansheeEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.01);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(30);
			heatwv:SetEndSize(25);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(95)
			blue:SetEndAlpha(20)
			blue:SetStartSize(10)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.SpaceBansheeEnginePos = {
				self:GetPos()+self:GetRight()*-47+self:GetUp()*47+self:GetForward()*-120,
				self:GetPos()+self:GetRight()*-3+self:GetUp()*47+self:GetForward()*-120,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function Banshee2Reticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingBanshee2");
		local self = p:GetNWEntity("Banshee2");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(1000);
			HALO_CovenantReticles(self);
			HALO_BlastIcon(self,5);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "Banshee2Reticle", Banshee2Reticle)

end