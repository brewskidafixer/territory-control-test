void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);
	this.addCommandID("consume");
	this.Tag("hopperable");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) > 96.0f) return;
	if (getGameTime() <= this.get_u32("button_delay")) return;
	this.set_u32("button_delay", getGameTime()+5);
	
	CBitStream params;
	params.write_u16(caller.getNetworkID());
	caller.CreateGenericButton(22, Vec2f(0, 0), this, this.getCommandID("consume"), "Eat!", params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("consume"))
	{
		if (getGameTime() < this.get_u32("consume_delay")) return;
		this.set_u32("consume_delay", getGameTime()+2);
		// this.getSprite().PlaySound("Huuu.ogg", 1.0f, 1.5f);
		this.getSprite().PlaySound("vo_no.ogg", 2.00f, 1.00f);

		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			if (!caller.hasScript("Schisked.as")) caller.AddScript("schisked.as");
			
			if (isServer())
			{
				this.server_Die();
			}
		}
	}
}
