/**
 *	SASS' CINEMATIC MOD --- "Actors" file
 *	Version : #280
 *	
 *	GitHub  : https://github.com/sasseries/iw4-cine-mod
 *	Discord : sass#1997
 */

#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\_movie;
#using_animtree( "destructibles" );
#using_animtree( "multiplayer" );

actor()
{

		setDvarIfUninitialized( "mvm_actor_spawn", "body head - ^3Spawns actor" );
		setDvarIfUninitialized( "mvm_actor_anim", "actor anim - ^3Sets actor animation" );
		setDvarIfUninitialized( "mvm_actor_weapon", "actor tag weapon camo - ^3Sets actor weapon" );
		setDvarIfUninitialized( "mvm_actor_walk", "actor time direction - ^3Makes the actor walk towards the given direction" );
		setDvarIfUninitialized( "mvm_actor_health", "actor health - ^3hanges actor's health amount" );
		setDvarIfUninitialized( "mvm_actor_move", "actor - ^3Teleports actor to your position" );
		setDvarIfUninitialized( "mvm_actor_delete", "actor - ^3Deletes actor" );
		setDvarIfUninitialized( "mvm_actor_model", "actor body head - ^3Changes actor's model" );
		setDvarIfUninitialized( "mvm_actor_death", "actor anim - ^3Sets actor death anim" );
		setDvarIfUninitialized( "mvm_actor_node_save", "actor node - ^3Saves node for actor walk" );
		setDvarIfUninitialized( "mvm_actor_node_del", "actor node - ^3Deletes node for actor walk" );
		setDvarIfUninitialized( "mvm_actor_node_walk", "actor - ^3Saves node for actor walk" );
		setDvarIfUninitialized( "mvm_actor_gopro", "action actor tag x y z x y z" );

		setDvarIfUninitialized( "actorback", " " );
		setDvarIfUninitialized( "actor_test", " " );

			
		// Precache thread
		// IMPORTANT : Put your own precache in the _precache.gsc file, and not this one
		thread _precache::precache();

		PrecacheMPAnim("pb_hold_idle"); // Default stand anim
		PrecacheMPAnim("pb_stand_death_chest_blowback"); // Default death anim

		precacheModel("projectile_m67fraggrenade_bombsquad");
		precacheModel("projectile_stinger_missile");
		precacheModel("defaultactor");

		level._effect["blood"] = loadfx("impacts/flesh_hit_body_fatal_exit");

		level.goPro = spawn("script_model", (9999,9999,9999) );
		level.goPro setModel( "tag_origin" );
		level.goPro.origin = self getorigin();
		level.goPro.angles = self getplayerangles();
		level.goPro.linked = 0;
		level.goPro enablelinkto();
		wait 0.05;
		level.goPro.obj = spawn("script_model", (9999,9999,9999) );
		level.goPro.obj setModel( "projectile_rpg7" );
		level.goPro.obj.origin = level.goPro.origin;
		level.goPro.obj.angles = (level.goPro.angles - (15, 0, 0));
		wait 0.05;
		level.goPro.obj linkTo( level.goPro, "tag_origin" );


		level thread OnPlayerConnect();
}


OnPlayerConnect()
{
    for(;;)
    {
        level waittill( "connected", player );   
		player thread OnPlayerSpawn();
    }
}


OnPlayerSpawn()
{
    self endon( "disconnect" );
    for(;;)
    {
		self waittill("spawned_player");
	
		thread SpawnActor();
		thread HPActor();
		thread DeleteActor();
		thread AnimActor();
		thread EquipActor();
		thread PathActor();
		thread DeathActor();
		thread MeeActor();
		thread ActorBack();
		thread ActorSetPath();
		thread ActorDoPath();
		thread ActorDeletePath();
		thread ChangeActorModel();
		thread ActorGoPro();
    }
}

SpawnActor()
{
	self endon( "death" );
    self endon( "disconnect" );

	actor = [];
	
    self notifyOnPlayerCommand( "mvm_actor_spawn", "mvm_actor_spawn" );
    
	for (i=1; i>=0; i++)
    {
        
        self waittill("mvm_actor_spawn");
		
		start = self getTagOrigin( "tag_eye" );
        end = anglestoforward(self getPlayerAngles()) * 1000000;
        actorpos = BulletTrace(start, end, true, self)["position"];
		
		argumentstring = getDvar( "mvm_actor_spawn", "body head - ^3Spawns actor" );
        arguments = StrTok(argumentstring, " ,");

		level.actor[i] = spawn( "script_model", actorpos);
		level.actor[i].angles = self.angles + (0,180,0);
		level.actor[i] EnableLinkTo();
		//level.actor[i] Solid();
     	level.actor[i] setModel(arguments[0]);
		level.actor[i] scriptModelPlayAnim("pb_stand_alert_mg");
		level.actor[i].name = ("actor" + i);
		
		level.actor[i].oldorg = 0;
		level.actor[i].oldang = 0;
        level.actor[i].ismoving = 0;
		
		level.actor[i].head = spawn("script_model", level.actor[i] getTagOrigin( "j_spine4" ));
		level.actor[i].head setModel(arguments[1]);
		level.actor[i].head.angles = level.actor[i].angles +(270,0,270);
		level.actor[i].head linkto(level.actor[i], "j_spine4");
		level.actor[i].head scriptModelPlayAnim("pb_stand_alert_mg");

		for(f=1; f < 13; f++)
		{
			level.actor[i].nodeorg[f] = 0;
			level.actor[i].nodeang[f] = 0;
			level.actor[i].nodeobj[f] = undefined;
			wait 0.05;
		}
		level.actor[i] thread PathDebug();
		level.actor[i].nodecount = 0;
		
		level.actor[i].hitbox = spawn("script_model", level.actor[i].origin + (0,0,30) ); 
		level.actor[i].hitbox setModel("com_plasticcase_enemy");
		level.actor[i].hitbox Solid();
		level.actor[i].hitbox.angles = (90,0,0);
		level.actor[i].hitbox hide();
		level.actor[i].hitbox.name = "hitbox" + i;
		level.actor[i].hitbox setCanDamage(1);
		level.actor[i].hitbox.health = 120; //default value
		level.actor[i].hitbox.savedhealth = 120; //same
		level.actor[i].hitbox linkto( level.actor[i] );
		level.actor[i].hitbox thread ActorHandleDamage( level.actor[i].hitbox, level.actor[i] );
		
		level.actor[i].deathanim = "pb_stand_death_chest_blowback";
		level.actor[i].assignedanim = "pb_stand_alert_mg";

		self iPrintLn(level.actor[i].name + "^3 spawned ^7: " + actorpos);
		
	}
}




ChangeActorModel()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_model", "mvm_actor_model" );
    
	for (;;)
    {
        self waittill("mvm_actor_model");
		
		argumentstring = getDvar( "mvm_actor_model", "Set the actor's health" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
			{
				actor setModel(arguments[1]);
				actor.head setModel(arguments[2]);
			}
        }
	}
}



HPActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_health", "mvm_actor_health" );
    
	for (;;)
    {
        self waittill("mvm_actor_health");
		
		argumentstring = getDvar( "mvm_actor_health", "Set the actor's health" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
			{
				actor.hitbox.savedhealth = int(arguments[1]);
				actor.hitbox.health = actor.hitbox.savedhealth;
				self iPrintLn( "^3" + actor.name +"^7's health set to ^3" + actor.hitbox.savedhealth );
			}
        }
	}
}

ActorHandleDamage( crate, actor )
{
	while ( self.health > 0 )
	{
		self waittill( "damage", amount, attacker, dir, point, type );
		level.attacker = attacker;
		attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "standard" );
	
		if ( isDefined( attacker ) && isPlayer( attacker ) && attacker != self.owner )
		{
			self.health -= amount;
			
			//attacker iprintln(self.name + " HP : " + self.health);
			continue;
			wait 0.15;
		}
	}
	actor scriptModelPlayAnim(actor.deathanim);
	actor.head scriptModelPlayAnim(actor.deathanim);
	//playFx( level._effect["blood"], actor.getTagOrigin( "j_spine4" ) );
	level.attacker maps\mp\gametypes\_rank::scorePopup(level.scoreInfo["kill"]["value"],0);
}

DeleteActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_delete", "mvm_actor_delete" );
    
	for (;;)
    {
        self waittill("mvm_actor_delete");
		foreach( actor in level.actor ) 
        {
            if(actor.name == getDvar("mvm_actor_delete", ""))
            {
				actor Delete();
                actor.head Delete();
				actor.hitbox Delete();
				actor.equ Delete();
				self iPrintLn( actor.name + "^1 deleted!" );
            }
        }
	}
}

AnimActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_anim", "mvm_actor_anim" );
    
	for (;;)
    {
        self waittill("mvm_actor_anim");
		
		argumentstring = getDvar( "mvm_actor_anim", "Set the actor's animation" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
            {
				actor scriptModelPlayAnim(arguments[1]);
				actor.head scriptModelPlayAnim(arguments[1]);
				actor.assignedanim = arguments[1];
				self iPrintLn( "Animation ^3" + actor.assignedanim + "^7 set on ^3" + actor.name );
            }
        }
	}
}

DeathActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	self endon( "done" );
	
    self notifyOnPlayerCommand( "mvm_actor_death", "mvm_actor_death" );
    
	for (;;)
    {
        self waittill("mvm_actor_death");
		
		argumentstring = getDvar( "mvm_actor_death", "Set the actor's death animation" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
            {
				actor.deathanim = arguments[1];
				self iPrintLn( "Death animation ^3" + actor.deathanim + "^7 set on ^3" + actor.name );
            }
        }
	}
}

EquipActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_weapon", "mvm_actor_weapon" );
    
	for (;;)
    {
        self waittill("mvm_actor_weapon");
		
		argumentstring = getDvar( "mvm_actor_weapon", "Set the actor's equipement" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
            {			
					equ_angles = actor getTagAngles(arguments[1]);
					equ_origin = actor getTagOrigin(arguments[1]);
					actorWeaponHideTagList = GetWeaponHideTags( arguments[2] );

					if( isDefined(actor.equ[arguments[1]]))
					actor.equ[arguments[1]] delete();

					actor.equ[arguments[1]] = spawn("script_model", actor GetTagOrigin(arguments[1]));
					actor.equ[arguments[1]] linkTo( actor, arguments[1], (0,0,0), (0,0,0) );
					actor.equ[arguments[1]] setModel( (getWeaponModel( arguments[2] )) + GetCamoName( arguments[3] ) );
					for ( i = 0; i < actorWeaponHideTagList.size; i++ )
					{
						actor.equ[arguments[1]] HidePart( actorWeaponHideTagList[i], (getWeaponModel( arguments[2] )) + GetCamoName( arguments[3] ) );
					}
					
					self iPrintLn( "^3" + actor.name + "^7 now have ^3" + actor.PrimaryWeapon + "^7 attached to ^3" + arguments[1]);
            }
        }
	}
}


PathActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	self endon ("done");
	
    self notifyOnPlayerCommand( "mvm_actor_walk", "mvm_actor_walk" );
    
	for (;;)
    {
        self waittill("mvm_actor_walk");
	
		
		argumentstring = getDvar( "mvm_actor_walk", "Starts actor's path" );
        arguments = StrTok(argumentstring, " ,");
				
		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
            {
				time = int(arguments[1]);
				
				actor.oldorg = actor.origin;
				actor.oldang = actor.angles;
				target = [];
				
				
				if(arguments[2] == "forward")
				{
                    vec = anglestoforward(actor.angles);
                    target = (vec[0]*600, vec[1]*600, vec[2]*600);
				}
				else if(arguments[2] == "backward")
				{
                    vec = anglestoforward(actor.angles);
                    target = (vec[0]*-600, vec[1]*-600, vec[2]*-600);
				}
				else if(arguments[2] == "right")
				{
                    vec = anglestoright(actor.angles);
                    target = (vec[0]*600, vec[1]*600, vec[2]*600);
				}
				else if(arguments[2] == "left")
				{
                    vec = anglestoright(actor.angles);
                    target = (vec[0]*-600, vec[1]*-600, vec[2]*-600);
				}				
				
                actor MoveTo(actor.origin + target,time , 0, 0);
				
            }
        }
	}
}

MeeActor()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_move", "mvm_actor_move" );
    
	for (;;)
    {
        self waittill("mvm_actor_move");
				
		foreach( actor in level.actor ) 
        {
            if(actor.name == getDvar( "mvm_actor_move", "" ))
            {
				actor MoveTo(self.origin, 0.1, 0, 0);
				actor RotateTo(self.angles, 0.1, 0, 0);
				actor.oldorg = actor.origin;
				actor.oldang = actor.angles;
            }
        }
	}
}

ActorBack()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "actorback", "actorback" );
    
	for (;;)
    {
        self waittill("actorback");
				
		foreach( actor in level.actor ) 
        {
			actor.hitbox.health = actor.hitbox.savedhealth;
			actor MoveTo(actor.oldorg, 0.1, 0, 0);
			actor RotateTo(actor.oldang, 0.1, 0, 0);
			actor scriptModelPlayAnim(actor.assignedanim);
			actor.head scriptModelPlayAnim(actor.assignedanim);
			actor.hitbox thread ActorHandleDamage( actor.hitbox, actor );
        }
		self iPrintLn("Actors ^3reset ^7!");
	}
}

ActorGoPro()
{
    self endon( "disconnect" );
	self endon( "death" );
    self notifyOnPlayerCommand( "mvm_actor_gopro", "mvm_actor_gopro" );

	for (;;)
    {
        self waittill("mvm_actor_gopro");

		argumentstring = getDvar( "mvm_actor_gopro", "action actor tag x y z x y z" );
        arguments = StrTok(argumentstring, " ,");

		if( arguments[0] == "detach" )
		{
			level.goPro unlink();
			level.goPro.linked = 0;
			level.goPro MoveTo((9999,9999,9999), .1);
		}
		else if( arguments[0] == "on" )
		{
			self CameraLinkTo( level.goPro, "tag_origin" );
			setDvar( "cg_drawgun", 0 );
			setDvar( "cg_draw2d", 0 );
		}
		else if( arguments[0] == "off" )
		{
			self CameraUnlink();
			setDvar( "cg_drawgun", 1 );
			setDvar( "cg_draw2d", 1 );
		}
		else if( arguments[0] == "attach" )
		{
			foreach( actor in level.actor ) 
			{
				if(actor.name == arguments[1])
				{
					if( level.goPro.linked == 1)
					{
						level.goPro unlink();
						level.goPro.linked = 0;
					}
					level.goPro.origin = actor GetTagOrigin( arguments[2] );
					level.goPro.angles = actor GetTagAngles( arguments[2] );
					wait 0.05;
					level.goPro linkTo( actor, arguments[2], (int(arguments[3]), int(arguments[4]), int(arguments[5])), (int(arguments[6]), int(arguments[7]), int(arguments[8])) );
					level.goPro.linked = 1;
				}
			}
		}
	}
}


ActorSetPath()
{
    self endon( "disconnect" );
	self endon( "death" );
    self notifyOnPlayerCommand( "mvm_actor_node_save", "mvm_actor_node_save" );

	for (;;)
    {
        self waittill("mvm_actor_node_save");

		argumentstring = getDvar( "mvm_actor_node_save", "actor node - ^3Saves node for actor walk" );
        arguments = StrTok(argumentstring, " ,");

		if(int(arguments[1]) > 13)
			iPrintLn("^1ERROR ^7: Can only save node ^3#1 to ^3#13");
		else
		{
			foreach( actor in level.actor ) 
			{
				if(actor.name == arguments[0])
				{
					f = int(arguments[1]);
					actor.nodeorg[f] = self.origin;
					actor.nodeang[f] = self.angles;
					if(actor.nodecount <= f) actor.nodecount = f;


					if(isDefined(level.actorpath["node"][f])) level.actorpath["node"][f] delete();
					level.actorpath["node"][f] = spawn("script_model", self.origin);
					//level.actorpath["node"][f] setModel("projectile_stinger_missile");
					level.actorpath["node"][f].angles = self.angles;

					iPrintLn("Node ^3#" + arguments[1] +"^7 for ^3" + arguments[0] + "^7 set to : ^3" + actor.nodeorg[f] );
					self thread DeleteActorPath();
					wait .5;
					self thread UpdateActorPath(actor);
									
				}
			}
		}
		
	}
}

ActorDeletePath()
{
    self endon( "death" );
    self endon( "disconnect" );
	
    self notifyOnPlayerCommand( "mvm_actor_node_del", "mvm_actor_node_del" );
    
	for (;;)
    {
        self waittill("mvm_actor_node_del");

		argumentstring = getDvar( "mvm_actor_node_del", "actor node - ^3Saves node for actor walk" );
        arguments = StrTok(argumentstring, " ,");
		
		foreach( actor in level.actor ) 
		{
			if(actor.name == arguments[0])
			{
				d = arguments[1];
				f = int(arguments[1]);

				self DeleteActorPath();
				
				if( actor.nodecount == 0 ) 
					self IPrintLn("There's nothing to delete");
				else if( d == "all" || f == 1)
				{		
					for (i=0 ; i<=actor.nodecount ; i++)
					{
						actor.nodeorg[i] = undefined;
						actor.nodeang[i] = undefined;
					}
					self iPrintLn( "^3All ^7positions ^3deleted^7!" );
					actor.nodecount = 0;
				}
				else if( f > 0 )
				{		
					for (i=f ; i<=actor.nodecount ; i++)
					{
						actor.nodeorg[i] = undefined;
						actor.nodeang[i] = undefined;
					}
					actor.nodecount = f-1;
					self UpdateActorPath(actor);
					self iPrintLn( "Position number ^3" + f + " ^7and above ^3deleted^7!" );
				}

				else self IPrintLn("^1Looks like you typed something wrong");
			}
		}
		wait .1;
	}
}

DeleteActorPath()
{
	foreach( actorpath in level.actorpath )
	{
		actorpath["path"] delete();
		actorpath["node"] delete();
	}
}

HideActorPath()
{
	foreach( actorpath in level.actorpath )
	{
		actorpath["path"] hide();
		actorpath["node"] hide();
	}
}

ShowActorPath()
{
	foreach( actorpath in level.actorpath )
	{
		actorpath["path"] show();
		actorpath["node"] show();
	}
}

UpdateActorPath(actor) 
{
	
	level.actorpath["path"] = [];
	level.actorpathtotal = 0;

	level.actorpathsteps = (2000 * actor.nodecount/400);
	for(j = 0; j < (level.actorpathsteps) ; j++)
	{
		t = j/(level.actorpathsteps - 1);
		vect[0]  = 0; vect[1]  = 0; vect[2]  = 0;
		angle[0] = 0; angle[1] = 0; angle[2] = 0;

		for(i=1 ; i<=actor.nodecount ; i++)
		{
			for(z = 0; z < 3; z++)
			{
				vect[z]  +=float(koeff(i-1,actor.nodecount-1)*pow((1-t),actor.nodecount-i)*pow(t,i-1)*actor.nodeorg[i][z]);
				angle[z] +=float(koeff(i-1,actor.nodecount-1)*pow((1-t),actor.nodecount-i)*pow(t,i-1)*actor.nodeang[i][z]);
			}
		}
		level.actorpath[level.actorpathtotal]["path"] = spawn( "script_model", (vect[0],vect[1],vect[2]) );
		level.actorpath[level.actorpathtotal]["path"] setModel( "projectile_m67fraggrenade_bombsquad" );
		level.actorpath[level.actorpathtotal]["path"].angles = (angle[0],angle[1],angle[2]);
		level.actorpathtotal++;
	}
	
}

ActorDoPath()
{
    self endon( "disconnect" );
    self notifyOnPlayerCommand( "mvm_actor_node_walk", "mvm_actor_node_walk" );

	for (;;)
    {
        self waittill("mvm_actor_node_walk");

		argumentstring = getDvar( "mvm_actor_node_walk", "actor speed - ^3haha" );
        arguments = StrTok(argumentstring, " ,");
        setDvar("arg_actorname", arguments[0]);
        setDvar("arg_walkspeed", arguments[1]);

		foreach( actor in level.actor ) 
        {
            if(actor.name == arguments[0])
            {
				actor SetOrigin(self.actororgstart);
				actor SetPlayerAngles(self.actorangstart);
				wait .1;
				HideActorPath();
				actor MoveTo(actor.nodeorg[1], 0.1, 0, 0);
				actor RotateTo(actor.nodeang[1], 0.1, 0, 0);
				actor PreparePath(actor);
				wait 2;
				actor ActorDoWalk(actor, int(arguments[1]));
				ShowActorPath();
				
            }
        }
	}
}

PathDebug()
{
	if( !isDefined(self.actororgstart) )
	{
        self.actororgstart = self GetOrigin();
        self.actorangstart = (0,360,0);
        level.cam["poscount"] = 0;
	}
}


PreparePath(actor) 
{
	level.alldist = 0;
	for(k=1; k<actor.nodecount; k++)
	{
		x=actor.nodeang[k][1];
		y=actor.nodeang[k+1][1];
		
		if(y - x >= 180)
		{
		 actor.nodeang[k]+=(0,360,0);
		}

		else if(y - x <= -180)
		{
		 actor.nodeang[k+1]+=(0,360,0);
		}

		level.partdist[k] = distance(actor.nodeorg[k], actor.nodeorg[k+1] );
		level.angledist[k] = distance(actor.nodeang[k], actor.nodeang[k+1]);
		level.alldist+=level.partdist[k];
		level.alldist+=level.angledist[k];
	}
}

ActorDoWalk(actor, speed)
{
	dist = level.alldist;
	level.multiplier = getDvarint("sv_fps") / 100 ;
	
	for(j = 0; j <= dist*10*level.multiplier/speed ; j++)
	{
		t = (j*speed/(dist * 10 * level.multiplier));
		vect[0]  = 0; vect[1]  = 0; vect[2]  = 0;
		angle[0] = 0; angle[1] = 0; angle[2] = 0;

		for(i=1 ; i<=actor.nodecount ; i++)
		{
			for(z = 0; z < 3; z++)
			{
				vect[z]  +=float(koeff(i-1,actor.nodecount-1)*pow((1-t),actor.nodecount-i)*pow(t,i-1)*actor.nodeorg[i][z]);
				angle[z] +=float(koeff(i-1,actor.nodecount-1)*pow((1-t),actor.nodecount-i)*pow(t,i-1)*actor.nodeang[i][z]);
			}
		}
		actor MoveTo((vect[0],vect[1],vect[2]), .1, 0, 0);
		actor RotateTo((angle[0],angle[1],angle[2]), .1, 0, 0);
		wait .01;
	}
	wait 0.1;
}

float(var) {
  	setDvar("temp",var);
  	return getDvarfloat("temp");
}

koeff(x,y){
	return (fact(y)/(fact(x)*fact(y-x)));
}

fact(x){
	c=1;
	if(x==0) return 1;
	for(i=1;i<=x;i++)
		c=c*i;
	return c;
}

pow(a,b){
  	x=1;
  	if(b!=0){
  		for(i=1;i<=b;i++)
  			x=x*a;
  	}
  	return x;
}