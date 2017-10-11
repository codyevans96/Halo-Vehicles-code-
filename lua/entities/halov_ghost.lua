ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-32 Ghost"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.Vehicle = "halov_ghost";
ENT.EntModel = "models/helios/ghost/ghost.mdl";
ENT.StartHealth = 800;
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/ghost_shoot.wav");

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_ghost");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*19+self:GetForward()*42;
	local driverAng = self:GetAngles()+Angle(0,90,0);
	self.SeatClass = "phx_seat3"
	self:SpawnChairs(driverPos,driverAng,false)
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*-75+self:GetUp()*19+self:GetRight()*-20,
		Right = self:GetPos()+self:GetForward()*-75+self:GetUp()*19+self:GetRight()*20,
	}
	
	self.ForwardSpeed = -450;
	self.BoostSpeed = -650
	self.AccelSpeed = 10;
	self.HoverMod = 0.1;
	self.StartHover = 30;
	self.CanBack = true;
	self.Bullet = HALOCreateBulletStructure(70,"plasma");
	self.FireDelay = 0.1;
	self.DontOverheat = true;
	self.WeaponDir = self:GetAngles():Forward()*-1;
	self:SpawnWeapons();
	self.FireGroup = {"Left","Right",};
	self.StandbyHoverAmount = 10;
	self.HoverMod = 10;
	self.CanShoot = true;

end

function ENT:Boost()
	
	if(self.NextUse.Boost < CurTime()) then
		self.Accel.FWD = self.BoostSpeed;
		self.Boosting = true;
		self:EmitSound(Sound("vehicles/ghost_boost.wav"),85,100,1,CHAN_VOICE)
		self.BoostTimer = CurTime()+3;
		self.NextUse.Boost = CurTime() + 5;
	end

end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetForward()*100+self:GetUp()*0
	self.FrontPos = self:GetPos()+self:GetForward()*-100+self:GetUp()*0
	self.MiddlePos = self:GetPos()+self:GetUp()*0;		
	if(self.Inflight) then
		local UP = ZAxis;
		self.RightDir = self.Entity:GetForward():Cross(UP):GetNormalized();
		self.FWDDir = self.Entity:GetForward();	
		

		self:RunTraces();

		self.ExtraRoll = Angle(0,0,self.YawAccel / 2);
		if(!self.WaterTrace.Hit) then
			if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
				self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/2*-1,0,0)
			else
				self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/2*-1,0,0)
			end
		end
	end

	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("vehicles/ghost_fly.wav"),
	}
	
	local Health = 0;
	local Speed = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			Speed = self:GetNWInt("Speed");
		end
		
	end

	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("HALOV_Ghost", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);
		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+self:GetForward()*270+self:GetUp()*100;
					//local face = self:GetAngles() + Angle(0,180,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
		end
	end
	hook.Add("CalcView", "HALOV_GhostView", CalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "HALOV_GhostDrawPlayerModel", function( p )
		local self = p:GetNWEntity("HALOV_Ghost", NULL);
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					return true;
				end
			elseif(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_GhostEnginePos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.06)
			blue:SetStartAlpha(155)
			blue:SetEndAlpha(8)
			blue:SetStartSize(2)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_GhostEnginePos = {
				self:GetPos()+self:GetRight()*-62+self:GetUp()*20+self:GetForward()*-30,
				self:GetPos()+self:GetRight()*12+self:GetUp()*20+self:GetForward()*-30,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_GhostReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Ghost");
		local self = p:GetNWEntity("HALOV_Ghost");
		if(Flying and IsValid(self)) then
			local WeaponsPos = {self:GetPos()};
			
			HALO_CovenantHoverReticles(self,WeaponsPos)
			HALO_Speeder_DrawHull(800)
			HALO_Speeder_DrawSpeedometer()

		end
	end
	hook.Add("HUDPaint", "HALOV_GhostReticle", HALOV_GhostReticle)
	
	
end