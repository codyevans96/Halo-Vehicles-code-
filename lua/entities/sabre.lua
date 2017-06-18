ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "YSS-1000 Sabre"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/sabre/sabre.mdl"
ENT.FlyModel = "models/helios/sabre_nogear/sabre_nogear.mdl"
ENT.Vehicle = "sabre"
ENT.StartHealth = 2000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/heavy_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("sabre");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetUp()*115+self:GetRight()*57+self:GetForward()*125,
		Left = self:GetPos()+self:GetUp()*115+self:GetRight()*-57+self:GetForward()*125,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2800;
	self.ForwardSpeed = 2800;
	self.UpSpeed = 1000;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanRoll = true;
	self.Hover = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.Bullet = HALOCreateBulletStructure(100,"unsc");
	self.FireDelay = 0.1;
	self.NextBlast = 1;
	self.AlternateFire = true;
	self.DontOverheat = true;
	self.FireGroup = {"Left","Right"};
	self.ExitModifier = {x = 0, y = 400, z = 50};
	
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
                        self:GetPos() + self:GetForward() * 35 + self:GetRight() * 90 + self:GetUp() * 90, //1
						self:GetPos() + self:GetForward() * 35 + self:GetRight() * -90 + self:GetUp() * 90, //1
						self:GetPos() + self:GetForward() * 35 + self:GetRight() * 90 + self:GetUp() * 90, //2
						self:GetPos() + self:GetForward() * 35 + self:GetRight() * -90 + self:GetUp() * 90, //2
                    }
                    self:FireSabreBlast(self.BlastPositions[self.NextBlast], false, 300, 300, true, 8, Sound("weapons/hornet_missle.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 5) then
						self.NextUse.FireBlast = CurTime()+10;
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

function ENT:FireSabreBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("sabre_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = size or 30;
	e.EndSize = size*3 or 25;
	
	local sound = snd or Sound("weapons/hornet_missle.wav");
	
	e:SetPos(pos);
	e:Spawn();
	e:Activate();
	e:Prepare(self,sound,gravity,vel);
	e:SetColor(Color(255,255,255,1));
	
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/pelican_fly.wav"),
	}
	
	hook.Add("ScoreboardShow","SabreScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("Sabre");
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
		local self = p:GetNetworkedEntity("Sabre", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*130+self:GetForward()*-150;
			View = HALOVehicleView(self,975,285,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "SabreView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.SabreEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/orangecore1",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(80)
			blue:SetEndAlpha(5)
			blue:SetStartSize(35)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.SabreEnginePos = {
				self:GetPos()+self:GetRight()*-107+self:GetUp()*87+self:GetForward()*-425,
				self:GetPos()+self:GetRight()*60+self:GetUp()*87+self:GetForward()*-425,
				self:GetPos()+self:GetRight()*-263+self:GetUp()*79+self:GetForward()*-335,
				self:GetPos()+self:GetRight()*218+self:GetUp()*79+self:GetForward()*-335,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function SabreReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingSabre");
		local self = p:GetNWEntity("Sabre");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(2000);
			HALO_UNSCReticles(self);
			HALO_BlastIcon(self,10);			
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "SabreReticle", SabreReticle)

end