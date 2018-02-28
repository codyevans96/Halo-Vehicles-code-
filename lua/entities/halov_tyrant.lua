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
 
ENT.Vehicle = "halov_tyrant";
ENT.EntModel = "models/helios/tyrant/tyrant.mdl";
 
ENT.StartHealth = 6000;
 
list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then
 
ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/macgun.wav");
 
 
AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
    local e = ents.Create("halov_tyrant");
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
        e:Prepare(self,Sound("weapons/macgun.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 5;
		self:EmitSound(self.FireSound, 120, math.random(120,250));
    end
   
end
 
function ENT:Enter(p,driver)
    self.BaseClass.Enter(self,p,driver);
    self:Rotorwash(false);
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
            if(p <= 70 and p >= 8) then
				p = 8;
			elseif(p >= -150 and p <= -30) then
				p = -30;
		    end
            self.Cannon:SetAngles(Angle(p,self:GetAngles().y,self:GetAngles().r));
            if(self.Pilot:KeyDown(IN_ATTACK)) then
                self:FireBlast(self.Cannon:GetPos()+self.Cannon:GetForward()*20+self:GetUp()*60,false,100,self.Cannon:GetAngles():Forward());
            elseif(self.Pilot:KeyDown(IN_ATTACK2)) then
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
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("HALOV_Tyrant", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-1300+self:GetUp()*950+self:GetRight()*0;
				local face = ((self:GetPos() + Vector(0,0,900))- pos):Angle();
					View.origin = pos;
					View.angles = face;
				return View;
			end
		end
	end
	hook.Add("CalcView", "HALOV_TyrantView", CalcView)
   
    function HALOV_TyrantReticle()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingHALOV_Tyrant");
        local self = p:GetNWEntity("HALOV_Tyrant");
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
    hook.Add("HUDPaint", "HALOV_TyrantReticle", HALOV_TyrantReticle)
   
   
end