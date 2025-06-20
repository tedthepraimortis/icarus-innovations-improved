class HDPDFour : HDWeapon {

	private int BurstIndex;

	Default {
		+HDWEAPON.FITSINBACKPACK
		Weapon.SelectionOrder 300;
		Weapon.SlotNumber 4;
		Weapon.SlotPriority 3;
		HDWeapon.BarrelSize 20,0.5,1;
		Scale 0.45;
		Tag "$TAG_PD42";
		HDWeapon.Refid HDLD_PD4;
		inventory.icon "PDWGA0";

		HDWeapon.Loadoutcodes "
			\cufiremode - 0-2, semi/burst/auto
			\cuslugger - Under-Barrel Slug Thrower
			\cureflexsight - 0/1, no/yes
			\cudot - 0-5";
	}

	override bool AddSpareWeapon(actor newowner) {
		return AddSpareWeaponRegular(newowner);
	}

	override HDWeapon GetSpareWeapon(actor newowner, bool reverse, bool doselect) {
		return GetSpareWeaponRegular(newowner, reverse, doselect);
	}

	override double GunMass() {
		return 6 + (weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? 1 : 0) + 0.03 * weaponStatus[PDS_MAG];
	}

	override double WeaponBulk() {
		double bulk = 0;

		int mag = weaponStatus[PDS_MAG];
		if (mag >= 0) {
			bulk += HDPDFourMag.EncMagLoaded + mag * ENC_426_LOADED;
		}

		if (weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER) {
			bulk += 5;
		}

		if (weaponStatus[PDS_SLUGCHAMBER]) {
			bulk += ENC_SHELLLOADED;
		}

		return 80 + bulk;
	}

	override void PostBeginPlay() {
		Super.PostBeginPlay();

		weaponspecial = 1337; // [Ace] UaS sling compatibility.
	}

	override void Tick() {
		Super.Tick();

		DrainHeat(PDS_HEAT, 10);

		// FIXME: Rework the removal of the slug thrower?
		// I wanna say this is just for FAK support,
		// as I'm not sure what else could just arbitrarily remove it
		if (!(weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER) && weaponStatus[PDS_SLUGCHAMBER]) {
			weaponStatus[PDS_SLUGCHAMBER] = 0;

			Actor ptr = owner ? owner : Actor(self);
			ptr.A_StartSound("weapons/huntrackup", CHAN_WEAPON, CHANF_OVERLAP);
			ptr.A_SpawnItemEx(
				weaponStatus[PDS_SLUGCHAMBER] > 1 ? 'HDFumblingSlug' : 'HDSpentSlug',
				cos(ptr.pitch) * 10, 0, ptr.height - 10 - 10 * sin(ptr.pitch),
				ptr.vel.x, ptr.vel.y, ptr.vel.z,
				0,
				SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH
			);
		}
	}

	override string PickupMessage()
	{
		String SlugStr = WeaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? Stringtable.localize("$PICKUP_PD42_SLUGTHROWER") : "";

		return Stringtable.localize("$PICKUP_PD42_PREFIX")..Stringtable.localize("$TAG_PD42")..SlugStr..Stringtable.localize("$PICKUP_PD42_SUFFIX");
	}

	override string, double GetPickupSprite()
	{
		string slugFrame = weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? "S" : "G";

		string magFrame = "";
		if (weaponStatus[PDS_MAG] > 0) {
			magFrame = weaponStatus[PDS_FLAGS] & PDF_REFLEXSIGHT ? "C" : "A";
		} else {
			magFrame = weaponStatus[PDS_FLAGS] & PDF_REFLEXSIGHT ? "D" : "B";
		}

		return "PDW"..slugFrame..magFrame.."0", 1.0;
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
		if (sb.HudLevel == 1) 
		{
			int NextMagLoaded = sb.GetNextLoadMag(HDMagAmmo(hpl.findinventory("HDPDFourMag")));
			if (NextMagLoaded >= HDPDFourMag.MagCapacity) {
				sb.DrawImage("PDMGA0", (-46, -3),sb. DI_SCREEN_CENTER_BOTTOM, scale: (1.0, 1.0));
			} else if (NextMagLoaded <= 0) {
				sb.DrawImage("PDMGB0", (-46, -3), sb.DI_SCREEN_CENTER_BOTTOM, alpha: NextMagLoaded ? 0.6 : 1.0, scale: (1.0, 1.0));
			} else {
				sb.DrawBar("PDMGNORM", "PDMGGREY", NextMagLoaded, HDPDFourMag.MagCapacity, (-46, -3), -1, sb.SHADER_VERT, sb.DI_SCREEN_CENTER_BOTTOM);
			}

			sb.DrawNum(hpl.CountInv('HDPDFourMag'), -43, -8, sb.DI_SCREEN_CENTER_BOTTOM);

			if (hdw.weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER) {
				sb.DrawImage("SLG1A0",(-59, -8), sb.DI_SCREEN_CENTER_BOTTOM, scale: (0.6, 0.6));
				sb.DrawNum(hpl.CountInv('HDSlugAmmo'), -58, -8, sb.DI_SCREEN_CENTER_BOTTOM);
			}
		}

		sb.DrawWepNum(hdw.weaponStatus[PDS_MAG], HDPDFourMag.MagCapacity);

		if (hdw.weaponStatus[PDS_CHAMBER] == 1) {
			sb.DrawRect(-19, -11, 3, 1);
		}
		
		if (hdw.weaponStatus[PDS_SLUGCHAMBER]) {
			sb.DrawRect(-18, -15, 2, 3);

			if (hdw.weaponStatus[PDS_SLUGCHAMBER] > 1) {
				sb.DrawRect(-23, -15, 4, 3);
				sb.DrawRect(-24, -14, 1, 1);
			}
		}

		sb.DrawWepCounter(hdw.weaponStatus[PDS_FIREMODE], -25, -10, "RBRSA3A7", "STBURAUT", "STFULAUT");
	}

	override string GetHelpText() {
		LocalizeHelp();
		return 
		LWPHELP_FIRESHOOT
		..(weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? LWPHELP_ALTFIRE.. Stringtable.Localize("$PD42_HELPTEXT_1") : "")
		..(weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? LWPHELP_ALTRELOAD.. Stringtable.Localize("$PD42_HELPTEXT_2") : "")
		..(weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER ? LWPHELP_USE.."+"..LWPHELP_UNLOAD.. Stringtable.Localize("$PD42_HELPTEXT_3") : "")
		..LWPHELP_RELOAD..Stringtable.Localize("$PD42_HELPTEXT_4")
		..LWPHELP_UNLOADUNLOAD
		..LWPHELP_FIREMODE..Stringtable.Localize("$PD42_HELPTEXT_5")
		..LWPHELP_MAGMANAGER;
	}

	override void DrawSightPicture(
		HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl,
		bool sightbob, vector2 bob, double fov, bool scopeview, actor hpc, string whichdot
	) {
		vector2 bobb = bob*1.18;

		if (weaponStatus[PDS_FLAGS] & PDF_REFLEXSIGHT) {
			double dotoff = max(abs(bob.x), abs(bob.y));
			if (dotoff < 40) {
				string whichdot = sb.ChooseReflexReticle(hdw.weaponStatus[PDS_DOT]);
				sb.DrawImage(whichdot, (0, 0) + bob * 1.18, sb.DI_SCREEN_CENTER | sb.DI_ITEM_CENTER, alpha : 0.8 - dotoff * 0.01, col:0xFF000000 | sb.crosshaircolor.GetInt());
			}
			sb.DrawImage("PDWBACK", (0, -18) + bob, sb.DI_SCREEN_CENTER | sb.DI_ITEM_TOP, scale: (0.8, 0.8));
		} else {
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			sb.SetClipRect(
				-16+bob.x,-4+bob.y,32,16,
				sb.DI_SCREEN_CENTER
			);
			//bobb.y=clamp(bobb.y,-8,8);
			sb.drawimage(
				"PDFNTSIT",(0,0)+bobb,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP
			);
			sb.SetClipRect(cx,cy,cw,ch);
			sb.drawimage(
				"PDBAKSIT",(0,0)+bob,sb.DI_SCREEN_CENTER|sb.DI_ITEM_TOP,
				alpha:0.9
			);
		}
	}

	override void DropOneAmmo(int amt) {
		if (owner) {
			double oldAngle = owner.angle;

			amt = clamp(amt, 1, 10);
			if (owner.CheckInventory('FourMilAmmo', 1)) {
				owner.A_DropInventory('FourMilAmmo', amt * 30);
			} else {
				owner.A_DropInventory('HDPDFourMag', amt);
			}

			owner.angle += 15;
			if (owner.CheckInventory('HDSlugAmmo', 1)) {
				owner.A_DropInventory('HDSlugAmmo', amt * 4);
			}

			owner.angle = oldAngle;
		}
	}

	override void SetReflexReticle(int which) {
		weaponStatus[PDS_DOT] = which;
	}

	action void A_CheckReflexSight() {
		if(invoker.weaponStatus[PDS_FLAGS] & PDF_REFLEXSIGHT) {
			Player.GetPSprite(PSP_WEAPON).sprite=getspriteindex("PDFGA0");
		} else {
			Player.GetPSprite(PSP_WEAPON).sprite=getspriteindex("PDFSA0");
		}
	}

	states{
		select0:
			PDFG A 0 A_CheckDefaultReflexReticle(PDS_DOT);
			PDFG A 0 A_CheckReflexSight();
			goto select0Small;
			
		deselect0:
			PDFG A 0 A_CheckReflexSight();
			goto deselect0Small;
			PDFG AB 0;
			PDFS AB 0;

		ready:
			PDFG A 0 A_CheckReflexSight();
			#### A 1
			{
				invoker.BurstIndex = 0;
				A_WeaponReady(WRF_ALL);
			}
			goto readyend;
		
		user3:
			#### A 0 A_MagManager("HDPDFourMag");
			goto ready;

		firemode:
			#### A 1
			{
				++invoker.weaponStatus[PDS_FIREMODE] %= 3;
			}
			goto nope;

		fire:
			#### A 0;
		fire2:
			#### B 1
			{
				if (invoker.weaponStatus[PDS_CHAMBER] > 0) {
					A_Overlay(PSP_FLASH, "Flash");
				} else {
					SetWeaponState('chamber_manual');
				}
			}
			#### A 0
			{
				A_WeaponOffset(0, 35);
				if (invoker.weaponStatus[PDS_MAG] > 0) {
					invoker.weaponStatus[PDS_CHAMBER] = 1;
					invoker.weaponStatus[PDS_MAG]--;
				}

				if (invoker.weaponStatus[PDS_FIREMODE] == 2) {
					A_SetTics(2);
				}

				A_WeaponReady(WRF_NOFIRE);
			}
			#### # 0
			{
				switch (invoker.weaponStatus[PDS_FIREMODE]) {
					case 1:
						if (invoker.BurstIndex < 1) {
							invoker.BurstIndex++;
							A_Refire('fire');
						}
						break;
					case 2:
						A_Refire('fire');
						break;
				}
			}
			goto nope;

		altfire:
			#### # 0 A_JumpIf(invoker.weaponStatus[PDS_SLUGCHAMBER] < 2, 'nope');
			#### # 2 A_Overlay(PSP_FLASH, "AltFlash");
			goto nope;

		flash:
			PDFF A 1
			{
				int heat = min(50, invoker.weaponStatus[PDS_HEAT]);

				HDBulletActor.FireBullet(self, "HDB_426", spread: heat > 20 ? heat * 0.2 : 0, speedfactor: 0.9);
				A_AlertMonsters(HDCONST_ONEMETRE * (15 + heat));

				A_StartSound("PD42/Fire", CHAN_WEAPON);
				
				invoker.weaponStatus[PDS_CHAMBER] = 0;
				invoker.weaponStatus[PDS_HEAT] += random(3, 5) * (invoker.weaponStatus[PDS_FIREMODE] == 1 ? 2 : 1);
				
				A_ZoomRecoil(0.95);
				HDFlashAlpha(-200);
				A_Light1();
				
				if (invoker.weaponStatus[PDS_FIREMODE] == 1) {
					// Hyperburst (totals: -[1.6 - 2.6], -[2.5 - 4.8])
					A_MuzzleClimb(
						0, 0,
						-frandom(1.2, 1.4), -frandom(1.6, 3.0),
						-frandom(0.4, 1.2), -frandom(0.9, 1.8)
					);
				} else {
					// Semi/Full Auto (totals: -[1.2 - 2.6], -[2.4 - 4.8])
					A_MuzzleClimb(
						0, 0,
						-frandom(0.6, 0.8), -frandom(0.8, 1.6),
						-frandom(0.4, 1.2), -frandom(0.8, 1.6),
						-frandom(0.2, 0.6), -frandom(0.8, 1.6)
					);
				}
			}
			goto lightdone;

		altflash:
			PDFF B 1 bright
			{
				A_WeaponOffset(0, 36);

				HDBulletActor.FireBullet(self, "HDB_wad");
				let p = HDBulletActor.FireBullet(self, "HDB_SLUG", speedfactor: 0.65);
				A_AlertMonsters();
				
				invoker.weaponStatus[PDS_SLUGCHAMBER] = 1;
				invoker.weaponStatus[PDS_HEAT] += random(12, 20);
				
				DistantNoise.Make(p, "world/shotgunfar");
				A_StartSound("PD42/SluggerFire", CHAN_WEAPON);

				let str = clamp(10 - HDPlayerPawn(self).strength, 0, 10);
				if (!GunBraced() && str > 0) {
					GiveBody(max(0, 11 - health));
					DamageMobj(invoker, self, str, "bashing");
				}
			}
			#### # 1 bright
			{
				A_ZoomRecoil(GunBraced() ? 0.75 : 0.65);
				HDFlashAlpha(-200);
				A_Light1();
				
				let str = clamp(10 - HDPlayerPawn(self).strength, 0, 10);
				let shotPower = HDShotgun.GetShotPower();

				// Totals (1 Strength):   -[5.40 - 7.575], -[4.05 - 7.275]
				// Totals (10+ Strength): -[1.44 - 3.360], -[2.16 - 5.040]
				A_MuzzleClimb(
					0, 0,
					-frandom(0.45 * str, 0.55 * str), -frandom(0.2 * str, 0.4 * str),
					-frandom(1.6 * shotPower, 3.2 * shotPower), -frandom(2.4 * shotPower, 4.8 * shotPower)
				);
			}
			goto lightdone; 

		unload:
			#### A 0
			{
				invoker.weaponStatus[PDS_FLAGS] |= PDF_JUSTUNLOAD;
				if (PressingUse() && invoker.weaponStatus[PDS_SLUGCHAMBER]) {
					SetWeaponState('unloadst');
					Return;
				}

				if (invoker.weaponStatus[PDS_MAG] >= 0) {
					SetWeaponState('unmag');
				} else if (invoker.weaponStatus[PDS_CHAMBER] > 0) {
					SetWeaponState('UnloadChamber');
				}
			}
			goto nope;

		unloadchamber:
			#### A 1 A_JumpIf(invoker.weaponStatus[PDS_CHAMBER] == 0, "nope");
			#### A 4 Offset(2, 34)
			{
				A_StartSound("PD42/BoltPull", 8);
			}
			#### A 6 Offset(1, 36)
			{
				class<Actor> Which = invoker.weaponStatus[PDS_CHAMBER] > 1 ? "FourMilAmmo" : "ZM66DroppedRound";
				invoker.weaponStatus[PDS_CHAMBER] = 0;
				A_SpawnItemEx(which, cos(pitch) * 10, 0, height - 8 - sin(pitch) * 10, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
			}
			#### A 2 Offset(0, 34);
			goto readyend;
		loadchamber:
			#### A 0 A_JumpIf(invoker.weaponstatus[PDS_CHAMBER] > 0, "nope");
			#### A 0 A_JumpIf(!countinv("FourMilAmmo"),"nope");
			#### A 1 offset(0,34) A_StartSound("weapons/pocket",9);
			#### A 1 offset(2,36);
			#### A 1 offset(2,44);
			#### B 1 offset(5,58);
			#### B 2 offset(7,70);
			#### B 6 offset(8,80);
			#### A 10 offset(8,87) {
				if (countinv("FourMilAmmo")) {
					A_TakeInventory("FourMilAmmo", 1, TIF_NOTAKEINFINITE);
					invoker.weaponstatus[PDS_CHAMBER] = 1;
					A_StartSound("weapons/smgchamber",8);
				} else {
					A_SetTics(4);
				}
			}
			#### A 3 offset(9,76);
			#### A 2 offset(5,70);
			#### A 1 offset(5,64);
			#### A 1 offset(5,52);
			#### A 1 offset(5,42);
			#### A 1 offset(2,36);
			#### A 2 offset(0,34);
			goto nope;

		altreload:
			#### A 0
			{
				invoker.weaponStatus[PDS_FLAGS] &= ~PDF_JUSTUNLOAD;
				if (invoker.weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER && invoker.weaponStatus[PDS_SLUGCHAMBER] < 2 && CheckInventory('HDSlugAmmo', 1))
				{
					SetWeaponState('unloadst');
				}
			}
			goto nope;

		unloadst:
			#### A 0
			{
				A_SetCrosshair(21);
				A_MuzzleClimb(-0.3, -0.3);
			}
			#### A 2 Offset(0, 34);
			#### A 1 Offset(4, 38) A_MuzzleClimb(-0.3,-0.3);
			#### A 2 Offset(8, 48)
			{
				A_StartSound("weapons/huntrackup", CHAN_WEAPON, CHANF_OVERLAP);
				A_MuzzleClimb(-0.3, -0.3);
			}
			#### A 2 Offset(8, 48)
			{
				if (invoker.weaponStatus[PDS_SLUGCHAMBER]) {
					A_StartSound("weapons/huntreload", CHAN_WEAPON);
				}
			}
			#### A 2 Offset(10, 49)
			{
				if (!(invoker.weaponStatus[PDS_SLUGCHAMBER])) {
					if (invoker.weaponStatus[PDS_FLAGS] & PDF_JUSTUNLOAD) {
						A_SetTics(3);
					}

					return;
				}
				
				// If we long press unload, and the chamber is a fresh slug, and the player has the max amount of slugs,
				// then give them a slug.
				// Otherwise, simply dump the slug onto the ground.
				if(PressingUnload() && invoker.weaponStatus[PDS_SLUGCHAMBER] >= 2 && !A_JumpIfInventory('HDSlugAmmo', 0, 'Null')) {
					A_SetTics(20);
					A_StartSound("weapons/pocket", CHAN_WEAPON, CHANF_OVERLAP);
					A_GiveInventory('HDSlugAmmo', 1);
					A_MuzzleClimb(frandom(0.8, -0.2), frandom(0.4, -0.2));
				} else {
					A_SpawnItemEx(
						invoker.weaponStatus[PDS_SLUGCHAMBER] > 1 ? 'HDFumblingSlug' : 'HDSpentSlug',
						cos(pitch) * 10, 0, height - 10 - 10 * sin(pitch),
						vel.x, vel.y, vel.z,
						0,
						SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH
					);
				}

				invoker.weaponStatus[PDS_SLUGCHAMBER] = 0;
			}
			#### A 0 A_JumpIf(invoker.weaponStatus[PDS_FLAGS] & PDF_JUSTUNLOAD, 'ReloadEndST');

		loadst:
			#### A 2 Offset(10, 50) A_StartSound("weapons/pocket", CHAN_WEAPON,  CHANF_OVERLAP);
			#### A 5 Offset(10, 50) A_MuzzleClimb(frandom(-0.2, 0.8), frandom(-0.2, 0.4));
			#### A 10 Offset(8, 50)
			{
				A_TakeInventory('HDSlugAmmo', 1, TIF_NOTAKEINFINITE);
				invoker.weaponStatus[PDS_SLUGCHAMBER] = 2;
				A_StartSound("weapons/huntreload", CHAN_WEAPON);
			}

		reloadendst:
			#### A 4 Offset(4, 44) A_StartSound("weapons/huntrackdown", CHAN_WEAPON);
			#### A 1 Offset(0, 40);
			#### A 1 Offset(0, 34) A_MuzzleClimb(frandom(-2.4, 0.2), frandom(-1.4, 0.2));
			goto nope;

		reload:
			#### A 0
			{
				invoker.weaponStatus[PDS_FLAGS] &= ~PDF_JUSTUNLOAD;
				bool noMags = HDMagAmmo.NothingLoaded(self, "HDPDFourMag");
				int mag = invoker.weaponStatus[PDS_MAG];
				if (mag >= HDPDFourMag.MagCapacity) {
					SetWeaponState("nope");
				} else if (mag < 1 && (PressingUse() || noMags)) {
					if (CountInv('FourMilAmmo')) {
						SetWeaponState('loadchamber');
					} else {
						SetWeaponState("nope");
					}
				} else if (noMags) {
					SetWeaponState("nope");
				}
			}
			goto unmag;

		unmag:
			#### A 1 Offset(0,34) A_SetCrosshair(21);
			#### A 1 Offset(5,38);
			#### A 1 Offset(10,42);
			#### A 2 Offset(20,46) A_StartSound("weapons/smgmagclick",8);
			#### A 4 Offset(30,52)
			{
				A_MuzzleClimb(0.3,0.4);
				A_StartSound("PD42/MagOut",8,CHANF_OVERLAP);
			}
			#### A 0
			{
				int magamt = invoker.weaponStatus[PDS_MAG];
				if(magamt < 0) {
					SetWeaponState("magout");
					return;
				}

				invoker.weaponStatus[PDS_MAG]=-1;
				if (
					(!PressingUnload() && !PressingReload())
					|| A_JumpIfInventory("HDPDFourMag",0,"null")
				) {
					HDMagAmmo.SpawnMag(self,"HDPDFourMag", magamt);
					SetWeaponState("magout");
				} else {
					HDMagAmmo.GiveMag(self,"HDPDFourMag", magamt);
					A_StartSound("weapons/pocket",9);
					SetWeaponState("pocketmag");
				}
			}
		pocketmag:
			#### AA 7 Offset(34,54) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
		magout:
			#### A 0
			{
				if(invoker.weaponStatus[PDS_FLAGS] & PDF_JUSTUNLOAD) {
					SetWeaponState("reloadend");
				} else {
					SetWeaponState("loadmag");
				}
			}

		loadmag:
			#### A 0 A_StartSound("weapons/pocket", 9);
			#### A 6 Offset(26, 54) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 7 Offset(26, 52) A_MuzzleClimb(frandom(0.2, -0.8), frandom(-0.2, 0.4));
			#### A 10 Offset(24, 50);
			#### A 3 Offset(24, 48)
			{
				let mag = HDMagAmmo(FindInventory("HDPDFourMag"));
				if (mag) {
					invoker.weaponStatus[PDS_MAG] = mag.TakeMag(true);
					A_StartSound("PD42/MagIn", 8, CHANF_OVERLAP);
				}
			}
			goto reloadend;

		reloadend:
			#### A 3 Offset(30, 52);
			#### A 2 Offset(20, 46);
			#### A 1 Offset(10, 42);
			#### A 1 Offset(5, 38);
			#### A 1 Offset(0, 34);
			goto chamber_manual;

		chamber_manual:
			#### A 0 A_JumpIf(
					invoker.weaponStatus[PDS_MAG] < 1
					|| invoker.weaponStatus[PDS_CHAMBER] == 1,
				"nope");
			#### A 2 Offset(2, 34);
			#### A 2 Offset(3, 38) A_StartSound("PD42/BoltPull", 8, CHANF_OVERLAP);
			#### A 3 Offset(4, 44)
			{
				if (invoker.weaponStatus[PDS_CHAMBER] == 1) {
					A_SpawnItemEx("ZM66DroppedRound", cos(pitch) * 10, 0, height - 10 - sin(pitch) * 10, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH);
					invoker.weaponStatus[PDS_CHAMBER] = 0;
				}

				A_WeaponBusy();
				invoker.weaponStatus[PDS_MAG]--;
				invoker.weaponStatus[PDS_CHAMBER] = 1;
			}
			#### A 1 Offset(3, 38);
			#### A 1 Offset(2, 34);
			#### A 1 Offset(0, 32);
			goto nope;
		
		spawn:
			TNT1 A 1;
			PDWS A 0 A_JumpIf(invoker.weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER, 2);
			PDWG A 0;
			#### # -1
			{
				int offset = invoker.weaponStatus[PDS_FLAGS] & PDF_REFLEXSIGHT ? 2 : 0;
				frame = (invoker.weaponStatus[PDS_MAG] < 0 ? 1 : 0) + offset;
			}
			stop;
	}

	override void InitializeWepStats(bool idfa) {
		weaponStatus[PDS_MAG] = HDPDFourMag.MagCapacity;
		weaponStatus[PDS_CHAMBER] = 1;
		
		if (weaponStatus[PDS_FLAGS] & PDF_SLUGLAUNCHER) {
			weaponStatus[PDS_SLUGCHAMBER] = 2;
		}
	}

	override void LoadoutConfigure(string input) {
		let firemode = GetLoadoutVar(input, "firemode", 1);
		if (firemode >= 0) {
			weaponStatus[PDS_FIREMODE] = clamp(firemode, 0, 2);
		}

		if (GetLoadoutVar(input, "reflexsight", 1) > 0) {
			weaponStatus[PDS_FLAGS] |= PDF_REFLEXSIGHT;

			let xhdot = GetLoadoutVar(input, "dot", 3);
			if (xhdot >= 0) {
				weaponStatus[PDS_DOT] = xhdot;
			}
		}

		if (GetLoadoutVar(input, "slugger", 1) > 0) {
			weaponStatus[PDS_FLAGS] |= PDF_SLUGLAUNCHER;
		}

		InitializeWepStats();
	}
}

enum PDFourStatus {
	PDF_JUSTUNLOAD = 1,
	PDF_SLUGLAUNCHER = 2,
	PDF_REFLEXSIGHT = 4,

	PDS_FLAGS = 0,
	PDS_MAG = 1,
	PDS_CHAMBER = 2,
	PDS_FIREMODE = 3, //0 semi, 1 burst, 2 auto
	PDS_DOT = 4,
	PDS_SLUGCHAMBER = 5,
	PDS_HEAT = 6
}

class PDFourRandom : IdleDummy {
	states {
		spawn:
			TNT1 A 0 NoDelay
			{
				A_SpawnItemEx('HDPDFourMag', -3,flags: SXF_NOCHECKPOSITION);
				A_SpawnItemEx('HDPDFourMag', 3,flags: SXF_NOCHECKPOSITION);
				
				let wpn = HDPDFour(Spawn('HDPDFour', pos, ALLOW_REPLACE));
				if (!wpn) return;

				HDF.TransferSpecials(self, wpn);

				if (!random(0, 2)) {
					wpn.weaponStatus[PDS_FLAGS] |= PDF_REFLEXSIGHT;
				}

				if (!random(0, 2)) {
					wpn.weaponStatus[PDS_FIREMODE] = random(0, 2);
				}

				if (!random(0, 2)) {
					wpn.weaponStatus[PDS_FLAGS] |= PDF_SLUGLAUNCHER;
					A_SpawnItemEx('SlugPickup', -6,flags: SXF_NOCHECKPOSITION);
				}

				wpn.InitializeWepStats(false);
			}
			stop;
	}
}

class HDPDFourMag : HDMagAmmo {

	override string PickupMessage()
	{
		return Stringtable.localize("$PICKUP_PD42MAG_PREFIX")..Stringtable.localize("$TAG_PD42MAG")..Stringtable.localize("$PICKUP_PD42MAG_SUFFIX");
	}

	override string, string, name, double GetMagSprite(int thismagamt)
	{
		return (thismagamt > 0) ? "PDMGA0" : "PDMGB0", "RBRSBRN", "FourMilAmmo", 1.0;
	}

	override void GetItemsThatUseThis() {
		ItemsThatUseThis.Push("HDPDFour");
	}

	const MagCapacity = 36;
	const EncMagEmpty = 6;
	const EncMagLoaded = EncMagEmpty * 1.2;

	Default {
		HDMagAmmo.MaxPerUnit MagCapacity;
		HDMagAmmo.InsertTime 8;
		HDMagAmmo.ExtractTime 6;
		HDMagAmmo.RoundType "FourMilAmmo";
		HDMagAmmo.RoundBulk ENC_426_LOADED;
		HDMagAmmo.MagBulk EncMagEmpty;
		Tag "$TAG_PD42MAG";
		HDPickup.RefId HDLD_PD4MAG;
		Scale 0.35;
	}
	
	override bool Extract() {
		SyncAmount();
		int mindex = Mags.Size() - 1;
		if (mindex == -1 || Mags[mindex] < 1 || owner.A_JumpIfInventory(roundtype, 0, "null")) {
			return false;
		}

		ExtractTime = GetDefaultByType(GetClass()).extracttime;
		
		int toTake = min(random(1, 24), mags[mindex]);
		if (toTake < HDPickup.MaxGive(owner, roundtype, roundbulk)) {
			HDF.Give(owner, roundtype, totake);
		} else {
			HDPickup.DropItem(owner, roundtype, totake);
		}

		owner.A_StartSound("weapons/rifleclick2", CHAN_WEAPON);
		owner.A_StartSound("weapons/rockreload", CHAN_WEAPON, CHANF_OVERLAP, 0.4);
		
		Mags[mindex] -= totake;
		
		return true;
	}
	
	override bool Insert() {
		SyncAmount();

		int mindex = Mags.Size() - 1;
		if (mindex == -1 || Mags[Mags.Size() - 1] >= MaxPerUnit || owner.CountInv(roundtype) == 0) {
			return false;
		}

		owner.A_TakeInventory(roundtype, 1, TIF_NOTAKEINFINITE);
		owner.A_StartSound("weapons/rifleclick2", 7);

		if (random(0,100) <= 10) {
			owner.A_StartSound("weapons/bigcrack", 8, CHANF_OVERLAP);
			owner.A_SpawnItemEx("WallChunk", 12, 0, owner.height - 12, 4, frandom(-2, 2), frandom(2, 4));
			return false;
		}
		owner.A_StartSound("weapons/pocket", 9, volume: frandom(0.1, 0.6));
		Mags[mindex]++;
		return true;
	}
	
	states{
		spawn:
			PDMG A -1;
			stop;
		spawnempty:
			PDMG B -1
			{
				bROLLSPRITE = true;
				bROLLCENTER = true;
				roll = randompick(0, 0, 0, 0, 2, 2, 2, 2, 1, 3) * 90;
			}
			stop;
	}
}
