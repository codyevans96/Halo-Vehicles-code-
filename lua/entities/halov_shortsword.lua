ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "B-65 Shortsword"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/shortsword.mdl"
ENT.Vehicle = "halov_shortsword"
ENT.StartHealth = 3000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/heavybolt.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_shortsword");
	e:SetPos(tr.HitPos + Vector(0,0,100));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetUp()*-20+self:GetRight()*53+self:GetForward()*255,
		Left = self:GetPos()+self:GetUp()*-20+self:GetRight()*-53+self:GetForward()*255,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2200;
	self.ForwardSpeed = 2200;
	self.UpSpeed = 1600;
	self.AccelSpeed = 10;
	self.CanBack = false;
	self.CanStrafe = true;
	self.Hover = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.Bullet = HALOCreateBulletStructure(120,"unsc");
	self.FireDelay = 0.2;
	self.NextBlast = 1;
	self.AlternateFire = true;
	self.DontOverheat = true;
	self.FireGroup = {"Left","Right"};
	self.ExitModifier = {x = 0, y = 350, z = -100};
	
	self.PilotVisible = false;
	
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
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //1
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //2
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //3
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //4
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //5
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * 0 + self:GetUp() * -100, //6
                    }
                    self:FireHALOV_ShortswordBlast(self.BlastPositions[self.NextBlast],true,0.5,600,false,7);
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 7) then
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

function ENT:FireHALOV_ShortswordBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("missle_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = true;
	e.StartSize = 15;
	e.EndSize = 5;
	
	local sound = snd or Sound("weapons/macgun.wav");
	
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
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("HALOV_Shortsword", NULL)
		if(IsValid(self)) then
			View = HALOVehicleView(self,755,105,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "HALOV_ShortswordView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_ShortswordEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/tfaenginered",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.1)
			blue:SetStartAlpha(50)
			blue:SetEndAlpha(10)
			blue:SetStartSize(80)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(5,255,255)

		end
	end
	
	function ENT:Think()
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_ShortswordEnginePos = {
				self:GetPos()+self:GetRight()*-68+self:GetUp()*-28+self:GetForward()*-95,
				self:GetPos()+self:GetRight()*16+self:GetUp()*-28+self:GetForward()*-95,
				self:GetPos()+self:GetRight()*-372+self:GetUp()*72+self:GetForward()*-305,
				self:GetPos()+self:GetRight()*320+self:GetUp()*72+self:GetForward()*-305,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_ShortswordReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Shortsword");
		local self = p:GetNWEntity("HALOV_Shortsword");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(3000);
			HALO_UNSCReticles(self);
			HALO_BlastIcon(self,10);			
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_ShortswordReticle", HALOV_ShortswordReticle)

end