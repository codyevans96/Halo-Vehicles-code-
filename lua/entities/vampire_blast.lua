
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Missle Blast"
ENT.Author = "Liam0102"
ENT.Category = "Halo"
ENT.Spawnable = false;
ENT.AdminSpawnable = false;

if SERVER then
	AddCSLuaFile()
	function ENT:Initialize()
	
		self:SetModel("models/props_junk/PopCan01a.mdl");
		self:SetSolid(SOLID_VPHYSICS);
		self:SetMoveType(MOVETYPE_VPHYSICS);
		self:PhysicsInit(SOLID_VPHYSICS);
		self:StartMotionController();
		self:SetUseType(SIMPLE_USE);
		self:SetRenderMode(RENDERMODE_TRANSALPHA);
		self:SetColor(Color(255,255,255,1));
		
		self:SetNWBool("White",self.IsWhite);
		self:SetNWInt("StartSize",self.StartSize or 20);
		self:SetNWInt("EndSize",self.EndSize or 15);
		
		self.Damage = self.Damage or 300;

	end
	
	function ENT:Prepare(e,s,gravity,vel,ang)
		e:EmitSound(s)
		local phys = self:GetPhysicsObject();
		phys:SetMass(100);
		phys:EnableGravity(gravity);
		if(!ang) then
			ang = e:GetForward();
		end
		phys:SetVelocity(ang*(2000*vel))
	end
	
	function ENT:PhysicsCollide(data, physobj)
	
		for i=1,math.Round(self.Damage/70) do
			local pos = self:GetPos()+self:GetForward()*math.random(-self.Damage/2,self.Damage/2)+self:GetRight()*math.random(-self.Damage/2,self.Damage/2)
			local fx = EffectData()
				fx:SetOrigin(pos);
			util.Effect("GunshipImpact",fx,true,true);
		end
		for k,v in pairs(ents.FindInSphere(self:GetPos(),self.Damage)) do
			local dist = (self:GetPos() - v:GetPos()):Length();
			local dmg = math.Clamp((self.Damage or 400) - dist,0,(self.Damage or 400));
			v:TakeDamage(dmg);
		end
		self:Remove()
	end
	
end

if CLIENT then

	function ENT:Initialize()	
		self.FXEmitter = ParticleEmitter(self:GetPos())
	end
	
	function ENT:Draw()
		
		self:DrawModel();
		
		local normal = (self:GetForward() * -1):GetNormalized()
		local roll = math.Rand(-90,90)
		
		local StartSize = self:GetNWInt("StartSize");
		local EndSize = self:GetNWInt("EndSize");
		
		local sprite;
		local IsWhite = self:GetNWBool("White");
		if(IsWhite) then
			sprite = "sprites/tfaenginered";
		else
			sprite = "sprites/tfaenginered";
		end

		local blue = self.FXEmitter:Add(sprite,self:GetPos())
		blue:SetVelocity(normal)
		blue:SetDieTime(0.7)
		blue:SetStartAlpha(250)
		blue:SetEndAlpha(100)
		blue:SetStartSize(30)
		blue:SetEndSize(5)
		blue:SetRoll(roll)
		blue:SetColor(110,110,255,1)
		
	end
end