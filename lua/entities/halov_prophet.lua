ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"

ENT.PrintName = "Gravity Throne"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;

ENT.EntModel = "models/helios/headdress.mdl"; 
ENT.Vehicle = "halov_prophet"; 
ENT.StartHealth = 1000; 
ENT.Allegiance = "Covenant";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("vehicles/speeder_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_prophet");
	e:SetPos(tr.HitPos + Vector(0,0,75));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*-10+self:GetForward()*3.5;
	local driverAng = self:GetAngles()+Angle(0,90,0);
	self:SpawnChairs(driverPos,driverAng,false)
	
	self.ForwardSpeed = -100;
	self.BoostSpeed = -100
	self.AccelSpeed = 5;
	self.WeaponLocations = {
		Main = self:GetPos()+self:GetRight()*100+self:GetUp()*15,
	}
	self.HoverMod = 80;
	self.StartHover = 65;
	self.StandbyHoverAmount = 20;
	self.Bullet = HALOCreateBulletStructure(100,"plasma");
	
	self.SpeederClass = 2
	
	self.ExitModifier = {x=0,y=-50,z=0};

end

function ENT:Exit(kill)
	local p;
	if(IsValid(self.Pilot)) then
		p = self.Pilot;
	end
	self.BaseClass.Exit(self,kill);
	if(IsValid(p)) then
		p:SetEyeAngles(self:GetAngles() + Angle(0,180,0));
	end
end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetForward()*5+self:GetUp()*0;
	self.FrontPos = self:GetPos()+self:GetForward()*-5+self:GetUp()*0;
	self.MiddlePos = self:GetPos()+self:GetUp()*0;
	if(self.Inflight) then
		local UP = ZAxis; // Up direction. Leave
		self.RightDir = self.Entity:GetRight(); // Which way is right, local to the model
		self.FWDDir = self.Entity:GetForward(); // Forward Direction. Local to the model.	
		
		self:RunTraces();

		self.ExtraRoll = Angle(1,0,0);

	end
	
	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	
end
end

if CLIENT then
	ENT.Sounds={
		Engine=Sound(""),
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
		local self = p:GetNWEntity("HALOV_Prophet", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
			    if(DriverSeat:GetThirdPersonMode()) then
					local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-100+self:GetUp()*100+self:GetRight()*0;
					local face = ((self:GetPos() + Vector(0,0,50))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
		end
	end
	hook.Add("CalcView", "HALOV_ProphetView", CalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "HALOV_ProphetDrawPlayerModel", function( p )
		local self = p:GetNWEntity("HALOV_Prophet", NULL);
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
	
	function HALOV_ProphetReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Prophet");
		local self = p:GetNWEntity("HALOV_Prophet");
		if(Flying and IsValid(self)) then
			local WeaponsPos = self:GetPos()+self:GetRight()*100+self:GetUp()*15; // Position of your weapon
			HALO_Speeder_DrawHull(1000)

		end
	end
	hook.Add("HUDPaint", "HALOV_ProphetReticle", HALOV_ProphetReticle)
	
	
end