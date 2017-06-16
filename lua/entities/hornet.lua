ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "AV-14 Hornet"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/hornet/hornet.mdl"
ENT.FlyModel = "models/helios/hornet/hornet_fwd.mdl"
ENT.Vehicle = "hornet"
ENT.StartHealth = 800;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/hornet_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("hornet");
	e:SetPos(tr.HitPos + Vector(0,0,5));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*60+self:GetUp()*100+self:GetRight()*-30,
		Right = self:GetPos()+self:GetForward()*60+self:GetUp()*100+self:GetRight()*30,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1000;
	self.ForwardSpeed = 1000;
	self.UpSpeed = 600;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanStrafe = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.DontOverheat = true;
	self.Bullet = HALOCreateBulletStructure(70,"unsc");
	self.FireDelay = 0.1;
	self.NextBlast = 1;
	self.AlternateFire = true;
	self.FireGroup = {"Left","Right",};
	self.ExitModifier = {x = 0, y = 200, z = 50};
    self.Hover = true;
	self.LandOffset = Vector(0,0,5);
	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=93,z=35};
	self.PilotAnim = "drive_jeep";
	
	self.SeatPos = {
		{self:GetPos()+self:GetUp()*17+self:GetRight()*28+self:GetForward()*64, self:GetAngles()+Angle(0,-135,0)},
		{self:GetPos()+self:GetUp()*17+self:GetRight()*-28+self:GetForward()*64, self:GetAngles()+Angle(0,-45,0)},
	};
	self:SpawnSeats();

	self.BaseClass.Initialize(self);
	
end

function ENT:Enter(p)
    if(!IsValid(self.Pilot)) then
        self:SetModel(self.FlyModel);
    end
    self.BaseClass.Enter(self,p);
end
    
function ENT:Exit(kill)
    local p = self.Pilot;
    if(self.Land or self.TakeOff) then
        self:SetModel(self.EntModel);
    end
	self.BaseClass.Exit(self,kill);
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
		e:SetVehicleClass("aim_chair");
		e:SetUseType(USE_OFF);
		e:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		//e:GetPhysicsObject():EnableCollisions(false);
		e.IsHornetSeat = true;
		e.Hornet = self;
		self.Seats[k] = e;
	end

end

hook.Add("PlayerEnteredVehicle","HornetSeatEnter", function(p,v)
	if(IsValid(v) and IsValid(p)) then
		if(v.IsHornetSeat) then
			p:SetNetworkedEntity("Hornet",v:GetParent());
            p:SetNetworkedEntity("HornetSeat",v);
			p:SetNetworkedBool("HornetPassenger",true);
		end
	end
end);

hook.Add("PlayerLeaveVehicle", "HornetSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsHornetSeat) then
            if(v.HornetFrontSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*0+self:GetUp()*0);
            else
                p:SetPos(v:GetPos()+v:GetForward()*30+v:GetUp()*30+v:GetRight()*0);
            end
			p:SetNetworkedEntity("Hornet",NULL);
            p:SetNetworkedEntity("HornetSeat",NULL);
			p:SetNetworkedBool("HornetPassenger",false);
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
    
function ENT:Think()
 
    if(self.Inflight) then
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK2) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * 40 + self:GetRight() * 35 + self:GetUp() * 10, //1
						self:GetPos() + self:GetForward() * 40 + self:GetRight() * -35 + self:GetUp() * 10, //1
                    }
                    self:FireHornetBlast(self.BlastPositions[self.NextBlast], false, 250, 250, true, 8, Sound("weapons/hornet_missle.wav"));
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

function ENT:FireHornetBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("missle_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = size or 20;
	e.EndSize = size*0.75 or 15;
	
	local sound = snd or Sound("weapons/hornet_missle.wav");
	
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
		Engine=Sound("vehicles/hornet_fly.wav"),
	}
	
	hook.Add("ScoreboardShow","HornetScoreDisable", function()
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("Hornet");
		if(Flying) then
			return false;
		end
	end)
	
	local View = {}
	local function CalcView()
		
		local p = LocalPlayer();	
		local Flying = p:GetNWBool("FlyingHornet");
		local Sitting = p:GetNWBool("HornetPassenger");
		local pos, face;
		local self = p:GetNWEntity("Hornet");
	
		
		if(Flying) then
			if(IsValid(self)) then
				local fpvPos = self:GetPos()+self:GetUp()*72+self:GetForward()*87;
				View = HALOVehicleView(self,470,175,fpvPos,true);		
				return View;
			end
		elseif(Sitting) then
			local v = p:GetNWEntity("HornetSeat");	
			if(IsValid(v)) then
				if(v:GetThirdPersonMode()) then
					View = HALOVehicleView(self,470,170,fpvPos);		
					return View;
				end
			end
		end
		
	end
	hook.Add("CalcView", "HornetView", CalcView)
	
	hook.Add( "ShouldDrawLocalPlayer", "HornetDrawPlayerModel", function( p )
		local self = p:GetNWEntity("Hornet", NULL);
		local PassengerSeat = p:GetNWEntity("HornetSeat",NULL);
		if(IsValid(self)) then
			if(IsValid(PassengerSeat)) then
				if(PassengerSeat:GetThirdPersonMode()) then
					return true;
				end
			end
		end
	end);
	
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
		for k,v in pairs(self.HornetEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.05);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(15);
			heatwv:SetEndSize(20);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(55)
			blue:SetEndAlpha(5)
			blue:SetStartSize(15)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HornetEnginePos = {
				self:GetPos()+self:GetRight()*-136.5+self:GetUp()*105+self:GetForward()*2,
				self:GetPos()+self:GetRight()*85.5+self:GetUp()*105+self:GetForward()*2,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HornetReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHornet");
		local self = p:GetNWEntity("Hornet");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(800);
			HALO_UNSCReticles(self);
			HALO_BlastIcon(self,5);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HornetReticle", HornetReticle)

end