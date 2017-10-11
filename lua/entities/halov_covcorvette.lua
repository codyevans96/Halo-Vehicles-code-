ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Base = "haloveh_base"
ENT.Type = "vehicle"

ENT.PrintName = "SDV-Class Corvette"
ENT.Author = "Cody Evans"
--- BASE AUTHOR: Liam0102 ---
ENT.Category = "Halo Vehicles: Covenant"
ENT.AutomaticFrameAdvance = true
ENT.Spawnable = false;
ENT.AdminSpawnable = false;
ENT.AdminOnly = true;

ENT.EntModel = "models/helios/capital/covenant_corvette.mdl"
ENT.Vehicle = "halov_covcorvette"
ENT.StartHealth = 20000;
ENT.IsCapitalShip = true;

list.Set("HaloVehicles", ENT.PrintName, ENT);

if SERVER then

ENT.FireSound = Sound("weapons/plasma_shoot.wav");
ENT.NextUse = {Wings = CurTime(),Use = CurTime(),Fire = CurTime(),SlipJump=CurTime(),Switch=CurTime(),};

AddCSLuaFile();
function ENT:SpawnFunction(pl, tr)
	local e = ents.Create("halov_covcorvette");
	e:SetPos(tr.HitPos + Vector(0,0,1300));
	e:SetAngles(Angle(0,pl:GetAimVector():Angle().Yaw+180,0));
	e:Spawn();
	e:Activate();
	return e;
end

function ENT:Initialize()


	self:SetNWInt("Health",self.StartHealth);
	
	self.WeaponLocations = {
		Left = self:GetPos()+self:GetForward()*100+self:GetUp()*70+self:GetRight()*-70,
		Right = self:GetPos()+self:GetForward()*100+self:GetUp()*70+self:GetRight()*70,
	}
	self.WeaponsTable = {};
	self.BoostSpeed = 350;
	self.ForwardSpeed = 350;
	self.UpSpeed = 300;
	self.AccelSpeed = 8;
	self.CanStandby = true;
	self.CanBack = true;
	self.CanRoll = false;
	self.CanStrafe = false;
	self.Cooldown = 2;
	self.HasWings = false;
	self.CanShoot = false;
	self.Bullet = HALOCreateBulletStructure(150,"plasma",true);
	self.FireDelay = 0.2;
	self.NextBlast = 1;
	self.WarpDestination = Vector(0,0,0);
	if(WireLib) then
		Wire_CreateInputs(self, { "Destination [VECTOR]", })
	else
		self.DistanceMode = true;
	end
	
	self.OGForward = 100;
	self.OGBoost = 200;
	self.OGUp = 100;

	self.ExitModifier = {x=1000,y=225,z=100};
	self.SeatPos = {
		{self:GetPos()+self:GetUp()*0+self:GetForward()*-1900+self:GetRight()*300, self:GetAngles()+Angle(0,180,0)},
		{self:GetPos()+self:GetUp()*0+self:GetForward()*-1900+self:GetRight()*-300, self:GetAngles()},
	}
	self.GunnerSeats = {};
	self:SpawnGunnerSeats();

	self.LeftWeaponLocations = {
		self:GetPos()+self:GetUp()*-175+self:GetForward()*-1850+self:GetRight()*600,
		
		self:GetPos()+self:GetUp()*-175+self:GetForward()*-1950+self:GetRight()*600,

		self:GetPos()+self:GetUp()*-175+self:GetForward()*-2050+self:GetRight()*600,	
	}
	
	self.RightWeaponLocations = {
		self:GetPos()+self:GetUp()*-175+self:GetForward()*-1850+self:GetRight()*-600,
		
		self:GetPos()+self:GetUp()*-175+self:GetForward()*-1950+self:GetRight()*-600,

		self:GetPos()+self:GetUp()*-175+self:GetForward()*-2050+self:GetRight()*-600,	
	}

	self.BaseClass.Initialize(self);
end

function ENT:Think()

    if(IsValid(self.LeftGunner)) then
		if(self.GunnerSeats[1]:GetThirdPersonMode()) then
			self.GunnerSeats[1]:SetThirdPersonMode(false);
		end
		if(self.LeftGunner:KeyDown(IN_ATTACK)) then
			self:FireLeft(self.LeftGunner:GetAimVector():Angle():Forward());
		end
	end
	
	if(IsValid(self.RightGunner)) then
		if(self.GunnerSeats[2]:GetThirdPersonMode()) then
			self.GunnerSeats[2]:SetThirdPersonMode(false);
		end
		if(self.RightGunner:KeyDown(IN_ATTACK)) then
			self:FireRight(self.RightGunner:GetAimVector():Angle():Forward());
		end
	end
	
	if(self.Inflight) then
		if(IsValid(self.Pilot)) then
				
			if(self.Pilot:KeyDown(IN_WALK) and self.NextUse.SlipJump < CurTime()) then
				if(!self.SlipJump and !self.HyperdriveDisabled) then
					self.SlipJump = true;
					self.SlipJumpTimer = CurTime() + 3;
					self.NextUse.SlipJump = CurTime() + 20;
					
				end
			end

			
			if(WireLib) then
				if(self.Pilot:KeyDown(IN_RELOAD) and self.NextUse.Switch < CurTime()) then
					if(!self.DistanceMode) then
						self.DistanceMode = true;
						self.Pilot:ChatPrint("Slipstream Mode: Distance");
					else
						self.DistanceMode = false;
						self.Pilot:ChatPrint("Slipstream Mode: Destination");
					end
					self.NextUse.Switch = CurTime() + 1;
				end
			end
			
		end
		if(self.SlipJump) then
			if(self.DistanceMode) then
				self:SlipTrigger(self:GetPos()+self:GetForward()*20000);
			else
				self:SlipTrigger(self.WarpDestination);
			end
		end
	end
	
	if(self.Inflight) then
        if(IsValid(self.Pilot)) then
            if(IsValid(self.Pilot)) then 
                if(self.Pilot:KeyDown(IN_ATTACK) and self.NextUse.FireBlast < CurTime()) then
                    self.BlastPositions = {
                        self:GetPos() + self:GetForward() * -440 + self:GetRight() * 835 + self:GetUp() * -200,
						self:GetPos() + self:GetForward() * -440 + self:GetRight() * -835 + self:GetUp() * -200,
						self:GetPos() + self:GetForward() * -440 + self:GetRight() * 935 + self:GetUp() * -200,
						self:GetPos() + self:GetForward() * -440 + self:GetRight() * -935 + self:GetUp() * -200,
						self:GetPos() + self:GetForward() * -440 + self:GetRight() * 1135 + self:GetUp() * -200,
						self:GetPos() + self:GetForward() * -440 + self:GetRight() * -1135 + self:GetUp() * -200,
                    }
                    self:FireHALOV_COVCorvetteBlast(self.BlastPositions[self.NextBlast], false, 1200, 1200, true, 8, Sound("weapons/wraith_shoot.wav"));
					self.NextBlast = self.NextBlast + 1;
					if(self.NextBlast == 7) then
						self.NextUse.FireBlast = CurTime()+10;
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

hook.Add("PlayerLeaveVehicle", "HALOV_COVCorvetteSeatExit", function(p,v)
	if(IsValid(p) and IsValid(v)) then
		if(v.IsRepGunnerSeat) then
			local e = v:GetParent();
			if(v.IsRight) then
				e:GunnerExit(true,p);
			else
				e:GunnerExit(false,p);
			end
		end
	end
end);

function ENT:FireLeft(angPos)

	if(self.NextUse.Fire < CurTime()) then
		for k,v in pairs(self.LeftWeapons) do

			self.Bullet.Attacker = self.Pilot or self;
			self.Bullet.Src		= v:GetPos();
			self.Bullet.Dir = angPos

			v:FireBullets(self.Bullet)
		end
		self:EmitSound(self.FireSound,100,math.random(80,120));
		self.NextUse.Fire = CurTime() + (self.FireDelay or 0.2);
	end
end

function ENT:FireRight(angPos)

	if(self.NextUse.Fire < CurTime()) then
		for k,v in pairs(self.RightWeapons) do

			self.Bullet.Attacker = self.Pilot or self;
			self.Bullet.Src		= v:GetPos();
			self.Bullet.Dir = angPos

			v:FireBullets(self.Bullet)
		end
		self:EmitSound(self.FireSound,100,math.random(80,120));
		self.NextUse.Fire = CurTime() + (self.FireDelay or 0.2);
	end
end

function ENT:SpawnWeapons()
	self.LeftWeapons = {};
	self.RightWeapons = {};
	for k,v in pairs(self.LeftWeaponLocations) do
		local e = ents.Create("prop_physics");
		e:SetModel("models/props_junk/PopCan01a.mdl");
		e:SetPos(v);
		e:Spawn();
		e:Activate();
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetSolid(SOLID_NONE);
		e:AddFlags(FL_DONTTOUCH);
		e:SetColor(Color(255,255,255,0));
		e:SetParent(self);
		e:GetPhysicsObject():EnableMotion(false);
		self.LeftWeapons[k] = e;
	end

	for k,v in pairs(self.RightWeaponLocations) do
		local e = ents.Create("prop_physics");
		e:SetModel("models/props_junk/PopCan01a.mdl");
		e:SetPos(v);
		e:Spawn();
		e:Activate();
		e:SetRenderMode(RENDERMODE_TRANSALPHA);
		e:SetSolid(SOLID_NONE);
		e:AddFlags(FL_DONTTOUCH);
		e:SetColor(Color(255,255,255,0));
		e:SetParent(self);
		e:GetPhysicsObject():EnableMotion(false);
		self.RightWeapons[k] = e;
	end
end

function ENT:SpawnGunnerSeats()
	
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
		e:SetThirdPersonMode(false);
		e:GetPhysicsObject():EnableMotion(false);
		e:GetPhysicsObject():EnableCollisions(false);
		e:SetUseType(USE_OFF);
		self.GunnerSeats[k] = e;
		if(k == 2) then
			e.IsRight = true;
		end
		e.IsRepGunnerSeat = true;
	end
end

function ENT:Use(p)

	if(p == self.Pilot or p == self.LeftGunner or p == self.RightGunner) then return end;

	if(!self.Inflight and !p:KeyDown(IN_WALK)) then
		if(p != self.LeftGunner and p != self.RightGunner) then
			self:Enter(p);
		end
	else
		if(!self.LeftGunner) then
			self:GunnerEnter(p,false);
		else
			self:GunnerEnter(p,true);
		end
	end

end

function ENT:GunnerEnter(p,right)
	if(p == self.Pilot) then return end;
	if(p == self.LeftGunner) then return end;
	if(p == self.RightGunner) then return end;
	if(self.NextUse.Use < CurTime()) then
		if(!right) then
			if(!IsValid(self.LeftGunner)) then
				p:SetNWBool("LeftGunner",true);
				self.LeftGunner = p;
				p:EnterVehicle(self.GunnerSeats[1]);
			end
		else
			if(!IsValid(self.RightGunner)) then
				p:SetNWBool("RightGunner",true);
				self.RightGunner = p;
				p:EnterVehicle(self.GunnerSeats[2]);
			end
		end
		p:SetNWEntity(self.Vehicle,self);
		self.NextUse.Use = CurTime() + 1;
	end
end

function ENT:GunnerExit(right,p)

	if(!right) then
		if(IsValid(self.LeftGunner)) then
			self.LeftGunner:SetNWBool("LeftGunner",false);
			self.LeftGunner = NULL;
		end
	else
		if(IsValid(self.RightGunner)) then
			self.RightGunner:SetNWBool("RightGunner",false);
			self.RightGunner = NULL;
		end
	end
	p:SetPos(self:GetPos()+self:GetRight()*1000);
	p:SetNWEntity(self.Vehicle,NULL);
end

function ENT:FireHALOV_COVCorvetteBlast(pos,gravity,vel,dmg,white,size,snd)
	local e = ents.Create("covcapital_blast");
	
	e.Damage = dmg or 600;
	e.IsWhite = white or false;
	e.StartSize = size or 80;
	e.EndSize = size*5 or 75;
	
	local sound = snd or Sound("weapons/wraith_shoot.wav");
	
	e:SetPos(pos);
	e:Spawn();
	e:Activate();
	e:Prepare(self,sound,gravity,vel);
	e:SetColor(Color(255,255,255,1));
	
end

function ENT:SlipTrigger(Dest)
	if(!self.PunchIt) then
		if(self.SlipJumpTimer > CurTime()) then
			self.ForwardSpeed = 0;
			self.BoostSpeed = 0;
			self.UpSpeed = 0;
			self.Accel.FWD = 0;
			self:SetNWInt("SlipJump",1);
			//util.ScreenShake(self:GetPos()+self:GetForward()*-730+self:GetUp()*195+self:GetRight()*3,5,5,10,5000)
		else
			self.Accel.FWD = 4000;
			self.SlipJumpWarp = CurTime()+0.5;
			self.PunchIt = true;
			self:SetNWInt("SlipJump",2);
		end
	
	else
		if(self.SlipJumpWarp < CurTime()) then
			
			self:ResetSlipJump();
			local fx = EffectData()
				fx:SetOrigin(self:GetPos())
				fx:SetEntity(self)
			util.Effect("propspawn",fx)
			self:EmitSound("ambient/levels/citadel/weapon_disintegrate2.wav", 500)
			self:SetPos(Dest);
			self.Accel.FWD = 500;
		end
	end
end

function ENT:ResetSlipJump()

	self.SlipJump = false;
	self.PunchIt = false;
	self.ForwardSpeed = self.OGForward;
	self.BoostSpeed = self.OGBoost;
	self.UpSpeed = self.OGUp;
	self.PlayedSound = false;
	self:SetNWInt("SlipJump",0);

			
end

function ENT:Exit()

	self.BaseClass.Exit(self);
	self:ResetSlipJump();
	self.SlipJumpTimer = CurTime();
	self.NextUse.SlipJump = CurTime();
end

function ENT:TriggerInput(k,v)
	if(k == "Destination") then
		self.WarpDestination = v;
	end
end

local FlightPhys = {
	secondstoarrive	= 1;
	maxangular		= 5000;
	maxangulardamp	= 10000;
	maxspeed			= 1000000;
	maxspeeddamp		= 500000;
	dampfactor		= 0.8;
	teleportdistance	= 5000;
};
local ZAxis = Vector(0,0,1);
function ENT:PhysicsSimulate(phys,delta)
	local FWD = self:GetForward()*-1;
	local UP = ZAxis;
	local RIGHT = FWD:Cross(UP):GetNormalized();
	if(self.Inflight) then
		phys:Wake();
		if(self.Pilot:KeyDown(IN_FORWARD) and (self.Wings or self.Pilot:KeyDown(IN_SPEED))) then
			self.num = self.BoostSpeed;
		elseif(self.Pilot:KeyDown(IN_FORWARD)) then
			self.num = self.ForwardSpeed;
		elseif(self.Pilot:KeyDown(IN_BACK) and self.CanBack) then
			self.num = (self.ForwardSpeed / 2)*-1;
		else
			self.num = 0;
		end

		self.Accel.FWD = math.Approach(self.Accel.FWD,self.num,self.Acceleration);
		
		if(self.Pilot:KeyDown(IN_MOVERIGHT)) then
			self.TurnYaw = Angle(0,-8,0);
		elseif(self.Pilot:KeyDown(IN_MOVELEFT)) then
			self.TurnYaw = Angle(0,8,0);
		else
			self.TurnYaw = Angle(0,0,0);
		end
		local ang = self:GetAngles() + self.TurnYaw;
		
		if(self.Pilot:KeyDown(IN_JUMP)) then
			self.num3 = self.UpSpeed;
		elseif(self.Pilot:KeyDown(IN_DUCK)) then
			self.num3 = -self.UpSpeed;
		else
			self.num3 = 0;
		end
		self.Accel.UP = math.Approach(self.Accel.UP,self.num3,self.Acceleration*0.9);
		
		--######### Do a tilt when turning, due to aerodynamic effects @aVoN
		local velocity = self:GetVelocity();
		local aim = self.Pilot:GetAimVector();
		//local ang = aim:Angle();
		
		
		local weight_roll = (phys:GetMass()/1000)/1.5
		local pos = self:GetPos()
		local ExtraRoll = math.Clamp(math.deg(math.asin(self:WorldToLocal(pos).y)),-25-weight_roll,25+weight_roll); -- Extra-roll - When you move into curves, make the shuttle do little curves too according to aerodynamic effects
		local mul = math.Clamp((velocity:Length()/1700),0,1); -- More roll, if faster.
		local oldRoll = ang.Roll;
		ang.Roll = (ang.Roll + self.Roll - ExtraRoll*mul) % 360;
		if (ang.Roll!=ang.Roll) then ang.Roll = oldRoll; end -- fix for nan values that cause despawing/crash.

	
		FlightPhys.angle = ang; --+ Vector(90 0, 0)
		FlightPhys.deltatime = deltatime;
		if(self.CanStrafe) then
			FlightPhys.pos = self:GetPos()+(FWD*self.Accel.FWD)+(UP*self.Accel.UP)+(RIGHT*self.Accel.RIGHT);
		else
			FlightPhys.pos = self:GetPos()+(FWD*self.Accel.FWD)+(UP*self.Accel.UP);
		end

		if(!self.CriticalDamage) then
			phys:ComputeShadowControl(FlightPhys);
		end
	else
		if(self.ShouldStandby and self.CanStandby) then
			FlightPhys.angle = self.StandbyAngles or Angle(0,self:GetAngles().y,0);
			FlightPhys.deltatime = deltatime;
			FlightPhys.pos = self:GetPos()+UP;
			phys:ComputeShadowControl(FlightPhys);		
		end
	end
		
end
end

if CLIENT then
	
	ENT.CanFPV = false;
	ENT.Sounds={
		Engine=Sound("vehicles/covenant_fly2.wav"),
	}
	
	function ENT:Initialize()
		self.Emitter = ParticleEmitter(self:GetPos());
		self.BaseClass.Initialize(self);
	end
	function ENT:Draw() self:DrawModel() end;
	local SlipJump = 0;
	function ENT:Think()
		self.BaseClass.Think(self);
		local p = LocalPlayer();
		local IsFlying = p:GetNWEntity(self.Vehicle);
		local Flying = self:GetNWBool("Flying".. self.Vehicle);
		if(IsFlying) then
			SlipJump = self:GetNWInt("SlipJump");
		end
		
		if(Flying) then
			self.HALOV_COVCorvettePos = {
				self:GetPos()+self:GetForward()*1670+self:GetUp()*-120+self:GetRight()*100,
				self:GetPos()+self:GetForward()*1670+self:GetUp()*-120+self:GetRight()*-100,
				
				self:GetPos()+self:GetForward()*1840+self:GetUp()*-20+self:GetRight()*280,
				self:GetPos()+self:GetForward()*1780+self:GetUp()*-20+self:GetRight()*340,
				self:GetPos()+self:GetForward()*1720+self:GetUp()*-20+self:GetRight()*400,
				
				self:GetPos()+self:GetForward()*1840+self:GetUp()*-20+self:GetRight()*-280,
				self:GetPos()+self:GetForward()*1780+self:GetUp()*-20+self:GetRight()*-340,
				self:GetPos()+self:GetForward()*1720+self:GetUp()*-20+self:GetRight()*-400,
				
			}
			self:Effects();
		end
	end	
	
	local View = {}
	local lastpos, lastang;
	function CalcView()
		
		local p = LocalPlayer();
		local self = p:GetNWEntity("HALOV_COVCorvette")
		local Flying = p:GetNWBool("FlyingHALOV_COVCorvette");
		local pos,face;
		if(IsValid(self) and Flying) then
			
			if(SlipJump == 2) then
				pos = lastpos;
				face = lastang;

				View.origin = pos;
				View.angles = face;
			else
				pos = self:GetPos()+self:GetUp()*350+LocalPlayer():GetAimVector():GetNormal()*5000;			
				face = ((self:GetPos() + Vector(0,0,100))- pos):Angle()
				View =  HALOVehicleView(self,-5000,250,fpvPos);
			end
			
			lastpos = pos;
			lastang = face;
			
			return View;
		end
	end
	hook.Add("CalcView", "HALOV_COVCorvetteView", CalcView)
	
	function ENT:Effects()

		local p = LocalPlayer();
		local roll = math.Rand(-45,45);
		local normal = (self.Entity:GetForward() * 1):GetNormalized();
		local id = self:EntIndex();
		for k,v in pairs(self.HALOV_COVCorvettePos) do
			
			local blue = self.Emitter:Add("sprites/bluecore",v)
			blue:SetVelocity(normal)
			blue:SetDieTime(0.8)
			blue:SetStartAlpha(35)
			blue:SetEndAlpha(5)
			blue:SetStartSize(90)
			blue:SetEndSize(1)
			blue:SetRoll(roll)
			blue:SetColor(218,90,214)

		end
	end
	
	function HALOV_COVCorvetteReticle()
		
		local p = LocalPlayer();
		local Flying = p:GetNWBool("FlyingHALOV_COVCorvette");
		local self = p:GetNWEntity("HALOV_COVCorvette");
		local LeftGunner = p:GetNWBool("LeftGunner");
		local RightGunner = p:GetNWBool("RightGunner");
		
		if(IsValid(self)) then
			if(SlipJump == 2) then
				DrawMotionBlur( 0.4, 20, 0.01 );
			end
		end
		
		if(Flying and IsValid(self)) then

			HALO_HUD_DrawHull(20000,x,y);			
		
		elseif(LeftGunner and IsValid(self)) then

			local WeaponsPos = {
				self:GetPos()+self:GetUp()*-175+self:GetForward()*-1850+self:GetRight()*600,
				
				self:GetPos()+self:GetUp()*-175+self:GetForward()*-1950+self:GetRight()*600,

				self:GetPos()+self:GetUp()*-175+self:GetForward()*-2050+self:GetRight()*600,	
			}
			
			for i=1,3 do
				local tr = util.TraceLine( {
					start = WeaponsPos[i],
					endpos = WeaponsPos[i] + p:GetAimVector():Angle():Forward()*10000,
				} )

				surface.SetTextColor( 255, 255, 255, 255 );
				
				local vpos = tr.HitPos;
				
				local screen = vpos:ToScreen();
				
				surface.SetFont( "CloseCaption_Bold" );	
				local tsW, tsH = surface.GetTextSize("+");
				
				local x,y;
				for k,v in pairs(screen) do
					if k=="x" then
						x = v - tsW/2;
					elseif k=="y" then
						y = v - tsH/2;
					end
				end
				
							
				surface.SetTextPos( x, y );
				surface.DrawText( "+" );
			end
		elseif(RightGunner and IsValid(self)) then
			local WeaponsPos = {
				self:GetPos()+self:GetUp()*-175+self:GetForward()*-1850+self:GetRight()*-600,
				
				self:GetPos()+self:GetUp()*-175+self:GetForward()*-1950+self:GetRight()*-600,

				self:GetPos()+self:GetUp()*-175+self:GetForward()*-2050+self:GetRight()*-600,			
			}
			
			for i=1,3 do
				local tr = util.TraceLine( {
					start = WeaponsPos[i],
					endpos = WeaponsPos[i] + p:GetAimVector():Angle():Forward()*10000,
				} )

				surface.SetTextColor( 255, 255, 255, 255 );
				
				local vpos = tr.HitPos;
				
				local screen = vpos:ToScreen();
				
				surface.SetFont( "CloseCaption_Bold" );	
				local tsW, tsH = surface.GetTextSize("+");
				
				local x,y;
				for k,v in pairs(screen) do
					if k=="x" then
						x = v - tsW/2;
					elseif k=="y" then
						y = v - tsH/2;
					end
				end
				
							
				surface.SetTextPos( x, y );
				surface.DrawText( "+" );
			end
		end
	end
	hook.Add("HUDPaint", "HALOV_COVCorvetteReticle", HALOV_COVCorvetteReticle)

end