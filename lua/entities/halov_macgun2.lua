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
 
ENT.Vehicle = "halov_macgun2";
ENT.EntModel = "models/helios/mac_base.mdl";
 
ENT.StartHealth = 6000;
 
list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.NextUse = {Use = CurTime(),Fire = CurTime()};
ENT.FireSound = Sound("weapons/macgun.wav");


AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_macgun2");
	e:SetPos(tr.HitPos + Vector(0,0,0));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()

	self.BaseClass.Initialize(self);
	local driverPos = self:GetPos()+self:GetUp()*0+self:GetForward()*0;
	local driverAng = self:GetAngles()+Angle(0,90,0);
	self:SpawnChairs(driverPos,driverAng,false);
	
	self.ForwardSpeed = 0;
	self.BoostSpeed = 0
	self.AccelSpeed = 0;
    self.HoverMod = -10;
    self.StartHover = -10;
    self.StandbyHoverAmount = -10; 
    self.SpeederClass = 2;
	self.CannonLocation = self:GetPos()+self:GetUp()*60+self:GetForward()*-10;
	
	self.NoWobble = true;
	self.StartHover = 1;
	
	self:SpawnTurretGuard();
	self:SpawnTurret();
	
	self.ExitModifier = {x=0,y=-250,z=5}
	
end

function ENT:SpawnTurret(ang)
	
	local e = ents.Create("prop_physics");
	e:SetPos(self:GetPos()+self:GetUp()*150+self:GetForward()*-22+self:GetRight()*5);
	e:SetAngles(self:GetAngles()+Angle(0,180,0));
	e:SetModel("models/helios/mac_cannon.mdl");
	e:SetParent(self.TurretGuard);
	e:Spawn();
	e:Activate();
	e:GetPhysicsObject():EnableCollisions(false);
	e:GetPhysicsObject():EnableMotion(false);
	self.Turret = e;
	self:SetNWEntity("Turret",e);
	
end

function ENT:SpawnTurretGuard(ang)
	
	local e = ents.Create("prop_physics");
	e:SetPos(self:GetPos()+self:GetUp()*35+self:GetForward()*0+self:GetRight()*2);
	e:SetAngles(self:GetAngles()+Angle(0,180,0));
	e:SetModel("models/helios/mac_carriage.mdl");
	e:SetParent(self);
	e:Spawn();
	e:Activate();
	e:GetPhysicsObject():EnableCollisions(false);
	e:GetPhysicsObject():EnableMotion(false);
	self.TurretGuard = e;

end

function ENT:FireBlast(pos,gravity,vel,ang)
    if(self.NextUse.FireBlast < CurTime()) then
        local e = ents.Create("mac_blast");
        e:SetPos(pos);
        e:Spawn();
        e:Activate();
        e:Prepare(self,Sound("weapons/macgun.wav"),gravity,vel,ang);
        e:SetColor(Color(255,255,255,1));
       
        self.NextUse.FireBlast = CurTime() + 5;
		self:EmitSound(self.FireSound, 120, math.random(120,250));
    end
end

local lastY = 0;
function ENT:Think()
	self.BaseClass.Think(self)
	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
		

			self.Turret.LastAng = self.Turret:GetAngles();
			self.TurretGuard.LastAng = self.TurretGuard:GetAngles();
		
			local aim = self.Pilot:GetAimVector():Angle();
            local p = aim.p*1;
            if(p <= -0 and p >= -40) then
                p = -0;
            elseif(p >= -300 and p <= 280) then
                p = 0;
            end
			self.Turret:SetAngles(Angle(p,aim.y+0,0));
			//self.DriverChair:SetAngles(self.TurretGuard:GetAngles())
			self.TurretGuard:SetAngles(Angle(self:GetAngles().p,self.Turret:GetAngles().y,self:GetAngles().r));
			if(self.Pilot:KeyDown(IN_ATTACK2)) then
				self:FireBlast(self.Turret:GetPos()+self.Turret:GetForward()*200,true,-3,self.Turret:GetAngles():Forward());
			elseif(self.Pilot:KeyDown(IN_ATTACK)) then
				self:FireBlast(self.Turret:GetPos()+self.Turret:GetForward()*200,false,-3,self.Turret:GetAngles():Forward());
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
	if(IsValid(self.TurretGuard)) then
		self.TurretGuard:SetAngles(self.TurretGuard.LastAng);
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
	ENT.HasCustomCalcView = true;
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
		local self = p:GetNWEntity("HALOV_Macgun2", NULL)
		local DriverSeat = p:GetNWEntity("DriverSeat",NULL);

		if(IsValid(self)) then

			if(IsValid(DriverSeat)) then
				local pos = self:GetPos()+LocalPlayer():GetAimVector():GetNormal()*-350+self:GetUp()*250+self:GetRight()*0;
				local face = ((self:GetPos() + Vector(0,0,200))- pos):Angle();
					View.origin = pos;
					View.angles = face;
				return View;
			end
		end
	end
	hook.Add("CalcView", "HALOV_Macgun2View", CalcView)
	
	function HALOV_Macgun2Reticle()
   
        local p = LocalPlayer();
        local Flying = p:GetNWBool("FlyingHALOV_Macgun2");
        local self = p:GetNWEntity("HALOV_Macgun2");
        if(Flying and IsValid(self)) then      
surface.SetDrawColor( color_white )	
			local TurretPos = Turret:GetPos()+Turret:GetForward()*-140;
			local tr = util.TraceLine({
				start = TurretPos,
				endpos = TurretPos + Turret:GetForward()*10000,
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
			surface.SetMaterial( Material( "hud/reticle_heavy.png", "noclamp" ) )
			surface.DrawTexturedRectUV( x , y, w, h, 0, 0, 1, 1 )
           
            HALO_Speeder_DrawHull(6000)
 
        end
    end
    hook.Add("HUDPaint", "HALOV_Macgun2Reticle", HALOV_Macgun2Reticle)
end