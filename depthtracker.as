
package flash
{

	import flash.utils.Dictionary;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.display.DisplayObject;
	import flash.display.BitmapData;
    import flash.geom.Transform;
    import flash.geom.Matrix;
	
	public class StatsTracker {
		public var maxval:Number = 0;
		public var minval:Number = 0;
		public var avgval:Number = 0;
		//public var scaledDepth:Number = 0;
		public var maxtime:Number = 0;
		public var mintime:Number = 0;
		public var lasttime:Number = (new Date()).getTime()/1000.0;
	}


    public dynamic class Main extends flash.display.MovieClip
    {

		var main;
		var g;
		var her;
		const modname : String = "depthtracker"
		var deepestyet:Number = 0.0;
		var recentdeepest3:StatsTracker = new StatsTracker();
		var recentdeepest5:StatsTracker = new StatsTracker();
		var recentdeepest15:StatsTracker = new StatsTracker();
		var recentdeepest60:StatsTracker = new StatsTracker();
		var recentvigour3:StatsTracker = new StatsTracker();
		var recentvigour5:StatsTracker = new StatsTracker();
		var recentvigour15:StatsTracker = new StatsTracker();
		var recentvigour60:StatsTracker = new StatsTracker();
		var lasthilt:Number = 0;
		var contactdist:Number = 0.8;
		var lastpos:Number = 0;

		public function initl(l)
		{
			main = l;
			g = l.g;
			her = l.her;
			//var modSettingsLoader = main.eDOM.getDefinition("Modules.modSettingsLoader") as Class;			//finds the modsettingsloader class from the loader
			//var mySettingsLoader = new modSettingsLoader(modname+"settings",onSettingsSucceed);	//creates a new settingsloader specifying the file to load and the funtion to run
			//mySettingsLoader.addEventListener("settingsNotFound",onSettingsFail);						//adds an event listener in case the settings file is failed to be found/loaded

			g.dialogueControl.advancedController._dialogueDataStore["dt_recentdepth"] = 7;
			//this.addEventListener(Event.ENTER_FRAME, doUpdate);
			main.addEnterFramePersist(doUpdate);
			//main.addEventListener(Event.ENTER_FRAME, doUpdate);
			//main.addEnterFrame(doUpdate);

			g.dialogueControl.advancedController._dialogueDataStore["dt_deepestyet"] = deepestyet;
			g.dialogueControl.advancedController._dialogueDataStore["dt_lasthilt"] = lasthilt;
			//g.her.VIGOUR_WINCE_LEVEL=0;
		}
			
		/** function registered to run when the settings file is done loading into flash **/
		function onSettingsSucceed(e)			
		{
			finishinit();
		}
		
		/** function registered to run when the settings file fails to load **/
		function onSettingsFail(e)			
		{
			main.updateStatusCol(e.msg,"#FF0000");		//displays error message
			finishinit();
		}
			
		function finishinit()
		{		
			//main.unloadMod();
		}

		function calcStats(val:Number, now_seconds:Number, stat:StatsTracker, maxage:Number, name:String)
		{
			var decay = 100.0 / maxage;
			var maxval_age = (now_seconds-stat.maxtime);
			var maxweighting = 1.0 - maxval_age / decay;
			var weighted_max = stat.maxval * maxweighting;
			
			if(val > weighted_max || now_seconds > stat.maxtime + maxage) {
				stat.maxval=val;
				stat.maxtime=now_seconds;
			}

			var minval_age = (now_seconds-stat.mintime);
			var minweighting = 1.0 - minval_age / decay;
			var weighted_min = stat.minval * minweighting;

			if(val < weighted_min || now_seconds > stat.mintime + maxage) {
				stat.minval=val;
				stat.mintime=now_seconds;
			}

			var deltaTime = now_seconds - stat.lasttime;
			if(deltaTime > 0.5 || isNaN(deltaTime) ) {
				deltaTime = 0.5;
			}
			if(deltaTime > 0.1) {
				stat.avgval -= stat.avgval / maxage * deltaTime;
				stat.avgval += val / maxage * deltaTime;
				stat.lasttime = now_seconds;
			}

			//g.dialogueControl.advancedController._dialogueDataStore["dt_recentdeepestweighted"+String(maxage)] = weighted_max;
			g.dialogueControl.advancedController._dialogueDataStore[name+"_max"+String(maxage)] = stat.maxval;
			g.dialogueControl.advancedController._dialogueDataStore[name+"_maxtime"+String(maxage)] = stat.maxtime;
			g.dialogueControl.advancedController._dialogueDataStore[name+"_min"+String(maxage)] = stat.minval;
			g.dialogueControl.advancedController._dialogueDataStore[name+"_mintime"+String(maxage)] = stat.mintime;
			g.dialogueControl.advancedController._dialogueDataStore[name+"_avg"+String(maxage)] = stat.avgval;
		}
		
		function doUpdate(a)
		{
			//if(g.her.VIGOUR_WINCE_LEVEL<1000) throw new Error("her wince level == "+String(g.her.VIGOUR_WINCE_LEVEL));
			var herpos:Number = g.her.pos;
			var contact:Boolean = testhitpoints();
			if(contact==false && herpos > contactdist) {
				contactdist = 0.8;
			}
			if(contact==true) {
				contactdist = Math.min(contactdist, Math.min((herpos+lastpos)/2.0, herpos) );
			}
			lastpos = herpos;
			herpos = (herpos-contactdist) / (1-contactdist);

			var herpos_scaled:Number = herpos * g.him.penis.scaleX;
			var vigour:Number = Math.min(1.0, g.her.vigour / 1000.0);//seems like vigour can go over 1 sometimes?
			var now:Date = new Date();
			var now_seconds:Number = now.getTime()/1000.0;
			g.dialogueControl.advancedController._dialogueDataStore["dt_time"] = now_seconds;
			g.dialogueControl.advancedController._dialogueDataStore["dt_penislength"] = g.him.penis.scaleX;
			g.dialogueControl.advancedController._dialogueDataStore["dt_penisgirth"] = g.him.penis.scaleY;
			g.dialogueControl.advancedController._dialogueDataStore["dt_herpos"] = herpos;
			g.dialogueControl.advancedController._dialogueDataStore["dt_contact"] = contact;//for debugging
			g.dialogueControl.advancedController._dialogueDataStore["dt_contactdist"] = contactdist;//for debugging

			calcStats(herpos_scaled, now_seconds, recentdeepest3, 3, "dt_depth");
			calcStats(herpos_scaled, now_seconds, recentdeepest5, 5, "dt_depth");
			calcStats(herpos_scaled, now_seconds, recentdeepest15, 15, "dt_depth");
			calcStats(herpos_scaled, now_seconds, recentdeepest60, 60, "dt_depth");//this could be error-prone with changing dialogs, characters, and positions...

			calcStats(vigour, now_seconds, recentvigour3, 3, "dt_vigour");
			calcStats(vigour, now_seconds, recentvigour5, 5, "dt_vigour");
			calcStats(vigour, now_seconds, recentvigour15, 15, "dt_vigour");
			calcStats(vigour, now_seconds, recentvigour60, 60, "dt_vigour");

			if(herpos > deepestyet) {
				deepestyet = herpos;
				g.dialogueControl.advancedController._dialogueDataStore["dt_deepestyet"] = deepestyet;
			}
			if(herpos > 0.99) {
				lasthilt = now_seconds;
				g.dialogueControl.advancedController._dialogueDataStore["dt_lasthilt"] = lasthilt;
			}
		}

		function checkPointInHer(ax:Number, ay:Number) : Boolean
		{
			/*if(g.her.torso.hitTestPoint(ax,ay, true)) { return true;}
			if(g.her.torsoBack.hitTestPoint(ax,ay, true)) { return true;}
			if(g.her.leftLegContainer.hitTestPoint(ax,ay, true)) { return true;}
			return false;*/

			if(g.her.torso.midLayer.chest.hitTestPoint(ax,ay, true)) { return true;}   //changed this after v13 probably cause would trigger on arms, reverted V14 cause wouldn't do it for front chest
			if(g.her.torso.backside.hitTestPoint(ax,ay, true)) { return true;}
			if(g.her.torso.back.hitTestPoint(ax,ay, true)) { return true;}
			//if(g.her.torso.midLayer.hitTestPoint(ax,ay, true)) { return true;}   //changed this after v13 probably cause would trigger on arms, reverted V14 cause wouldn't do it for front chest
			
			//if(g.her.head.hitTestPoint(ax,ay, true)) { return true;}
			if(g.her.torso.leg.thigh.hitTestPoint(ax,ay, true)) { return true;}
			if(g.her.leftLegContainer.leg.thigh.hitTestPoint(ax,ay, true)) { return true;}
			//if(g.her.torso.rightCalfContainer.calf.hitTestPoint(ax,ay, true)) {return true;}
			//if(g.her.torsoBack.leftBreast.getChildAt(0).hitTestPoint(ax,ay, true)) { return true;}

			return false;
		}

		function listchildren(p) : String
		{

			var names:String = "";
			try {
				names += "<"+p.name+">";
				try {
				for (var i:uint = 0; i < p.numChildren; i++)
					names += listchildren(p.getChildAt(i));
				} catch(e:Error) {}
				names += "</"+p.name+">";
			} catch(error:Error) {}
			return names;
		}
        
		/*
		//https://forums.adobe.com/thread/873737
        private function checkForHit(a:BitmapData,b:BitmapData):Boolean {
            return a.hitTest(new Point(0,0),0xff,b,new Point(0,0),0xff);
        }
        
        private function createBitmapData(a:DisplayObject):BitmapData {
			var bmpd:BitmapData = new BitmapData(a.stage.stageWidth,a.stage.stageHeight,true,0x000000ff);
			var currentTrans:Transform = a.transform;
			var currentMat:Matrix = currentTrans.concatenatedMatrix;
			bmpd.draw(a,currentMat);
			return bmpd;
        }
		*/

		function testhitpoints() : Boolean
		{
			/*var penisBmp:BitmapData = createBitmapData(g.him.penis);
			var herBacksideBmp:BitmapData = createBitmapData(g.her.torso.backside);
			var herBackBmp:BitmapData = createBitmapData(g.her.torsoBack);

			if(checkForHit(penisBmp, herBacksideBmp)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her backside"; return true; }
			if(checkForHit(penisBmp, herBackBmp)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her back"; return true; }

			return false;*/

			/*if(g.her.torso.backside.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her.torso.backside"; return true; }
			if(g.her.torsoBack.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her.torsoBack"; return true; }
			//if(g.her.leftLegContainer.leg.thigh.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her.leftLegContainer.leg.thigh"; return true; }
			//if(g.her.torso.leg.thigh.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="her.torso.leg.thigh"; return true; }
			return false;*/

			var ax:Number = g.him.getPenisTipPoint().x;
			var ay:Number = g.him.getPenisTipPoint().y;

			//throw new Error(listchildren(g.him));
			//g.dialogueControl.advancedController._dialogueDataStore["dt_names"] = listchildren(g.him);

			if( checkPointInHer(ax, ay) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="tip"; return true; }

			var penisRect = g.him.penis.getRect(this);
			var topLeft = /*g.him.penis.localToGlobal*/(penisRect.topLeft);
			var bottomRight = /*g.him.penis.localToGlobal*/(penisRect.bottomRight);
			var midX:Number = (topLeft.x + bottomRight.x) / 2;
			var midY:Number = (topLeft.y + bottomRight.y) / 2;
			var frontX:Number = (midX + ax + ax) / 3;
			var backX:Number = midX - (ax - midX);
			backX = (midX + backX + backX) / 3;
			var frontY:Number = (midY + ay + ay) / 3;
			var backY:Number = midY - (ay - midY);
			backY = (midY + backY + backY) / 3;

			//g.dialogueControl.advancedController._dialogueDataStore["dt_debug"] = "ax:"+ax.toFixed(2)+", ay:"+ay.toFixed(2)+", midX:"+midX.toFixed(2)+", midY:"+midY.toFixed(2)+", penis:"+topLeft.toString()+", "+bottomRight.toString();

			if( checkPointInHer(midX, midY) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="penismid"; return true; }
			if( checkPointInHer(frontX, frontY) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="penisfront"; return true; }
			//if( checkPointInHer(ax, midY) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="penismix"; return true; }
			//if( checkPointInHer(midX, ay) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="penismix"; return true; }
			//if( checkPointInHer(backX, backY) ) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="penisback"; return true; }

			//if(g.her.head.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="head"; return true; }
			//if(g.her.torsoBack.chestBack.hitTestObject(g.him.penis)) { g.dialogueControl.advancedController._dialogueDataStore["dt_col"]="torsoBack.chestBack"; return true; }

			return false;
	
			//
			//else if(g.her.torso.topContainer.hitTestPoint(ax,ay, true)) return true;
			//
			//
			//else if(g.her.torsoBack.backside.hitTestPoint(ax,ay, true)) return true;
			//else if(g.her.torsoBack.chestBack.hitTestPoint(ax,ay, true)) return true;
	
			//else if(g.her.leftLegContainer.hitTestPoint(ax,ay, true)) return true;		//meh
			//else if(g.her.rightArmContainer.hitTestPoint(ax,ay, true)) return true;		//probably don't want this
			//else if(g.her.torso.midLayer.leftArm.hitTestPoint(ax,ay, true)) return true; 	//dont add
		}

		function doUnload()
		{
			//cMC.removeEventListener(Event.ENTER_FRAME, doUpdate);
		}
		
    }
}

