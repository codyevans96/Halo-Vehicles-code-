ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "UH-144 Falcon"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

ENT.EntModel = "models/helios/falcon/falcon_idle.mdl"
ENT.FlyModel = "models/helios/falcon/falcon_fly.mdl"
ENT.Vehicle = "halov_falcon"
ENT.StartHealth = 3000;
ENT.Allegiance = "UNSC";

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/lightbolt.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_falcon");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*180+self:GetUp()*5+self:GetRight()*-0,
		Right = self:GetPos()+self:GetForward()*180+self:GetUp()*5+self:GetRight()*0,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 1200;
	self.ForwardSpeed = 1200;
	self.UpSpeed = 1000;
	self.AccelSpeed = 10;
	self.CanBack = true;
	self.CanStrafe = true;
	self.Cooldown = 2;
	self.CanShoot = true;
	self.DontOverheat = true;
	self.Bullet = HALOCreateBulletStructure(50,"unsc");
	self.FireDelay = 0.1;
	self.AlternateFire = true;
	self.FireGroup = {"Left","Right",};
	self.ExitModifier = {x = 0, y = 250, z = 10};
    self.Hover = true;
	self.SeatPos = {
            
		BackL = {self:GetPos()+self:GetForward()*40+self:GetRight()*-22+self:GetUp()*38,self:GetAngles()+Angle(0,180,0)},
		BackR = {self:GetPos()+self:GetForward()*40+self:GetRight()*22+self:GetUp()*38,self:GetAngles()+Angle(0,180,0)},
		Back = {self:GetPos()+self:GetForward()*-34+self:GetRight()*0+self:GetUp()*37,self:GetAngles()+Angle(0,0,0)},
		SideR = {self:GetPos()+self:GetForward()*-40+self:GetUp()*30+self:GetRight()*35,self:GetAngles()+Angle(0,-90,0)},
		SideL = {self:GetPos()+self:GetForward()*-40+self:GetUp()*30+self:GetRight()*-35,self:GetAngles()+Angle(0,90,0)},
	}
	self:SpawnSeats();
	self.HasLookaround = true;
	self.PilotVisible = true;
	self.PilotPosition = {x=0,y=99,z=34};
	self.PilotAnim = "drive_jeep";

	self.BaseClass.Initialize(self);
	
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
		e.IsHALOV_FalconSeat = true;
		e.HALOV_Falcon = self;
		if(k == "Back") then
            e.HALOV_FalconBackSeat = true;
		elseif(k == "BackR") then
            e.HALOV_FalconBackRSeat = true;
		elseif(k == "BackL") then
            e.HALOV_FalconBackLSeat = true;
		elseif(k == "SideR") then
            e.HALOV_FalconSideRSeat = true;
        elseif(k == "SideL") then
		    e.HALOV_FalconSideLSeat = true;
		end
		self.Seats[k] = e;
	end

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

function ENT:Passenger(p)
	if(self.NextUse.Use > CurTime()) then return end;
	for k,v in pairs(self.Seats) do
		if(v:GetPassenger(1) == NULL) then
			p:EnterVehicle(v);
			p:SetAllowWeaponsInVehicle( false )
			return;			
		end
	end
end


function ENT:Use(p)
	if(not self.Inflight) then
		if(!p:KeyDown(IN_WALK)) then
            local min = self:GetPos()+self:GetForward()*55+self:GetUp()*15+self:GetRight()*-113;
            local max = self:GetPos()+self:GetForward()*165+self:GetUp()*75+self:GetRight()*54
            for k,v in pairs(ents.FindInBox(min,max)) do
               if(v == p) then
                    self:Enter(p);
                    break;
                end
            end	
		else
			self:Passenger(p);
		end
	else
		if(p != self.Pilot) then
			self:Passenger(p);
		end
	end
end

hook.Add("PlayerLeaveVehicle", "HALOV_FalconSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsHALOV_FalconSeat) then
			if(v.HALOV_FalconBackLSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*40+self:GetUp()*20+self:GetRight()*-90);
			elseif(v.HALOV_FalconBackRSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*40+self:GetUp()*20+self:GetRight()*90);
			elseif(v.HALOV_FalconBackSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*-90+self:GetUp()*20+self:GetRight()*-110);
			elseif(v.HALOV_FalconSideLSeat) then
                local self = v:GetParent();
                p:SetPos(self:GetPos()+self:GetForward()*-40+self:GetUp()*30+self:GetRight()*-90);
            elseif(v.HALOV_FalconSideRSeat) then
			    local self = v:GetParent();
				p:SetPos(self:GetPos()+self:GetForward()*-40+self:GetUp()*30+self:GetRight()*90);
			end
			p:SetNetworkedEntity("HALOV_Falcon",NULL);
            p:SetNetworkedEntity("HALOV_FalconSeat",NULL);
		end
	end
end);

end

if CLIENT then
	
	ENT.CanFPV = true;
	ENT.Sounds={
		Engine=Sound("vehicles/falcon_fly.wav"),
	}
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	
	local View = {}
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNetworkedEntity("HALOV_Falcon", NULL)
		if(IsValid(self)) then
			local fpvPos = self:GetPos()+self:GetUp()*74+self:GetForward()*97;
			View = HALOVehicleView(self,635,185,fpvPos,true);		
			return View;
		end
	end
	hook.Add("CalcView", "HALOV_FalconView", CalcView)
	
	function ENT:Effects()
	

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetRight() * -1):GetNormalized();
		local FWD = self:GetRight();
		local id = self:EntIndex();
		for k,v in pairs(self.HFalconEnginePos) do

			local heatwv = self.Emitter:Add("sprites/heatwave",v+FWD*25);
			heatwv:SetVelocity(normal*2);
			heatwv:SetDieTime(0.01);
			heatwv:SetStartAlpha(255);
			heatwv:SetEndAlpha(255);
			heatwv:SetStartSize(15);
			heatwv:SetEndSize(1);
			heatwv:SetColor(255,255,255);
			heatwv:SetRoll(roll);
			
			local blue = self.FXEmitter:Add("sprites/orangecore1",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(75)
			blue:SetEndAlpha(10)
			blue:SetStartSize(10)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.HFalconEnginePos = {
				self:GetPos()+self:GetRight()*-63+self:GetUp()*114+self:GetForward()*-85,
				self:GetPos()+self:GetRight()*14+self:GetUp()*114+self:GetForward()*-85,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
	
	function HALOV_FalconReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_Falcon");
		local self = p:GetNWEntity("HALOV_Falcon");
		if(Flying and IsValid(self)) then
			HALO_HUD_DrawHull(3000);
			HALO_UNSCReticles(self);
			HALO_HUD_Compass(self,x,y); // Draw the compass/radar
			HALO_HUD_DrawSpeedometer();
		end
	end
	hook.Add("HUDPaint", "HALOV_FalconReticle", HALOV_FalconReticle)

end