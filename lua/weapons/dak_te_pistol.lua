AddCSLuaFile( "dak_ai_translations.lua" )
include( "dak_ai_translations.lua" )

if SERVER then
 
	--AddCSLuaFile ("shared.lua")
 

	SWEP.Weight = 5

	SWEP.AutoSwitchTo = false
	SWEP.AutoSwitchFrom = false
 
elseif CLIENT then
 
	SWEP.PrintName = "DTTE Pistol"
 
	SWEP.Slot = 4
	SWEP.SlotPos = 1

	SWEP.DrawAmmo = true
	SWEP.DrawCrosshair = true
end
 
SWEP.Author = "DakTank"
SWEP.Purpose = "Shoots Things."
SWEP.Instructions = "10mm average pen"

SWEP.Category = "DakTank"
 
SWEP.Spawnable = true
SWEP.AdminOnly = true
 
SWEP.ViewModel = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"

SWEP.Primary.ClipSize		= 10
SWEP.Primary.DefaultClip	= 100
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "Pistol"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
 
SWEP.PrimaryNumberofShots = 1
SWEP.PrimarySpread = 0.015
SWEP.PrimaryForce = 20
SWEP.PrimaryDamage = 20
SWEP.PrimaryCooldown = 0.1
SWEP.UseHands = true

SWEP.HoldType = "pistol"
SWEP.LastTime = CurTime()
SWEP.CSMuzzleFlashes = true

function SWEP:Initialize()
	self:SetHoldType( self.HoldType )
	if self.Owner:IsNPC() then
		if SERVER then
		self.Owner:SetCurrentWeaponProficiency( WEAPON_PROFICIENCY_PERFECT )
		self.Owner:CapabilitiesAdd( CAP_MOVE_GROUND )
		self.Owner:CapabilitiesAdd( CAP_MOVE_JUMP )
		self.Owner:CapabilitiesAdd( CAP_MOVE_CLIMB )
		self.Owner:CapabilitiesAdd( CAP_MOVE_SWIM )
		self.Owner:CapabilitiesAdd( CAP_MOVE_CRAWL )
		self.Owner:CapabilitiesAdd( CAP_MOVE_SHOOT )
		self.Owner:CapabilitiesAdd( CAP_USE )
		self.Owner:CapabilitiesAdd( CAP_USE_SHOT_REGULATOR )
		self.Owner:CapabilitiesAdd( CAP_SQUAD )
		self.Owner:CapabilitiesAdd( CAP_DUCK )
		self.Owner:CapabilitiesAdd( CAP_AIM_GUN )
		self.Owner:CapabilitiesAdd( CAP_NO_HIT_SQUADMATES )
		end
	end
	self.PrimaryLastFire = 0
	self.Fired = 0

	self.ShellList = {}
 	self.RemoveList = {}
end

function SWEP:Reload()
	if  ( self.Weapon:Clip1() < self.Primary.ClipSize && self.Owner:GetAmmoCount( self.Primary.Ammo ) > 0 ) then
		self.Weapon:DefaultReload(ACT_VM_RELOAD)	
	end
end
 
function SWEP:Think()
	if self.LastTime+0.1 < CurTime() then
		for i = 1, #self.ShellList do
			self.ShellList[i].LifeTime = self.ShellList[i].LifeTime + 0.1
			self.ShellList[i].Gravity = physenv.GetGravity()*self.ShellList[i].LifeTime
			local trace = {}
				trace.start = self.ShellList[i].Pos + (self.ShellList[i].DakVelocity * self.ShellList[i].Ang:Forward() * (self.ShellList[i].LifeTime-0.1)) - (-physenv.GetGravity()*((self.ShellList[i].LifeTime-0.1)^2)/2)
				trace.endpos = self.ShellList[i].Pos + (self.ShellList[i].DakVelocity * self.ShellList[i].Ang:Forward() * self.ShellList[i].LifeTime) - (-physenv.GetGravity()*(self.ShellList[i].LifeTime^2)/2)
				trace.filter = self.ShellList[i].Filter
				trace.mins = Vector(-1,-1,-1)
				trace.maxs = Vector(1,1,1)
			local ShellTrace = util.TraceHull( trace )
			local effectdata = EffectData()
			effectdata:SetStart(ShellTrace.StartPos)
			effectdata:SetOrigin(ShellTrace.HitPos)
			effectdata:SetScale((self.ShellList[i].DakCaliber*0.0393701))
			util.Effect("dakballistictracer", effectdata, true, true)
			if ShellTrace.Hit then
				DTShellHit(ShellTrace.StartPos,ShellTrace.HitPos,ShellTrace.Entity,self.ShellList[i],ShellTrace.HitNormal)
			end
			if self.ShellList[i].DieTime then
				--self.RemoveList[#self.RemoveList+1] = i
				if self.ShellList[i].DieTime+1.5<CurTime()then
					self.RemoveList[#self.RemoveList+1] = i
				end
			end
			if self.ShellList[i].RemoveNow == 1 then
				self.RemoveList[#self.RemoveList+1] = i
			end
		end
		if #self.RemoveList > 0 then
			for i = 1, #self.RemoveList do
				table.remove( self.ShellList, self.RemoveList[i] )
			end
		end
		self.RemoveList = {}
		self.LastTime = CurTime()
	end
end

function SWEP:PrimaryAttack()
	if self.PrimaryLastFire+self.PrimaryCooldown<CurTime() then
		if self.Weapon:Clip1() > 0 then
			if SERVER then
				local shootOrigin = self.Owner:EyePos()
				local shootDir = self.Owner:GetAimVector()
				local shell = {}
 				shell.Pos = self.Owner:EyePos()
 				shell.Ang = shootDir:Angle() + Angle(math.Rand(-0.25,0.25),math.Rand(-0.25,0.25),math.Rand(-0.25,0.25))
				shell.DakTrail = "dakshelltrail"
				shell.DakVelocity = 25000
				shell.DakDamage = 0.04
				shell.DakMass = 1
				shell.DakIsPellet = false
				shell.DakSplashDamage = 0
				shell.DakPenetration = 10
				shell.DakExplosive = false
				shell.DakBlastRadius = 0
				shell.DakPenSounds = {"daktanks/daksmallpen1.wav","daktanks/daksmallpen2.wav","daktanks/daksmallpen3.wav","daktanks/daksmallpen4.wav"}
				shell.DakBasePenetration = 10
				shell.DakCaliber = 5
				shell.DakFireSound = ""
				shell.DakFirePitch = 100
				shell.DakGun = self.Owner
				shell.DakGun.DakOwner = self.Owner
				shell.Filter = {self.Owner}
				shell.LifeTime = 0
				shell.Gravity = 0
				shell.DakPenLossPerMeter = 0.0005
				if self.DakName == "Flamethrower" then
					shell.DakIsFlame = 1
				end
				self.ShellList[#self.ShellList+1] = shell
			end
			self:EmitSound( "weapons/glock/glock18-1.wav", 140, 100, 1, 2)
			self.PrimaryLastFire = CurTime()
			self:TakePrimaryAmmo(1)
			self.Fired = 1
		else
			self:Reload()
		end
	end
	if self.Fired == 1 then
		self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
		self.Fired = 0
	end
end

function SWEP:SecondaryAttack()
	if self.Owner:GetFOV()==40 then
		self.Owner:SetFOV( 0, 0.1 )
	else
		self.Owner:SetFOV( 40, 0.1 )
	end
end
 
function SWEP:AdjustMouseSensitivity()
	if math.Round(self.Owner:GetFOV(),0)==40 then
		return 0.40
	else
		return 1
	end
end

function SWEP:GetCapabilities()
	return bit.bor( CAP_WEAPON_RANGE_ATTACK1, CAP_INNATE_RANGE_ATTACK1 )
end


