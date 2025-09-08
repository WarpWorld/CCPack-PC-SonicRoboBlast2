// Simplified Fang
freeslot("MT_SIMPLE_FANG", "MT_SFANG_HELPER", "S_SFANG_HELPER")
freeslot("S_SFANG_IDLE0", "S_SFANG_IDLE1", "S_SFANG_IDLE2", "S_SFANG_IDLE3",
		"S_SFANG_IDLE4", "S_SFANG_IDLE5", "S_SFANG_IDLE6", "S_SFANG_IDLE7",
		"S_SFANG_IDLE8", "S_SFANG_PAIN1", "S_SFANG_PAIN2", 
		"S_SFANG_PATHINGSTART1", "S_SFANG_PATHINGSTART2", "S_SFANG_PATHING",
		"S_SFANG_BOUNCE1", "S_SFANG_BOUNCE2", "S_SFANG_BOUNCE3", 
		"S_SFANG_BOUNCE4", "S_SFANG_FALL1", "S_SFANG_FALL2", 
		"S_SFANG_CHECKPATH1", "S_SFANG_CHECKPATH2", "S_SFANG_PATHINGCONT1",
		"S_SFANG_PATHINGCONT2", "S_SFANG_PATHINGCONT3", "S_SFANG_SKID1",
		"S_SFANG_SKID2", "S_SFANG_SKID3", "S_SFANG_CHOOSEATTACK",
		"S_SFANG_FIRESTART1", "S_SFANG_FIRESTART2", "S_SFANG_FIRE1",
		"S_SFANG_FIRE2", "S_SFANG_FIRE3", "S_SFANG_FIRE4", "S_SFANG_FIREREPEAT",
		"S_SFANG_LOBSHOT1", "S_SFANG_LOBSHOT2", "S_SFANG_LOBSHOT3",
		"S_SFANG_WAIT1", "S_SFANG_WAIT2", "S_SFANG_WALLHIT", "S_SFANG_DIE1", 
		"S_SFANG_DIE2", "S_SFANG_DIE3", "S_SFANG_DIE4", "S_SFANG_DIE5", 
		"S_SFANG_DIE6", "S_SFANG_DIE7", "S_SFANG_DIE8")

local state_dict = {
	[S_SFANG_IDLE0] = "S_SFANG_IDLE0",
	[S_SFANG_IDLE1] = "S_SFANG_IDLE1",
	[S_SFANG_IDLE2] = "S_SFANG_IDLE2",
	[S_SFANG_IDLE3] = "S_SFANG_IDLE3",
	[S_SFANG_IDLE4] = "S_SFANG_IDLE4",
	[S_SFANG_IDLE5] = "S_SFANG_IDLE5",
	[S_SFANG_IDLE6] = "S_SFANG_IDLE6",
	[S_SFANG_IDLE7] = "S_SFANG_IDLE7",
	[S_SFANG_IDLE8] = "S_SFANG_IDLE8",
	[S_SFANG_PAIN1] = "S_SFANG_PAIN1",
	[S_SFANG_PAIN2] = "S_SFANG_PAIN2",
	[S_SFANG_PATHINGSTART1] = "S_SFANG_PATHINGSTART1",
	[S_SFANG_PATHINGSTART2] = "S_SFANG_PATHINGSTART2",
	[S_SFANG_PATHING] = "S_SFANG_PATHING",
	[S_SFANG_BOUNCE1] = "S_SFANG_BOUNCE1",
	[S_SFANG_BOUNCE2] = "S_SFANG_BOUNCE2",
	[S_SFANG_BOUNCE3] = "S_SFANG_BOUNCE3",
	[S_SFANG_BOUNCE4] = "S_SFANG_BOUNCE4",
	[S_SFANG_FALL1] = "S_SFANG_FALL1",
	[S_SFANG_FALL2] = "S_SFANG_FALL2",
	[S_SFANG_CHECKPATH1] = "S_SFANG_CHECKPATH1",
	[S_SFANG_CHECKPATH2] = "S_SFANG_CHECKPATH2",
	[S_SFANG_PATHINGCONT1] = "S_SFANG_PATHINGCONT1",
	[S_SFANG_PATHINGCONT2] = "S_SFANG_PATHINGCONT2",
	[S_SFANG_PATHINGCONT3] = "S_SFANG_PATHINGCONT3",
	[S_SFANG_SKID1] = "S_SFANG_SKID1",
	[S_SFANG_SKID2] = "S_SFANG_SKID2",
	[S_SFANG_SKID3] = "S_SFANG_SKID3",
	[S_SFANG_FIRESTART1] = "S_SFANG_FIRESTART1",
	[S_SFANG_FIRESTART2] = "S_SFANG_FIRESTART2",
	[S_SFANG_FIRE1] = "S_SFANG_FIRE1",
	[S_SFANG_FIRE2] = "S_SFANG_FIRE2",
	[S_SFANG_FIRE3] = "S_SFANG_FIRE3",
	[S_SFANG_FIRE4] = "S_SFANG_FIRE4",
	[S_SFANG_FIREREPEAT] = "S_SFANG_FIREREPEAT",
	[S_SFANG_LOBSHOT1] = "S_SFANG_LOBSHOT1",
	[S_SFANG_LOBSHOT2] = "S_SFANG_LOBSHOT2",
	[S_SFANG_LOBSHOT3] = "S_SFANG_LOBSHOT3",
	[S_SFANG_WAIT1] = "S_SFANG_WAIT1",
	[S_SFANG_WAIT2] = "S_SFANG_WAIT2",
	[S_SFANG_WALLHIT] = "S_SFANG_WALLHIT",
	[S_SFANG_DIE1] = "S_SFANG_DIE1",
	[S_SFANG_DIE2] = "S_SFANG_DIE2",
	[S_SFANG_DIE3] = "S_SFANG_DIE3",
	[S_SFANG_DIE4] = "S_SFANG_DIE4",
	[S_SFANG_DIE5] = "S_SFANG_DIE5",
	[S_SFANG_DIE6] = "S_SFANG_DIE6",
	[S_SFANG_DIE7] = "S_SFANG_DIE7",
	[S_SFANG_DIE8] = "S_SFANG_DIE8",
}

local testmobj = nil

function A_CheckGround(actor, var1, var2)
	if (P_IsObjectOnGround(actor)) then
		actor.state = var1
	end
	if (actor.tracer and P_AproxDistance(actor.tracer.x - actor.x, actor.tracer.y - actor.y) < 2*actor.radius) then
		actor.momx = (4*actor.momx)/5
		actor.momy = (4*actor.momy)/5
	end
end

function A_CheckFalling(actor, var1, var2)
	if (P_MobjFlip(actor)*actor.momz <= 0)
		actor.state = var1
	end
end

function A_SFangExtraRepeat(actor, var1, var2)
	actor.extravalue2 = P_RandomKey(5) + 1
end

function A_SFangFindPoint(actor, var1, var2)
	local can_see = false
	for i=1,10 do
		local x = actor.x + (P_SignedRandom() * FRACUNIT * 32)
		local y = actor.y + (P_SignedRandom() * FRACUNIT * 32)
		local z = P_FloorzAtPos(x, y, actor.z, actor.height)
		if actor.eflags & MFE_VERTICALFLIP then
			z = P_CeilingzAtPos(x, y, actor.z, actor.height)
		end
		local mobj = P_SpawnMobj(x, y, z + actor.height, MT_SFANG_HELPER)
		if actor == testmobj then
			print(P_CheckSight(actor, mobj))
		end
		if P_CheckSight(actor, mobj) then
			can_see = true
			break
		end
	end
	if (can_see) then
		actor.tracer = mobj
	else
		actor.tracer = actor.target
	end
	A_FaceTracer(actor)
end

function A_SFangCalm(actor, var1, var2)
	actor.flags = $ | MF_SHOOTABLE
	actor.flags2 = $ & ~MF2_FRET
	if actor.tracer != nil and actor.tracer != actor.target then
		P_RemoveMobj(actor.tracer)
	end
end

mobjinfo[MT_SIMPLE_FANG] = {
	--$Name "Simple Fang"
	--$Sprite FANG
	--$Category "Enemies"
	--$Arrow
	doomednum = -1,
	spawnstate = S_SFANG_IDLE0,
	spawnhealth = 2,
	seestate = S_SFANG_PATHINGSTART1,
	reactiontime = 0,
	attacksound = sfx_skid,
	painstate = S_SFANG_PAIN1,
	painchance = 0,
	painsound = sfx_s3k5d,
	meleestate = S_NULL,
	missilestate = S_NULL,
	deathstate = S_SFANG_DIE1,
	xdeathstate = S_NULL,--S_SFANG_KO,
	deathsound = sfx_s3k90,
	speed = 0,
	radius = 24*FRACUNIT,
	height = 60*FRACUNIT,
	dispoffset = 0,
	mass = 0,
	damage = 3,
	activesound = sfx_boingf,
	flags = MF_RUNSPAWNFUNC|MF_SPECIAL|MF_ENEMY|MF_SHOOTABLE|MF_GRENADEBOUNCE|MF_NOCLIPTHING,
	raisestate = S_NULL
}

mobjinfo[MT_SFANG_HELPER] = {
	--$Name "Simple Fang"
	--$Sprite FANG
	--$Category "Enemies"
	doomednum = -1,
	spawnstate = S_SFANG_HELPER,
	spawnhealth = 1,
	seestate = S_NULL,
	reactiontime = 0,
	attacksound = sfx_None,
	painstate = S_NULL,
	painchance = 0,
	painsound = sfx_None,
	meleestate = S_NULL,
	missilestate = S_NULL,
	deathstate = S_NULL,
	xdeathstate = S_NULL,
	deathsound = sfx_None,
	speed = 0,
	radius = 24*FRACUNIT,
	height = 24*FRACUNIT,
	dispoffset = 0,
	mass = 0,
	damage = 0,
	activesound = sfx_None,
	flags = MF_NOCLIPTHING,
	raisestate = S_NULL
}

states[S_SFANG_HELPER] = {
	sprite = SPR_NULL,
	frame = 0,
	tics = 0,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_HELPER
}

states[S_SFANG_IDLE0] = {
	sprite = SPR_FANG,
	frame = 0,
	tics = 2,
	action = A_SetObjectFlags,
	var1 = MF_NOCLIPTHING,
	var2 = 1,
	nextstate = S_SFANG_IDLE1
}

states[S_SFANG_IDLE1] = {
	sprite = SPR_FANG,
	frame = 2,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE2
}

states[S_SFANG_IDLE2] = {
	sprite = SPR_FANG,
	frame = 3,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE3
}

states[S_SFANG_IDLE3] = {
	sprite = SPR_FANG,
	frame = 3,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE4
}

states[S_SFANG_IDLE4] = {
	sprite = SPR_FANG,
	frame = 3,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE5
}

states[S_SFANG_IDLE5] = {
	sprite = SPR_FANG,
	frame = 2,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE6
}

states[S_SFANG_IDLE6] = {
	sprite = SPR_FANG,
	frame = 1,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE7
}

states[S_SFANG_IDLE7] = {
	sprite = SPR_FANG,
	frame = 2,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE8
}

states[S_SFANG_IDLE8] = {
	sprite = SPR_FANG,
	frame = 2,
	tics = 16,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE1
}

states[S_SFANG_PAIN1] = {
	sprite = SPR_FANG,
	frame = 14,
	tics = 0,
	action = A_DoNPCPain,
	var1 = FRACUNIT,
	var2 = 0,
	nextstate = S_SFANG_PAIN2
}

states[S_SFANG_PAIN2] = {
	sprite = SPR_FANG,
	frame = 14,
	tics = 1,
	action = A_CheckGround,
	var1 = S_SFANG_PATHINGSTART1,
	var2 = 0,
	nextstate = S_SFANG_PAIN2
}

states[S_SFANG_PATHINGSTART1] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 0,
	action = A_SFangExtraRepeat,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_PATHINGSTART2
}

states[S_SFANG_PATHINGSTART2] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 0,
	action = A_PlayActiveSound,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_PATHING
}

states[S_SFANG_PATHING] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 0,
	action = A_SFangFindPoint,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_BOUNCE1
}

states[S_SFANG_BOUNCE1] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 2,
	action = A_Thrust,
	var1 = 0,
	var2 = 1,
	nextstate = S_SFANG_BOUNCE2
}

states[S_SFANG_BOUNCE2] = {
	sprite = SPR_FANG,
	frame = 9,
	tics = 2,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_BOUNCE3
}

states[S_SFANG_BOUNCE3] = {
	sprite = SPR_FANG,
	frame = 10,
	tics = 1,
	action = A_Boss5Jump,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_BOUNCE4
}

states[S_SFANG_BOUNCE4] = {
	sprite = SPR_FANG,
	frame = 10,
	tics = 1,
	action = A_CheckFalling,
	var1 = S_SFANG_FALL1,
	var2 = 0,
	nextstate = S_SFANG_BOUNCE4
}

states[S_SFANG_FALL1] = {
	sprite = SPR_FANG,
	frame = 12,
	tics = 1,
	action = A_CheckGround,
	var1 = S_SFANG_CHECKPATH1,
	var2 = 0,
	nextstate = S_SFANG_FALL2
}

states[S_SFANG_FALL2] = {
	sprite = SPR_FANG,
	frame = 13,
	tics = 1,
	action = A_CheckGround,
	var1 = S_SFANG_CHECKPATH1,
	var2 = 0,
	nextstate = S_SFANG_FALL1
}

states[S_SFANG_CHECKPATH1] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 0,
	action = A_SFangCalm,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_CHECKPATH2
}

states[S_SFANG_CHECKPATH2] = {
	sprite = SPR_FANG,
	frame = 8,
	tics = 0,
	action = A_Repeat,
	var1 = 0,
	var2 = S_SFANG_PATHINGCONT1,
	nextstate = S_SFANG_SKID1
}

states[S_SFANG_PATHINGCONT1] = {
	sprite = SPR_FANG,
	frame = 9,
	tics = 0,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_PATHINGCONT2
}

states[S_SFANG_PATHINGCONT2] = {
	sprite = SPR_FANG,
	frame = 9,
	tics = 0,
	action = A_PlayActiveSound,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_PATHINGCONT3
}

states[S_SFANG_PATHINGCONT3] = {
	sprite = SPR_FANG,
	frame = 9,
	tics = 2,
	action = A_Thrust,
	var1 = 0,
	var2 = 1,
	nextstate = S_SFANG_PATHING
}

states[S_SFANG_SKID1] = {
	sprite = SPR_FANG,
	frame = 4,
	tics = 0,
	action = A_PlayAttackSound,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_SKID2
}

states[S_SFANG_SKID2] = {
	sprite = SPR_FANG,
	frame = 4,
	tics = 1,
	action = A_DoNPCSkid,
	var1 = S_SFANG_SKID3,
	var2 = 0,
	nextstate = S_SFANG_SKID2
}

states[S_SFANG_SKID3] = {
	sprite = SPR_FANG,
	frame = 4,
	tics = 10,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_CHOOSEATTACK
}

states[S_SFANG_CHOOSEATTACK] = {
	sprite = SPR_FANG,
	frame = 0,
	tics = 0,
	action = A_RandomState,
	var1 = S_SFANG_LOBSHOT1,
	var2 = S_SFANG_FIRESTART1,
	nextstate = S_NULL
}

states[S_SFANG_FIRESTART1] = {
	sprite = SPR_FANG,
	frame = 5,
	tics = 0,
	action = A_PrepareRepeat,
	var1 = 3,
	var2 = 0,
	nextstate = S_SFANG_FIRESTART2
}

states[S_SFANG_FIRESTART2] = {
	sprite = SPR_FANG,
	frame = 5,
	tics = 5,
	action = A_LookForBetter,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_FIRE1
}

states[S_SFANG_FIRE1] = {
	sprite = SPR_FANG,
	frame = 5,
	tics = 5,
	action = A_FireShot,
	var1 = MT_CORK,
	var2 = -16,
	nextstate = S_SFANG_FIRE2
}

states[S_SFANG_FIRE2] = {
	sprite = SPR_FANG,
	frame = 6,
	tics = 5,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_FIRE3
}

states[S_SFANG_FIRE3] = {
	sprite = SPR_FANG,
	frame = 7,
	tics = 5,
	action = nil,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_FIRE4
}

states[S_SFANG_FIRE4] = {
	sprite = SPR_FANG,
	frame = 5,
	tics = 5,
	action = nil,
	var1 = 2,
	var2 = 0,
	nextstate = S_SFANG_FIREREPEAT
}

states[S_SFANG_FIREREPEAT] = {
	sprite = SPR_FANG,
	frame = 5,
	tics = 0,
	action = A_Repeat,
	var1 = 3,
	var2 = S_SFANG_FIRE1,
	nextstate = S_SFANG_WAIT1
}

states[S_SFANG_LOBSHOT1] = {
	sprite = SPR_FANG,
	frame = 18,
	tics = 16,
	action = A_LookForBetter,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_LOBSHOT2
}

states[S_SFANG_LOBSHOT2] = {
	sprite = SPR_FANG,
	frame = 19,
	tics = 2,
	action = A_LookForBetter,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_LOBSHOT3
}

states[S_SFANG_LOBSHOT3] = {
	sprite = SPR_FANG,
	frame = 20,
	tics = 18,
	action = A_BrakLobShot,
	var1 = MT_FBOMB,
	var2 = 32 + (1<<16),
	nextstate = S_SFANG_WAIT1
}

states[S_SFANG_WAIT1] = {
	sprite = SPR_FANG,
	frame = 15|FF_ANIMATE,
	tics = 70,
	action = nil,
	var1 = 1,
	var2 = 5,
	nextstate = S_SFANG_WAIT2
}

states[S_SFANG_WAIT2] = {
	sprite = SPR_FANG,
	frame = 15|FF_ANIMATE,
	tics = 70,
	action = A_Look,
	var1 = 1,
	var2 = 0,
	nextstate = S_SFANG_IDLE1
}

states[S_SFANG_WALLHIT] = {
	sprite = SPR_FANG,
	frame = 12,
	tics = 1,
	action = A_CheckGround,
	var1 = S_SFANG_PATHINGSTART2,
	var2 = 0,
	nextstate = S_SFANG_WALLHIT
}

states[S_SFANG_DIE1] = {
	sprite = SPR_FANG,
	frame = 21,
	tics = 0,
	action = A_DoNPCPain,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_DIE2
}

states[S_SFANG_DIE2] = {
	sprite = SPR_FANG,
	frame = 21,
	tics = 1,
	action = A_CheckGround,
	var1 = S_SFANG_DIE3,
	var2 = 0,
	nextstate = S_SFANG_DIE2
}

states[S_SFANG_DIE3] = {
	sprite = SPR_FANG,
	frame = 22,
	tics = 0,
	action = A_Scream,
	var1 = 0,
	var2 = 0,
	nextstate = S_SFANG_DIE4
}

states[S_SFANG_DIE4] = {
	sprite = SPR_FANG,
	frame = 22,
	tics = -1,
	action = A_SetFuse,
	var1 = 70,
	var2 = 0,
	nextstate = S_SFANG_DIE5
}

states[S_SFANG_DIE5] = {
	sprite = SPR_FANG,
	frame = 11,
	tics = 0,
	action = A_PlaySound,
	var1 = sfx_jump,
	var2 = 0,
	nextstate = S_SFANG_DIE6
}

states[S_SFANG_DIE6] = {
	sprite = SPR_FANG,
	frame = 11,
	tics = 1,
	action = A_ZThrust,
	var1 = 6,
	var2 = (1<<FRACBITS)|1,
	nextstate = S_SFANG_DIE7
}

states[S_SFANG_DIE7] = {
	sprite = SPR_FANG,
	frame = 11,
	tics = 1,
	action = A_CheckFalling,
	var1 = S_SFANG_DIE8,
	var2 = 0,
	nextstate = S_SFANG_DIE7
}

states[S_SFANG_DIE8] = {
	sprite = SPR_FANG,
	frame = 12,
	tics = 1,
	action = A_CheckGround,
	var1 = S_NULL,
	var2 = 0,
	nextstate = S_SFANG_DIE8
}

local function SFangThinker(mobj)
	/*if testmobj == nil then
		testmobj = mobj
	end*/
	/*if mobj == testmobj then
	end*/
	if mobj.health == 0 then
		if mobj.fuse != 0 then
			if mobj.flags2 & MF2_SLIDEPUSH then
				local trans = 10-((10*mobj.fuse)/70)
				if trans > 9 then
					trans = 9
				elseif trans < 0
					trans = 0
				end
				mobj.frame = ($ | ~FF_TRANSMASK)|(trans<<FF_TRANSSHIFT)
				if not mobj.fuse & 1 then
					mobj.colorized = not $
					mobj.fram = $ ^^ FF_FULLBRIGHT
				end
			end
			return
		end
		if mobj.state == mobj.info.xdeathstate then
			mobj.momz = $ - 2*FRACUNIT/3
		elseif mobj.tracer and P_AproxDistance(mobj.tracer.x - mobj.x, mobj.tracer.y - mobj.y) < 2*mobj.radius then
			mobj.flags = $ & ~MF_NOCLIP
		end
	else
		if mobj.flags2 & MF2_FRET and (leveltime & 1) and mobj.state != S_SFANG_PAIN1 and mobj.state != S_SFANG_PAIN2 then
			mobj.flags2 = $ | MF2_DONTDRAW
		else
			mobj.flags2 = $ & ~MF2_DONTDRAW
		end
	end
	
	if mobj.state == S_SFANG_BOUNCE3 or mobj.state == S_SFANG_BOUNCE4 then
		if P_MobjFlip(mobj)*mobj.momz > 0 and abs(mobj.momx) < FRACUNIT/2 and abs(mobj.momy) < FRACUNIT/2 and not P_IsObjectOnGround(mobj) then
			local prevtarget = mobj.target
			mobj.target = nil
			A_DoNPCPain(mobj, 0, 0)
			mobj.target = pretarget
			mobj.state = S_SFANG_WALLHIT
			mobj.extravalue2 = $ + 1
		end
	end
end

addHook("MobjThinker", SFangThinker, MT_SIMPLE_FANG)

local function SFangTouch(special, toucher)
	local player = toucher.player
	if not player then
		return
	end
	if ((not player.powers[pw_flashing]) 
			and (not(player.charability == CA_TWINSPIN and player.panim == PA_ABILITY))
			and (not(player.charability2 == CA2_MELEE and player.panim == PA_ABILITY2))) then
		if ((special.state == S_SFANG_BOUNCE3 or special.state == S_SFANG_BOUNCE4) 
				and (P_MobjFlip(special)*((special.z - special.height/2) - (toucher.z + toucher.height/2))) > (toucher.height/2)) then
			P_DamageMobj(toucher, special, special, 1, 0)
			special.tracer.target = toucher
			A_SFangExtraRepeat(special)
			special.state = S_SFANG_PATHINGCONT2
			if (special.eflags & MFE_VERTICALFLIP) then
				special.z = toucher.z - special.height
			else
				special.z = toucher.z + special,height
			end
		end
	end
	return
end

addHook("TouchSpecial", SFangTouch, MT_SIMPLE_FANG)

local function SFangFuse(mobj)
	if mobj.flags2 & MF2_SLIDEPUSH then
		--A_BossDeath(mobj, 0, 0)
		return false
	end
	mobj.state = states[mobj.state].nextstate
	if mobj == nil or not mobj.valid then
		return false
	end
end

addHook("MobjFuse", SFangFuse, MT_SIMPLE_FANG)