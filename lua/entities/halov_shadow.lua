ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"

ENT.PrintName = "T-29 Shadow"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.Vehicle = "halov_shadow";
ENT.EntModel = "models/helios/shadow/shadow.mdl";
ENT.StartHealth = 2000;

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/plasma_shoot.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_shadow");
	e:SetPos(tr.HitPos + Vector(0,0,10));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*40+self:GetForward()*-90;
	local driverAng = self:GetAngles()+Angle(0,90,0);
	self:SpawnChairs(driverPos,driverAng,false);
	
	self.ForwardSpeed = -300;
	self.BoostSpeed = -550
	self.AccelSpeed = 6;
	self.HoverMod = 0.5;
	self.SpeederClass = 2;
	self.NoWobble = true;
	self.CanShoot = false;
	self.WeaponDir = self:GetAngles():Forward()*-1;
	self.CannonLocation = self:GetPos()+self:GetUp()*60+self:GetForward()*-10;
	
	self.SeatPos = {
		{self:GetPos()+self:GetForward()*-20+self:GetUp()*15+self:GetRight()*21,self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetForward()*-20+self:GetUp()*15+self:GetRight()*-21,self:GetAngles()+Angle(0,90,0)},
		{self:GetPos()+self:GetForward()*5+self:GetUp()*15+self:GetRight()*21,self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetForward()*5+self:GetUp()*15+self:GetRight()*-21,self:GetAngles()+Angle(0,90,0)},
		{self:GetPos()+self:GetForward()*30+self:GetUp()*15+self:GetRight()*21,self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetForward()*30+self:GetUp()*15+self:GetRight()*-21,self:GetAngles()+Angle(0,90,0)},
		{self:GetPos()+self:GetForward()*55+self:GetUp()*15+self:GetRight()*21,self:GetAngles()+Angle(0,-90,0)},
		{self:GetPos()+self:GetForward()*55+self:GetUp()*15+self:GetRight()*-21,self:GetAngles()+Angle(0,90,0)},
	
	}
	self:SpawnSeats();
	
	self.CanBack = true;
	self.StartHover = 30;
	
	self:SpawnTurret();
	
end

function ENT:SpawnSeats()
	self.Seats = {};
	for k,v in pairs(self.SeatPos) do
		local e = ents.Create("prop_vehicle_prisoner_pod");
		e:SetPos(v[1]);
		e:SetAngles(v[2]+Angle(0,-90,0));
		e:SetParent(self);		
		e:SetModel("models/nova/airboat_seat.mdl");
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetColor(Color(255,255,255,0));	
		e:Spawn();
		e:Activate();
		e:SetUseType(USE_OFF);
		e:GetPhysicsObject():EnableMotion(false);
		e:GetPhysicsObject():EnableCollisions(false);
		e.IsHALOV_ShadowSeat = true;
		e.HALOV_Shadow = self;

		self.Seats[k] = e;
	end

end

hook.Add("PlayerEnteredVehicle","HALOV_ShadowSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsHALOV_ShadowSeat) then
			p:SetNetworkedEntity("HALOV_Shadow",v:GetParent());
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "HALOV_ShadowSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsHALOV_ShadowSeat) then
			local e = v.HALOV_Shadow;
			p:SetPos(v:GetPos()+v:GetForward()*50+v:GetUp()*5+v:GetRight()*0);
			p:SetNetworkedEntity("HALOV_Shadow",NULL);
		end
	end
end);

function ENT:PassengerEnter(p)
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
			self:Enter(p,true);
		else
			self:PassengerEnter(p);
		end
	else
		if(p != self.Pilot) then
			self:PassengerEnter(p);
		end
	end
end

function ENT:SpawnTurret()
	
	local e = ents.Create("prop_physics");
	e:SetPos(self:GetPos()+self:GetUp()*100+self:GetForward()*-58);
	e:SetAngles(self:GetAngles());
	e:SetModel("models/helios/shadow/shadow_gun.mdl");
	e:SetParent(self);
	e:Spawn();
	e:Activate();
	e:GetPhysicsObject():EnableCollisions(false);
	e:GetPhysicsObject():EnableMotion(false);
	self.Turret = e;
	self:SetNWEntity("Turret",e);
	
end

local lastY = 0;

function ENT:FireBlast(pos,gravity,vel,ang)
    if(self.NextUse.FireBlast < CurTime()) then
        local e = ents.Create("shadow_blast");
        e:SetPos(pos);
        e:Spawn();
        e:Activate();
        e:Prepare(self,Sound("weapons/banshee_shoot.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 0.35;
    end
   
end

function ENT:Think()
	self.BaseClass.Think(self)
	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
		

			self.Turret.LastAng = self.Turret:GetAngles();
		
			local aim = self.Pilot:GetAimVector():Angle();
			local p = aim.p*-1;
			if(p <= -0 and p >= -40) then
				p = -0;
			elseif(p >= -300 and p <= 280) then
				p = -300;
			end
			self.Turret:SetAngles(Angle(p,aim.y+180,0));
			if(self.Pilot:KeyDown(IN_ATTACK)) then
				self:FireBlast(self.Turret:GetPos()+self.Turret:GetForward()*-60+self.Turret:GetUp()*40,true,-3,self.Turret:GetAngles():Forward());
			end
			lastY = aim.y;
			self:NextThink(CurTime());
			return true;
		end
	end
	
end

function ENT:Exit(driver,kill)
	
	self.BaseClass.Exit(self,driver,kill);
	if(IsValid(self.Turret)) then
		self.Turret:SetAngles(self.Turret.LastAng);
	end
	
end

function ENT:Boost()
	
	if(self.NextUse.Boost < CurTime()) then
		self.Accel.FWD = self.BoostSpeed;
		self.Boosting = true;
		self:EmitSound(Sound("vehicles/ghost_boost.wav"),85,100,1,CHAN_VOICE)
		self.BoostTimer = CurTime()+5;
		self.NextUse.Boost = CurTime() + 15;
	end

end

local ZAxis = Vector(0,0,1);

function ENT:PhysicsSimulate( phys, deltatime )
	self.BackPos = self:GetPos()+self:GetForward()*100;
	self.FrontPos = self:GetPos()+self:GetForward()*-145;
	self.MiddlePos = self:GetPos();
	if(self.Inflight) then
		local UP = ZAxis;
		self.RightDir = self.Entity:GetForward():Cross(UP):GetNormalized();
		self.FWDDir = self.Entity:GetForward();

		if(IsValid(self.Pilot)) then
			if(self.Pilot:KeyDown(IN_JUMP)) then
				self.Right = 0;
			elseif(self.Pilot:KeyDown(IN_WALK)) then
				self.Right = 0;
			else
				self.Right = 0;
			end
		end
		self.Accel.RIGHT = math.Approach(self.Accel.RIGHT,self.Right,5);
		

		
		self:RunTraces();

		self.ExtraRoll = Angle(0,0,self.YawAccel / 4);
		if(!self.WaterTrace.Hit) then
			if(self.FrontTrace.HitPos.z >= self.BackTrace.HitPos.z) then
				self.PitchMod = Angle(math.Clamp((self.BackTrace.HitPos.z - self.FrontTrace.HitPos.z),-45,45)/3*-1,0,0)
			else
				self.PitchMod = Angle(math.Clamp(-(self.FrontTrace.HitPos.z - self.BackTrace.HitPos.z),-45,45)/3*-1,0,0)
			end
		end
	end

	self.BaseClass.PhysicsSimulate(self,phys,deltatime);
	

end

end

if CLIENT then
	ENT.Sounds={
		Engine=Sound("vehicles/wraith_fly.wav"),
	}
	
	local Health = 0;
	local Target;
	local Turret;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local Flying = p:GetNWBool("Flying"..self.Vehicle);
		if(Flying) then
			Health = self:GetNWInt("Health");
			Target = self:GetNWVector("Target");
			Turret = self:GetNWEntity("Turret");
		end
		
	end

	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("HALOV_Shadow", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
		local PassengerSeat = p:GetNWEntity("PassengerSeat",NULL);

		if(IsValid(self) and IsValid(Turret)) then

			if(IsValid(DriverSeat)) then
				if(DriverSeat:GetThirdPersonMode()) then
					--- local pos = Turret:GetPos()+Turret:GetForward()*470+Turret:GetUp()*100;
					local pos = self:GetPos()+self:GetForward()*450+self:GetUp()*250;
					local face = ((self:GetPos() + Vector(0,0,250))- pos):Angle();
						View.origin = pos;
						View.angles = face;
					return View;
				end
			end
			
		end
	end
	hook.Add("CalcView", "HALOV_ShadowView", CalcView)

	
	hook.Add( "ShouldDrawLocalPlayer", "HALOV_ShadowDrawPlayerModel", function( p )
		local self = p:GetNWEntity("HALOV_Shadow", NULL);
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
	
	function HALOV_ShadowReticle()
	
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Shadow");
		local self = p:GetNWEntity("HALOV_Shadow");
		if(Flying and IsValid(self)) then
surface.SetDrawColor( color_white )	
			local TurretPos = Turret:GetPos()+Turret:GetForward()*-40;
			local tr = util.TraceLine({
				start = TurretPos,
				endpos = TurretPos + Turret:GetForward()*-10000,
				filter = {self,Turret},
			});
			
			local vpos = tr.HitPos;
			local screen = vpos:ToScreen();
			local x,y;
			for k,v in pairs(screen) do
				if(k == "x") then
					x = v;
				elseif(k == "y") then
					y = v;
				end
			end
			
			local w = ScrW()/100*2;
			local h = w;
			x = x - w/2;
			y = y - h/2;
			surface.SetMaterial( Material( "hud/reticle_cov.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
			
			vpos = tr.HitPos;
			screen = vpos:ToScreen();
			x = 0;
			y = 0;
			for k,v in pairs(screen) do
				if(k == "x") then
					x = v;
				elseif(k == "y") then
					y = v;
				end
			end
			
			x = x - w/2;
			y = y - h/2;
			
			surface.SetMaterial( Material( "hud/reticle_cov.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
	
			HALO_Speeder_DrawHull(2000)
			HALO_Speeder_DrawSpeedometer()
	
		end
	end
	hook.Add("HUDPaint", "HALOV_ShadowReticle", HALOV_ShadowReticle)
	
	
end