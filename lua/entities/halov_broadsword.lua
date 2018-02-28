ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "F-41 Broadsword"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/broadsword.mdl"
ENT.Vehicle = "halov_broadsword"
ENT.StartHealth = 3000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/heavybolt.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_broadsword");
	e:SetPos(tr.HitPos + Vector(0,0,250));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetUp()*-170+self:GetRight()*53+self:GetForward()*185,
		Left = self:GetPos()+self:GetUp()*-170+self:GetRight()*-53+self:GetForward()*185,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2600;
	self.ForwardSpeed = 2600;
	self.UpSpeed = 1600;
	self.AccelSpeed = 10;
	self.CanBack = false;
	self.CanStrafe = true;
	self.Hover = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.Bullet = HALOCreateBulletStructure(120,"unsc");
	self.FireDelay = 0.1;
	self.NextBlast = 1;
	self.AlternateFire = true;
	self.DontOverheat = true;
	self.FireGroup = {"Left","Right"};
	self.ExitModifier = {x = 0, y = 350, z = -100};
	
	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=170,z=-125};
	self.PilotAnim = "drive_jeep";
	
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
                        self:GetPos() + self:GetForward() * 155 + self:GetRight() * 160 + self:GetUp() * -100, //1
						self:GetPos() + self:GetForward() * 155 + self:GetRight() * -160 + self:GetUp() * -100, //1
                    }
                    self:FireHALOV_BroadswordBlast(self.BlastPositions[self.NextBlast], false, 300, 300, true, 8, Sound("weapons/rocket.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 3) then
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

function ENT:FireHALOV_BroadswordBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("missle_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = 15;
	e.EndSize = 5;
	
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
		Engine=Sound("vehicles/pelican_fly.wav"),
	}
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("HALOV_Broadsword", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*-80+self:GetForward()*175;
			View = HALOVehicleView(self,955,55,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "HALOV_BroadswordView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_BroadswordBigEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.03)
			blue:SetStartAlpha(90)
			blue:SetEndAlpha(10)
			blue:SetStartSize(40)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
		for k,v in pairs(self.HALOV_BroadswordSmallEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.03)
			blue:SetStartAlpha(90)
			blue:SetEndAlpha(10)
			blue:SetStartSize(20)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_BroadswordBigEnginePos = {
				self:GetPos()+self:GetRight()*-75+self:GetUp()*-152+self:GetForward()*-335,
				self:GetPos()+self:GetRight()*25+self:GetUp()*-152+self:GetForward()*-335,
			}
			self.HALOV_BroadswordSmallEnginePos = {
				self:GetPos()+self:GetRight()*-43+self:GetUp()*-112+self:GetForward()*-290,
				self:GetPos()+self:GetRight()*-7+self:GetUp()*-112+self:GetForward()*-290,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_BroadswordReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Broadsword");
		local self = p:GetNWEntity("HALOV_Broadsword");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(3000);
			HALO_UNSCReticles(self);
			HALO_BlastIcon(self,5);			
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_BroadswordReticle", HALOV_BroadswordReticle)

end