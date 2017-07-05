ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Base = "halohover_base"
ENT.Type = "vehicle"
 
ENT.PrintName = "Mark 2488 MAC"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: UNSC"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminOnly = false;
 
ENT.Vehicle = "macgun";
ENT.EntModel = "models/helios/mac/mac.mdl";
 
ENT.StartHealth = 6000;
 
list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then
 
ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/banshee_shoot.wav");
 
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("macgun");
    e:SetPos(tr.HitPos + Vector(0,0,10));
    e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+0,0));
    e:Spawn();
    e:Activate();
    return e;
end
 
function ENT:Initialize()
    self.BaseClass.Initialize(self);
    local driverPos = self:GetPos()+self:GetUp()*198+self:GetForward()*10+self:GetRight()*-166.5;
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
    self.StartHover = 5;
    self.StandbyHoverAmount = 5; 
    self.SpeederClass = 2;
    self.CanBack = true;
    self.CannonLocation = self:GetPos()+self:GetUp()*500+self:GetForward()*-300;
    self:SpawnCannon(self:GetAngles()+Angle(0,0,0));
 
    self.ExitModifier = {x=0,y=-250,z=5}
   
end
 
function ENT:FireBlast(pos,gravity,vel,ang)
    if(self.NextUse.FireBlast < CurTime()) then
        local e = ents.Create("mac_blast");
        e:SetPos(pos);
        e:Spawn();
        e:Activate();
        e:Prepare(self,Sound("weapons/hevplasma_shoot.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 5;
    end
   
end
 
function ENT:Enter(p,driver)
    self.BaseClass.Enter(self,p,driver);
    self:Rotorwash(false);
end
 
hook.Add("PlayerEnteredVehicle","MacgunSeatEnter", function(p,v)
    if(IsValid(v) and IsValid(p)) then
        if(v.IsMacgunSeat) then
            p:SetNetworkedEntity("Macgun",v:GetParent());
            p:SetNetworkedEntity("MacgunSeat",v);
            p:SetAllowWeaponsInVehicle( false )
        end
    end
end);
 
hook.Add("PlayerLeaveVehicle", "MacgunSeatExit", function(p,v)
    if(IsValid(p) and IsValid(v)) then
        if(v.IsMacgunSeat) then
            local e = v.Macgun;
            if(IsValid(e)) then
                p:SetEyeAngles(e:GetAngles()+Angle(0,0,0))
            end
            p:SetNetworkedEntity("MacgunSeat",NULL);
            p:SetNetworkedEntity("Macgun",NULL);
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
    e:SetPos(self:GetPos()+self:GetUp()*240+self:GetForward()*60+self:GetRight()*0);
    e:SetAngles(ang);
    e:SetModel("models/helios/mac/mac_cannon.mdl");
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
                p = 3;
            end
            self.Cannon:SetAngles(Angle(p,self:GetAngles().y,self:GetAngles().r));
            if(self.Pilot:KeyDown(IN_ATTACK)) then
                self:FireBlast(self.Cannon:GetPos()+self.Cannon:GetForward()*50+self:GetUp()*0,true,100,self.Cannon:GetAngles():Forward());
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
        local self = p:GetNWEntity("Macgun", NULL)
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local MacgunSeat = p:GetNWEntity("MacgunSeat",NULL);
        local pass = p:GetNWEntity("MacgunSeat",NULL);
        if(IsValid(self)) then
 
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    --- local pos = self:GetPos()+self:GetForward()*-800+self:GetUp()*300;
					local pos = Cannon:GetPos()+Cannon:GetForward()*-400+Cannon:GetUp()*100;
                    local face = Cannon:GetAngles() + Angle(0,0,0);
                        View.origin = pos;
                        View.angles = face;
                    return View;
                end
            end
       
 
            if(IsValid(pass)) then
                if(MacgunSeat:GetThirdPersonMode()) then
                        View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                    else
                    View =  HALOVehicleView(self,1000,600,fpvPos);
                    return View;
                end
            end
        end
    end
    hook.Add("CalcView", "MacgunView", CalcView)
   
    hook.Add( "ShouldDrawLocalPlayer", "MacgunDrawPlayerModel", function( p )
        local self = p:GetNWEntity("Macgun", NULL);
        local DriverSeat = p:GetNWEntity("DriverSeat",NULL);
        local MacgunSeat = p:GetNWEntity("MacgunSeat",NULL);
        local pass = p:GetNWEntity("MacgunSeat",NULL);
        if(IsValid(self)) then
            if(IsValid(DriverSeat)) then
                if(DriverSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
            if(IsValid(pass)) then
                if(MacgunSeat:GetThirdPersonMode()) then
                    return false;
                end
            end
        end
    end);
   
    function MacgunReticle()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingMacgun");
        local self = p:GetNWEntity("Macgun");
        if(Flying and IsValid(self)) then      
surface.SetDrawColor( color_white )	
			local CannonPos = Cannon:GetPos()+Cannon:GetForward()*-140;
			local tr = util.TraceLine({
				start = CannonPos,
				endpos = CannonPos + Cannon:GetForward()*10000,
				filter = {self,Cannon},
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
			surface.SetMaterial( Material( "hud/reticle_heavy.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
           
            HALO_Speeder_DrawHull(6000)
 
        end
    end
    hook.Add("HUDPaint", "MacgunReticle", MacgunReticle)
   
   
end