ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-48 Revenant"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.Vehicle = "Revenant";
ENT.EntModel = "models/helios/revenant/revenant.mdl";
ENT.StartHealth = 800;
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/xwing_shoot.wav");

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("revenant");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.SeatClass = "phx_seat2";
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*13+self:GetForward()*39+self:GetRight()*16;
	local driverAng = self:GetAngles()+Angle(0,90,0);
	local passPos = self:GetPos()+self:GetUp()*19+self:GetForward()*32+self:GetRight()*-19
	self:SpawnChairs(driverPos,driverAng,true,passPos,driverAng);
	self.CanBack = true;
	self.ForwardSpeed = -350;
	self.BoostSpeed = -550
	self.AccelSpeed = 8;
	self.StartHover = 25;
	self.DontOverheat = true;
	self.CanBack = true;
	self.StandbyHoverAmount = 25;
	self.HoverMod = 10;
	self:Rotorwash(false);

end


function ENT:OnTakeDamage(dmg)

	local health=self:GetNetworkedInt("Health")-(dmg:GetDamage()/2)

	self:SetNWInt("Health",health);
	
	if(health<100) then
		self.CriticalDamage = true;
		self:SetNWBool("CriticalDamage",true);
	end
	
	
	if((health)<=0) then
		self:Bang()
	end
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
	self.BackPos = self:GetPos()+self:GetForward()*80+self:GetUp()*5
	self.FrontPos = self:GetPos()+self:GetForward()*-100+self:GetUp()*5
	self.MiddlePos = self:GetPos()+self:GetUp()*5;
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
		Engine=Sound("vehicles/revenant_fly.wav"),
	}
	
	local Health = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			local EnginePos = {
				self:GetPos()+self:GetForward()*120+self:GetRight()*55+self:GetUp()*20,
				self:GetPos()+self:GetForward()*120+self:GetRight()*-55+self:GetUp()*20,
			}
			self:Effects(EnginePos)
		end
		
	end

	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("Revenant", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-300+self:GetUp()*120;
					//local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					//local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
			
			if(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-300+self:GetUp()*120;
					//local pos = self:GetPos()+self:GetRight()*250+self:GetUp()*100;
					//local face = self:GetAngles() + Angle(0,-90,0);
					local face = ((self:GetPos() + Vector(0,0,100))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
		end
	end
	hook.Add("CalcView", "RevenantView", CalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "RevenantDrawPlayerModel", function( p )
		local self = p:GetNWEntity("Revenant", NULL);
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
	
	function RevenantReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingRevenant");
		local self = p:GetNWEntity("Revenant");
		if(Flying and IsValid(self)) then
				
			HALO_Speeder_DrawHull(800)
			HALO_Speeder_DrawSpeedometer()
	
		end
	end
	hook.Add("HUDPaint", "RevenantReticle", RevenantReticle)
	
	
end