ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-52 Phantom"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/phantom/phantom_open.mdl"
ENT.Vehicle = "halov_phantom"
ENT.StartHealth = 5000;
ENT.Allegiance = "Covenant";

ENT.DoorsModel = "models/helios/phantom/phantom.mdl"
ENT.ClosedModel = "models/helios/phantom/phantom_open.mdl"

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/phantom_shoot.wav");
ENT.NextUse = {Doors = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_phantom");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Right = self:GetPos()+self:GetForward()*380+self:GetUp()*10+self:GetRight()*0,
		Left = self:GetPos()+self:GetForward()*380+self:GetUp()*10+self:GetRight()*0,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 2000;
	self.ForwardSpeed = 2000;
	self.UpSpeed = 500;
	self.AccelSpeed = 9;
	self.CanStandby = true;
	self.CanBack = true;
    self.CanStrafe = true;
	self.CanShoot = false;
	self.DontOverheat = true;
	self.AlternateFire = true;
	self.FireGroup = {"Right","Left"}
	self.Hover = true;
	self.HasDoors = true;
	self.Cooldown = 2;
	self.LandOffset = Vector(0,0,30);
	
	self.Bullet = HALOCreateBulletStructure(80,"red");
	self.FireDelay = 0.25;
	self.NextBlast = 1;
	
	self.SeatPos = {
	
		{self:GetPos()+self:GetUp()*158+self:GetRight()*0+self:GetForward()*-90, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*0+self:GetForward()*67, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*0+self:GetForward()*-13, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*-243.5, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*-243.5, self:GetAngles()+Angle(0,-90,0)},
	
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*-166.5, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*-166.5, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*-115.5, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*-115.5, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*-61, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*-61, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*-10, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*-10, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*41.5, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*41.5, self:GetAngles()+Angle(0,-90,0)},
		
		{self:GetPos()+self:GetUp()*158+self:GetRight()*-72.5+self:GetForward()*92, self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetUp()*158+self:GetRight()*72.5+self:GetForward()*92, self:GetAngles()+Angle(0,-90,0)},
		
	};
	
	self:SpawnSeats();
	self.ExitModifier = {x=0,y=95,z=175};

	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=282,z=123};

	self.HasLookaround = true;
	self.BaseClass.Initialize(self);
end


function ENT:SpawnSeats()
	self.Seats = {};
	for k,v in pairs(self.SeatPos) do
		local e = ents.Create("prop_vehicle_prisoner_pod");
		e:SetPos(v[1]);
		e:SetAngles(v[2]);
		e:SetParent(self);		
		e:SetModel("models/nova/airboat_seat.mdl");
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetColor(Color(255,255,255,0));	
		e:Spawn();
		e:Activate();
		e:SetVehicleClass("idle_chair");
		e:SetUseType(USE_OFF);
		e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		//e:GetPhysicsObject():EnableCollisions(false);
		e.IsHALOV_PhantomSeat = true;
		e.HALOV_Phantom = self;
		self.Seats[k] = e;
	end

end

hook.Add("PlayerEnteredVehicle","HALOV_PhantomSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsHALOV_PhantomSeat) then
			p:SetNetworkedEntity("HALOV_Phantom",v:GetParent());
            p:SetNetworkedEntity("HALOV_PhantomSeat",v);
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "HALOV_PhantomSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsHALOV_PhantomSeat) then
            if(v.HALOV_PhantomFrontSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*270+self:GetUp()*170);
            else
                p:SetPos(v:GetPos()+v:GetForward()*0+v:GetUp()*30+v:GetRight()*0);
            end
			p:SetNetworkedEntity("HALOV_Phantom",NULL);
            p:SetNetworkedEntity("HALOV_PhantomSeat",NULL);
		end
	end
end);

function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetPassenger(1) == NULL) then
			p:EnterVehicle(v);
			return;
		end
	end
end
 
function ENT:Use(p)
   if(not self.Inflight) then
       if(!p:KeyDown(IN_WALK)) then
           self:Enter(p);
       else
           self:Passenger(p);
       end
   else
       if(p != self.Pilot) then
           self:Passenger(p);
       end
   end
end

function ENT:ToggleDoors()
    if(!IsValid(self)) then return end;
	if(self.NextUse.Doors < CurTime()) then
		if(self.Doors) then
			self:SetModel(self.ClosedModel);
			self.Doors = false;
		else
			self.Doors = true;
			self:SetModel(self.DoorsModel);
		end
		self.NextUse.Doors = CurTime() + 1;
	end
end

function ENT:Think()
 
    if(self.Inflight) then
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 380 + self:GetRight() * 0 + self:GetUp() * 10, //1
                    }
                    self:FireHALOV_PhantomBlast(self.BlastPositions[self.NextBlast], false, 160, 160, true, 8, Sound("weapons/phantom_shoot.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 2) then
						self.NextUse.FireBlast = CurTime()+0.40;
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

function ENT:FireHALOV_PhantomBlast(pos,gravity,vel,dmg,white,size,snd)
	if(self.NextUse.FireBlast < CurTime()) then
		local e = ents.Create("shadow2_blast");
		
		e.Damage = dmg or 600;
		e.IsWhite = white or false;
		e.StartSize = size or 20;
		e.EndSize = e.StartSize*2 or 15;
		
		
		local sound = snd or Sound("weapons/phantom_shoot.wav");
		
		e:SetPos(pos);
		e:Spawn();
		e:Activate();
		e:Prepare(self,sound,gravity,vel);
		e:SetColor(Color(255,255,255,1));
	end
	
end

end

if CLIENT then

	function ENT:Draw() self:DrawModel() end
	
	ENT.EnginePos = {}
	ENT.Sounds={
		Engine=Sound("vehicles/covenant_fly.wav"),
	}
	ENT.CanFPV = false;
	
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
		for k,v in pairs(self.HALOV_PhantomEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.04);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(80);
			heatwv:SetEndSize(65);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.06)
			blue:SetStartAlpha(35)
			blue:SetEndAlpha(0)
			blue:SetStartSize(70)
			blue:SetEndSize(65)
			blue:SetRoll(roll)
			blue:SetColor(218,180,214)

		end
		for k,v in pairs(self.HALOV_PhantomSupportPos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.02);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(40);
			heatwv:SetEndSize(15);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.02)
			blue:SetStartAlpha(155)
			blue:SetEndAlpha(0)
			blue:SetStartSize(50)
			blue:SetEndSize(25)
			blue:SetRoll(roll)
			blue:SetColor(218,180,214)

		end
	end
	
	function ENT:Think()
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HALOV_PhantomEnginePos = {
				self:GetPos()+self:GetForward()*-310+self:GetUp()*200+self:GetRight()*135,
				self:GetPos()+self:GetForward()*-310+self:GetUp()*200+self:GetRight()*-185,
			}
			self.HALOV_PhantomSupportPos = {
				self:GetPos()+self:GetForward()*-90+self:GetUp()*115+self:GetRight()*95,
				self:GetPos()+self:GetForward()*80+self:GetUp()*115+self:GetRight()*95,
				self:GetPos()+self:GetForward()*80+self:GetUp()*115+self:GetRight()*-140,
				self:GetPos()+self:GetForward()*-90+self:GetUp()*115+self:GetRight()*-140,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	hook.Add( "ShouldDrawLocalPlayer", "CGILAATDrawPlayerModel", function( p )
		local self = p:GetNWEntity("CGILAAT", NULL);
		local PassengerSeat = p:GetNWEntity("CGILAATSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingHALOV_Phantom");
		local Sitting = p:GetNWBool("HALOV_PhantomPassenger");
		local pos, face;
		local self = p:GetNWEntity("HALOV_Phantom");
	
		
		if(Flying) then
			if(IsValid(self)) then
				View = HALOVehicleView(self,1250,630,fpvPos,true);		
				return View;
			end
		elseif(Sitting) then
			local v = p:GetNWEntity("HALOV_PhantomSeat");	
			if(IsValid(v)) then
				if(v:GetThirdPersonMode()) then
					View = HALOVehicleView(self,800,380,fpvPos);		
					return View;
				end
			end
		end
		
	end
	hook.Add("CalcView", "HALOV_PhantomView", CalcView)

	function HALOV_PhantomReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Phantom");
		local self = p:GetNWEntity("HALOV_Phantom");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(5000);
			HALO_CovenantReticles(self);
			HALO_HUD_Compass(self);
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_PhantomReticle", HALOV_PhantomReticle)

end