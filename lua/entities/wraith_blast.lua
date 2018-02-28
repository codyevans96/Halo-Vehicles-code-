
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Wraith Mortar Blast"
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
		self:SetColor(Color(218,210,214,1));
		
		self:SetNWBool("White",self.IsWhite);
		self:SetNWInt("StartSize",self.StartSize or 40);
		self:SetNWInt("EndSize",self.EndSize or 10);
		
		self.Damage = self.Damage or 500;

	end
	
	function ENT:Prepare(e,s,gravity,vel,ang)
		e:EmitSound(s)
		local phys = self:GetPhysicsObject();
		phys:SetMass(100);
		phys:EnableGravity(gravity);
		if(!ang) then
			ang = e:GetForward();
		end
		phys:SetVelocity(ang*(25*vel))
	end
	
	function ENT:PhysicsCollide(data, physobj)
	
		for i=1,math.Round(self.Damage/100) do
			local pos = self:GetPos()+self:GetForward()*math.random(-self.Damage/2,self.Damage/2)+self:GetRight()*math.random(-self.Damage/2,self.Damage/2)
			local fx = EffectData()
				fx:SetOrigin(pos);
			util.Effect("Explosion",fx,true,true);
		end
		for k,v in pairs(ents.FindInSphere(self:GetPos(),self.Damage)) do
			local dist = (self:GetPos() - v:GetPos()):Length();
			local dmg = math.Clamp((self.Damage or 600) - dist,0,(self.Damage or 600));
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
		blue:SetStartAlpha(75)
		blue:SetEndAlpha(1)
		blue:SetStartSize(150)
		blue:SetEndSize(50)
		blue:SetRoll(roll)
		blue:SetColor(60,90,255,1)
		
	end
end