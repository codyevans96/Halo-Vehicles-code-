ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "T-38 Tyrant"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.Vehicle = "tyrant";
ENT.EntModel = "models/helios/tyrant/tyrant.mdl";
 
ENT.StartHealth = 6000;
 
list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then
 
ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/banshee_shoot.wav");
 
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("tyrant");
    e:SetPos(tr.HitPos + Vector(0,0,10));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
    self.BaseClass.Initialize(self);
    local driverPos = self:GetPos()+self:GetUp()*705+self:GetForward()*-10+self:GetRight()*0;
    local driverAng = self:GetAngles()+Angle(0,-90,0);
    self:SpawnChairs(driverPos,driverAng,false)
   
    self.ForwardSpeed = 0;
    self.BoostSpeed = 0;
    self.AccelSpeed = 0;
    self.WeaponLocations = {
        Main = self:GetPos()+self:GetRight()*100+self:GetUp()*15,
    }
    self:SpawnWeapons();
    self.HoverMod = 0.5;
    self.StartHover = 1;
    self.StandbyHoverAmount = 1; 
    self.SpeederClass = 2;
    self.CanBack = true;
    self.CannonLocation = self:GetPos()+self:GetUp()*500+self:GetForward()*-300;
    self:SpawnCannon(self:GetAngles()+Angle(0,0,0));
 
    self.ExitModifier = {x=0,y=-400,z=5}
   
end
 
function ENT:FireBlast(pos,gravity,vel,ang)
    if(self.NextUse.FireBlast < CurTime()) then
        local e = ents.Create("tyrant_blast");
        e:SetPos(pos);
        e:Spawn();
        e:Activate();
        e:Prepare(self,Sound("weapons/hevplasma_shoot.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 8;
    end
   
end
 
function ENT:Enter(p,driver)
    self.BaseClass.Enter(self,p,driver);
    self:Rotorwash(false);
end
 
hook.Add("PlayerEnteredVehicle","TyrantSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsTyrantSeat) then
            p:SetNetworkedEntity("Tyrant",v:GetParent());
            p:SetNetworkedEntity("TyrantSeat",v);
            p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "TyrantSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsTyrantSeat) then
            local e = v.Tyrant;
            if(IsValid(e)) then
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("TyrantSeat",NULL);
            p:SetNetworkedEntity("Tyrant",NULL);
        end
    end
end);
 
function ENT:FireWeapons()
 
    if(self.NextUse.Fire < CurTime()) then
        local e = self.Cannon;
        local WeaponPos = {
            e:GetPos()+e:GetRight()*45+e:GetForward()*-110,
            e:GetPos()+e:GetRight()*-45+e:GetForward()*-110,
        }
        for k,v in pairs(WeaponPos) do
            local tr = util.TraceLine({
                start = self:GetPos(),
                endpos = self:GetPos() + self.Cannon:GetForward()*-10000,
                filter = {self,self.Cannon},
            })
            self.Bullet.Src     = v:GetPos();
            self.Bullet.Attacker = self.Pilot or self; 
            self.Bullet.Dir = self.Pilot:GetAimVector():Angle():Forward();
 
            v:FireBullets(self.Bullet)
        end
        self:EmitSound(self.FireSound, 120, math.random(90,110));
    end
end
 
function ENT:SpawnCannon(ang)
   
    local e = ents.Create("prop_physics");
    e:SetPos(self:GetPos()+self:GetUp()*460+self:GetForward()*0+self:GetRight()*0);
    e:SetAngles(ang);
    e:SetModel("models/helios/tyrant/tyrant_cannon.mdl");
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
            if(self.Pilot:KeyDown(IN_ATTACK)) then
                self:FireBlast(self.Cannon:GetPos()+self.Cannon:GetForward()*20+self:GetUp()*60,true,100,self.Cannon:GetAngles():Forward());
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
    self.BackPos = self:GetPos()+self:GetRight()*-200+self:GetUp()*5;
    self.FrontPos = self:GetPos()+self:GetRight()*200+self:GetUp()*5;
    self.MiddlePos = self:GetPos()+self:GetUp()*5;
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
        Engine=Sound(""),
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
        local self = p:GetNWEntity("Tyrant", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local TyrantSeat = p:GetNWEntity("TyrantSeat",NULL);
        local pass = p:GetNWEntity("TyrantSeat",NULL);
        if(IsValid(self)) then
 
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    local pos = self:GetPos()+self:GetForward()*-1000+self:GetUp()*900+self:GetRight()*500;
                    local face = self:GetAngles() + Angle(0,0,0);
                        View.origin = pos;
                        View.angles = face;
                    return View;
                end
            end
       
 
            if(IsValid(pass)) then
                if(TyrantSeat:GetThirdPersonMode()) then
                        View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                    else
                    View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                end
            end
        end
    end
    hook.Add("CalcView", "TyrantView", CalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "TyrantDrawPlayerModel", function( p )
        local self = p:GetNWEntity("Tyrant", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local TyrantSeat = p:GetNWEntity("TyrantSeat",NULL);
        local pass = p:GetNWEntity("TyrantSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(TyrantSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
        end
    end);
   
    function TyrantReticle()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingTyrant");
        local self = p:GetNWEntity("Tyrant");
        if(Flying and IsValid(self)) then      
            local WeaponsPos = {self:GetPos()};
           
            HALO_Cannon_Reticles(self,WeaponsPos)
            HALO_Speeder_DrawHull(6000)
 
        end
    end
    hook.Add("HUDPaint", "TyrantReticle", TyrantReticle)
   
   
end