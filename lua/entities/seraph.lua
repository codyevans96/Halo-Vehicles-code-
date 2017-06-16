ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-31 Seraph"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/seraph/seraph.mdl"
ENT.Vehicle = "seraph"
ENT.StartHealth = 1500;
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/ghost_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("seraph");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		BottomRight = self:GetPos()+self:GetUp()*40+self:GetRight()*100+self:GetForward()*275,
		TopRight = self:GetPos()+self:GetUp()*90+self:GetRight()*100+self:GetForward()*275,
		BottomLeft = self:GetPos()+self:GetUp()*40+self:GetRight()*-100+self:GetForward()*275,
		TopLeft = self:GetPos()+self:GetUp()*90+self:GetRight()*-100+self:GetForward()*275,
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
	self.Bullet = HALOCreateBulletStructure(50,"plasma");
	self.FireDelay = 0.1;
	self.NextBlast = 1;
	self.AlternateFire = true;
	self.DontOverheat = true;
	self.FireGroup = {"BottomLeft","TopLeft","BottomRight","TopRight"};
	self.ExitModifier = {x = 0, y = 350, z = 50};
    self.CanEject = false;

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
                        self:GetPos() + self:GetForward() * 275 + self:GetRight() * 100 + self:GetUp() * 90, //1
						self:GetPos() + self:GetForward() * 275 + self:GetRight() * -100 + self:GetUp() * 40, //1
						self:GetPos() + self:GetForward() * 275 + self:GetRight() * 100 + self:GetUp() * 40, //2
						self:GetPos() + self:GetForward() * 275 + self:GetRight() * -100 + self:GetUp() * 90, //2
                    }
                    self:FireSeraphBlast(self.BlastPositions[self.NextBlast], false, 300, 300, true, 8, Sound("weapons/banshee_bomb.wav"));
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

function ENT:FireSeraphBlast(pos,gravity,vel,dmg,white,size,snd)
	if(self.NextUse.FireBlast < CurTime()) then
		local e = ents.Create("plasma_blast");
		
		e.Damage = dmg or 600;
		e.IsWhite = white or false;
		e.StartSize = size or 20;
		e.EndSize = e.StartSize*2 or 15;
		
		
		local sound = snd or Sound("weapons/banshee_bomb.wav");
		
		e:SetPos(pos);
		e:Spawn();
		e:Activate();
		e:Prepare(self,sound,gravity,vel);
		e:SetColor(Color(20,205,0,1));
	end
	
end

end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/covenant_fly2.wav"),
	}
	
	hook.Add("ScoreboardShow","SeraphScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("Seraph");
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
		local self = p:GetNetworkedEntity("Seraph", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*130+self:GetForward()*-150;
			View = HALOVehicleView(self,975,285,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "SeraphView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.SeraphEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.16)
			blue:SetStartAlpha(35)
			blue:SetEndAlpha(10)
			blue:SetStartSize(45)
			blue:SetEndSize(10)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)
			
			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.05);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(55);
			heatwv:SetEndSize(50);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.SeraphEnginePos = {
				self:GetPos()+self:GetRight()*-25+self:GetUp()*80+self:GetForward()*-310,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function SeraphReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingSeraph");
		local self = p:GetNWEntity("Seraph");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(1500);
			HALO_CovenantReticles(self);
			HALO_BlastIcon(self,10);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "SeraphReticle", SeraphReticle)

end