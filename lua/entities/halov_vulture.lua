ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "AC-220 Vulture"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/vulture.mdl"
ENT.Vehicle = "halov_vulture"
ENT.StartHealth = 10000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/heavybolt.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_vulture");
	e:SetPos(tr.HitPos + Vector(0,0,150));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetUp()*-100+self:GetRight()*170+self:GetForward()*405,
		Left = self:GetPos()+self:GetUp()*-100+self:GetRight()*-170+self:GetForward()*405,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 800;
	self.ForwardSpeed = 800;
	self.UpSpeed = 600;
	self.AccelSpeed = 5;
	self.CanBack = false;
	self.CanStrafe = true;
	self.Hover = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.Bullet = HALOCreateBulletStructure(200,"unsc");
	self.FireDelay = 0.3;
	self.NextBlast = 1;
	self.DontOverheat = true;
	self.ExitModifier = {x = 0, y = 400, z = 50};
	
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
                        self:GetPos() + self:GetForward() * 155 + self:GetRight() * 140 + self:GetUp() * 80, //1
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * -140 + self:GetUp() * 80, //1
						self:GetPos() + self:GetForward() * 135 + self:GetRight() * 140 + self:GetUp() * 80, //2
						self:GetPos() + self:GetForward() * 135 + self:GetRight() * -140 + self:GetUp() * 80, //2
						self:GetPos() + self:GetForward() * 115 + self:GetRight() * 140 + self:GetUp() * 80, //3
						self:GetPos() + self:GetForward() * 115 + self:GetRight() * -140 + self:GetUp() * 80, //3
						self:GetPos() + self:GetForward() * 95 + self:GetRight() * 140 + self:GetUp() * 80, //4
						self:GetPos() + self:GetForward() * 95 + self:GetRight() * -140 + self:GetUp() * 80, //4
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 140 + self:GetUp() * 80, //5
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -140 + self:GetUp() * 80, //5
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 130 + self:GetUp() * 80, //6
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -130 + self:GetUp() * 80, //6
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 120 + self:GetUp() * 80, //7
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -120 + self:GetUp() * 80, //7
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 150 + self:GetUp() * 80, //8
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -150 + self:GetUp() * 80, //8
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 160 + self:GetUp() * 80, //9
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -160 + self:GetUp() * 80, //9
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * 140 + self:GetUp() * 80, //10
						self:GetPos() + self:GetForward() * 75 + self:GetRight() * -140 + self:GetUp() * 80, //10
                    }
                    self:FireHALOV_VultureBlast(self.BlastPositions[self.NextBlast], false, 200, 200, true, 8, Sound("weapons/hornet_missle.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 21) then
						self.NextUse.FireBlast = CurTime()+15;
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

function ENT:FireHALOV_VultureBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("missle_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = 10;
	e.EndSize = 5;
	
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
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("HALOV_Vulture", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*-80+self:GetForward()*175;
			View = HALOVehicleView(self,655,215,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "HALOV_VultureView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_VultureEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/heatwave",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.01)
			blue:SetStartAlpha(90)
			blue:SetEndAlpha(10)
			blue:SetStartSize(80)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_VultureEnginePos = {
				self:GetPos()+self:GetRight()*-55+self:GetUp()*20+self:GetForward()*-325,
				self:GetPos()+self:GetRight()*5+self:GetUp()*20+self:GetForward()*-325,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_VultureReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Vulture");
		local self = p:GetNWEntity("HALOV_Vulture");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(10000);
			HALO_HeavyReticles(self);
			HALO_BlastIcon(self,15);			
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_VultureReticle", HALOV_VultureReticle)

end