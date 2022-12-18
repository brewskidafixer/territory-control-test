void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.addCommandID("consume");
	this.Tag("hopperable");
	if (this.getName() != "goobypill")
	{
		this.Tag("syringe");
		this.Tag("forcefeed_always");
	}
	this.set_string("forcefeed_text", "Inject "+this.getInventoryName()+"!");
	this.Tag("dartguninjectable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("consume"), this.get_string("forcefeed_text"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume"))
	{
		int rnd = XORRandom(2);
		if (this.getName() != "goobypill")this.getSprite().PlaySound("Syringe_Injection_"+rnd+".ogg", 2.00f, 1.00f);
		else this.getSprite().PlaySound("Eat.ogg", 2.00f, 1.00f);

		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (!caller.hasScript("Gooby_Effect.as"))
			{
				caller.AddScript("Gooby_Effect.as");
				caller.set_f32("gooby_effect", 1.00f);
			}
			else
			{
				caller.add_f32("gooby_effect", -1.00f);
			}
			
			if (isServer())
			{
				this.server_Die();
			}
		}
	}
}