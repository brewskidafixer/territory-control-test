//Rock logic

#include "Hitters.as";;

// defines amount of damage as well as maximum separate hits
// - in terms of this's health. see config
const f32 ROCK_DAMAGE = 0.125f;

u32 g_lastplayedsound = 0;

//sprite functions
void onInit(CSprite@ this)
{
	//set a random frame
	Animation@ anim = this.addAnimation("Rock", 0, false);
	anim.AddFrame(this.getBlob().getNetworkID() % 4);
	this.SetAnimation(anim);
}

//blob functions
Random _r(0xca7a);

void onInit(CBlob@ this)
{
	if (isServer())
	{
		this.server_SetTimeToDie(4 + _r.NextRanged(2));
	}

	this.getShape().getConsts().mapCollisions = false;
	this.getShape().getConsts().bullet = false;
	this.getShape().getConsts().net_threshold_multiplier = 4.0f;

}

void onTick(CBlob@ this)
{
	const f32 vellen = this.getShape().vellen;

	// chew through backwalls

	const bool is_server = isServer();
	const bool is_client = isClient();

	if (vellen > 0.5f)
	{
		Vec2f pos = this.getPosition();

		if (is_client && (getGameTime() + this.getNetworkID() * 31) % 19 == 0)
		{
			MakeDustParticle(pos, "Smoke.png");
		}

		CMap@ map = this.getMap();
		Tile tile = map.getTile(pos);

		if (map.isTileBackgroundNonEmpty(tile))
		{
			if (isServer())
			{
				if (map.getSectorAtPosition(pos, "no build") !is null)
				{
					map.server_DestroyTile(pos, 1.0f, this);
				}
			}
		}
		else if (map.isTileSolid(tile))
		{
			if (!is_server)
				this.getShape().SetStatic(true);
		}

		if (is_server)
		{
			Pierce(this);
		}
	}
	else
	{
		if (is_server) this.server_Die();
	}
}

void MakeDustParticle(Vec2f pos, string file)
{
	if(!isClient()){return;}
	CParticle@ temp = ParticleAnimated(file, pos, Vec2f(0, 0), 0.0f, 1.0f, 3, 0.0f, false);

	if (temp !is null)
	{
		temp.rotation = Vec2f(-1, 0);
		temp.rotation.RotateBy(_r.NextFloat() * 360.0f);
		temp.rotates = true;

		temp.width = 8;
		temp.height = 8;
	}
}

bool canHitBlob(CBlob@ this, CBlob@ blob)
{
	CBlob@ carrier = blob.getCarriedBlob();

	if (carrier !is null)
		if ((this.getTeamNum() == carrier.getTeamNum() || blob.hasTag("temp blob")))
			return false;

	return (this.getTeamNum() != blob.getTeamNum() || blob.getShape().isStatic())
	       && !blob.hasTag("invincible");

}

void HitMap(CBlob@ this, CMap@ map, Vec2f tilepos, bool ricochet)
{
	TileType t = map.getTile(tilepos).type;

	if (map.isTileCastle(t) || map.isTileWood(t))
	{
		if (map.getSectorAtPosition(tilepos, "no build") is null)
		{
			map.server_DestroyTile(tilepos, ricochet ? 1.0f : 10.0f, this);
		}
	}
}

void onDie(CBlob@ this)
{
	this.getSprite().Gib();

	u32 gametime = getGameTime();
	if (isClient() && (gametime) > g_lastplayedsound + 3)
	{
		g_lastplayedsound = gametime;
		Sound::Play("/rock_hit", this.getPosition(), Maths::Min(Maths::Max(0.5f, this.getOldVelocity().Length()), 1.5f));
	}
}

void Pierce(CBlob @this)
{
	CMap@ map = this.getMap();

	Vec2f initVelocity = this.getVelocity();

	Vec2f velDir = initVelocity;
	f32 vellen = velDir.Normalize();

	if (vellen < 0.1f)
	{
		this.server_Die();
		return;
	}

	f32 angle = velDir.Angle();

	Vec2f pos = this.getPosition();
	Vec2f oldpos = this.getShape().getVars().oldpos;

	Vec2f displacement = pos - oldpos;
	f32 displen = displacement.Length();

	HitInfo@[] hitInfos;

	u32 gametime = getGameTime();

	bool hit = false;
	bool ricochet = (gametime + this.getNetworkID() * 17) % 3 == 0;

	if (map.getHitInfosFromArc(oldpos, -angle, 0, displen, this, true, @hitInfos))
	{
		for (uint i = 0; i < hitInfos.length; i++)
		{
			HitInfo@ hi = hitInfos[i];
			CBlob@ b = hi.blob;
			if (b !is null) // blob
			{
				if (canHitBlob(this, b))
				{
					hit = true;
					this.server_Hit(b, hi.hitpos, initVelocity, ROCK_DAMAGE, Hitters::muscles, true);
				}
			}
			else //map
			{
				hit = true;

				Vec2f tilepos = hi.hitpos + velDir;
				HitMap(this, map, tilepos, true);
				ricochet = true;

				this.setPosition(hi.hitpos - velDir * 0.4f);
			}

			if (hit)
			{
				break;
			}
		}
	}

	if (!hit)
	{
		TileType t = map.getTile(pos).type;
		if (map.isTileSolid(t))
		{
			hit = true;
			HitMap(this, map, pos, false);
		}
	}

	if (hit)
	{
		if (isServer())
		{
			uint seed = (getGameTime() * (this.getNetworkID() * 997 + 1337));
			Random@ r = Random(seed);

			if (ricochet)
			{
				this.server_Hit(this, pos, initVelocity, ROCK_DAMAGE, Hitters::cata_stones, true);
				this.setVelocity(Vec2f(r.NextFloat() - 0.5f, r.NextFloat() - 0.5f) * vellen * 1.5f + initVelocity * 0.25f);
			}
			else
			{
				this.server_Die();
			}
		}
	}
}
