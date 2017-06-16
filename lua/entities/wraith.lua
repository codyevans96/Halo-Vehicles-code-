ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "T-26 Wraith"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.Vehicle = "wraith";
ENT.EntModel = "models/helios/wraith/wraith_open.mdl";
 
ENT.StartHealth = 2000;
 
list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then
 
ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/plasma_shoot.wav");
 
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("wraith");
    e:SetPos(tr.HitPos + Vector(0,0,10));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
    self.BaseClass.Initialize(self);
    local driverPos = self:GetPos()+self:GetUp()*75+self:GetForward()*-20+self:GetRight()*0;
    local driverAng = self:GetAngles()+Angle(0,-90,0);
    self:SpawnChairs(driverPos,driverAng,false)
   
    self.ForwardSpeed = 600;
    self.BoostSpeed = 600;
    self.AccelSpeed = 8;
    self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*105+self:GetUp()*50+self:GetRight()*-40,
		Right = self:GetPos()+self:GetForward()*105+self:GetUp()*50+self:GetRight()*40,
	}
    self:SpawnWeapons();
    self.HoverMod = 0.5;
    self.StartHover = 50;
    self.StandbyHoverAmount = 50; 
	self.HoverMod = 15;
    self.SpeederClass = 2;
	self.Bullet = HALOCreateBulletStructure(100,"plasma");
	self.FireDelay = 0.25;
	self.DontOverheat = true;
    self.CanBack = true;
	self.CanShoot = true;
	self.AlternateFire = true;
    self.CannonLocation = self:GetPos()+self:GetUp()*100+self:GetForward()*50;
    self:SpawnCannon(self:GetAngles()+Angle(0,0,0));
	self.WeaponDir = self:GetAngles():Forward()*-1;
	self:SpawnWeapons();
	self.FireGroup = {"Left","Right",};
 
    self.ExitModifier = {x=0,y=-400,z=5}
   
end
 
function ENT:FireBlast(pos,gravity,vel,ang)
    if(self.NextUse.FireBlast < CurTime()) then
        local e = ents.Create("wraith_blast");
        e:SetPos(pos);
        e:Spawn();
        e:Activate();
        e:Prepare(self,Sound("weapons/wraith_shoot.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 3;
    end
   
end
 
function ENT:Enter(p,driver)
    self.BaseClass.Enter(self,p,driver);
    self:Rotorwash(false);
end
 
hook.Add("PlayerEnteredVehicle","WraithSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsWraithSeat) then
            p:SetNetworkedEntity("Wraith",v:GetParent());
            p:SetNetworkedEntity("WraithSeat",v);
            p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "WraithSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsWraithSeat) then
            local e = v.Wraith;
            if(IsValid(e)) then
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("WraithSeat",NULL);
            p:SetNetworkedEntity("Wraith",NULL);
        end
    end
end);
 
function ENT:SpawnCannon(ang)
   
    local e = ents.Create("prop_physics");
    e:SetPos(self:GetPos()+self:GetUp()*130+self:GetForward()*-150+self:GetRight()*1.5);
    e:SetAngles(ang);
    e:SetModel("models/helios/wraith/wraith_gun.mdl");
    e:SetParent(self);
    e:Spawn();
    e:Activate();
    e:GetPhysicsObject():EnableCollisions(false);
    e:GetPhysicsObject():EnableMotion(false);
    self.Cannon = e;
    self:SetNWEntity("Cannon",e);
   
end
 
function ENT:Think()
 
    if(self.Inflight) then
       
        if(IsValid(self.Pilot)) then
       
            self.Cannon.LastAng = self.Cannon:GetAngles();
           
            local aim = self.Pilot:GetAimVector():Angle();
            local p = aim.p*1;
            if(p <= -0 and p >= -40) then
                p = -0;
            elseif(p >= -300 and p <= 280) then
                p = -300;
            end
            self.Cannon:SetAngles(Angle(p,self:GetAngles().y,self:GetAngles().r));
            if(self.Pilot:KeyDown(IN_ATTACK2)) then
                self:FireBlast(self.Cannon:GetPos()+self.Cannon:GetForward()*0+self:GetUp()*15,true,100,self.Cannon:GetAngles():Forward());
            end
        end
       
    end
    self.BaseClass.Think(self)
end
 
function ENT:Exit(driver,kill)
   
    self.BaseClass.Exit(self,driver,kill);
    if(IsValid(self.Cannon)) then
        self.Cannon:SetAngles(self.Cannon.LastAng);
    end
end
 
local ZAxis = Vector(0,0,1);
 
function ENT:PhysicsSimulate( phys, deltatime )
    self.BackPos = self:GetPos()+self:GetRight()*-200+self:GetUp()*0;
    self.FrontPos = self:GetPos()+self:GetRight()*300+self:GetUp()*0;
    self.MiddlePos = self:GetPos()+self:GetUp()*0;
    if(self.Inflight) then
        local UP = ZAxis;
        self.RightDir = self.Entity:GetRight();
        self.FWDDir = self.Entity:GetForward();  
       
 
       
        self:RunTraces();
 
        self.ExtraRoll = Angle(0,0,self.YawAccel / 2*-.1);
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
    local Speed = 0;
    local Target;
    local Cannon;
    function ENT:Think()
        self.BaseClass.Think(self);
        local p = LocalPlayer();
        local Flying = p:GetNWBool("Flying"..self.Vehicle);
        if(Flying) then
            Health = self:GetNWInt("Health");
            Speed = self:GetNWInt("Speed");
            Target = self:GetNWVector("Target");
            Cannon = self:GetNWEntity("Cannon");
        end
       
    end
   
    local View = {}
    local function CalcView()
       
        local p = LocalPlayer();
        local self = p:GetNWEntity("Wraith", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local WraithSeat = p:GetNWEntity("WraithSeat",NULL);
        local pass = p:GetNWEntity("WraithSeat",NULL);
        if(IsValid(self)) then
 
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+self:GetForward()*-500+self:GetUp()*200;
                    local face = self:GetAngles() + Angle(0,0,0);
                        View.origin = pos;
                        View.angles = face;
                    return View;
                end
            end
       
 
            if(IsValid(pass)) then
                if(WraithSeat:GetThirdPersonMode()) then
                        View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                    else
                    View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                end
            end
        end
    end
    hook.Add("CalcView", "WraithView", CalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "WraithDrawPlayerModel", function( p )
        local self = p:GetNWEntity("Wraith", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local WraithSeat = p:GetNWEntity("WraithSeat",NULL);
        local pass = p:GetNWEntity("WraithSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(WraithSeat:GetThirdPersonMode()) then
                    return false;
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
		for k,v in pairs(self.SmallWraithPos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(155)
			blue:SetEndAlpha(8)
			blue:SetStartSize(5)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
		for k,v in pairs(self.BigWraithPos) do
			
			local blue = self.FXEmitter:Add("sprites/bluecore",v+FWD*25)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.05)
			blue:SetStartAlpha(95)
			blue:SetEndAlpha(30)
			blue:SetStartSize(12)
			blue:SetEndSize(5)
			blue:SetRoll(roll)
			blue:SetColor(255,255,255)

		end
	end
	
	function ENT:Think()
	
		
		
		local p = LocalPlayer();
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(Flying) then
			self.SmallWraithPos = {
				self:GetPos()+self:GetRight()*-148.5+self:GetUp()*26+self:GetForward()*-12,
				self:GetPos()+self:GetRight()*99+self:GetUp()*26+self:GetForward()*-12,
				self:GetPos()+self:GetRight()*-158.5+self:GetUp()*16.5+self:GetForward()*-12,
				self:GetPos()+self:GetRight()*109+self:GetUp()*16.5+self:GetForward()*-12,
			}
			self.BigWraithPos = {
				self:GetPos()+self:GetRight()*-24.8+self:GetUp()*74+self:GetForward()*-195,
			}
			self:Effects();
		end
		self.BaseClass.Think(self)
	end
   
    function WraithReticle()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingWraith");
        local self = p:GetNWEntity("Wraith");
        if(Flying and IsValid(self)) then      
            local WeaponsPos = {self:GetPos()};
           
            HALO_Cannon_Reticles(self,WeaponsPos)
            HALO_Speeder_DrawHull(2000)
			HALO_Speeder_DrawSpeedometer()
 
        end
    end
    hook.Add("HUDPaint", "WraithReticle", WraithReticle)
   
   
end