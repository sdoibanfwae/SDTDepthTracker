
package flash
{


	import flash.utils.Dictionary;
	import flash.events.MouseEvent;
	import flash.events.Event;
	
	public class RecentDeepest {
		public var depth:Number = 0;
		//public var scaledDepth:Number = 0;
		public var time:Number = 0;
	}


    public dynamic class Main extends flash.display.MovieClip
    {

		var main;
		var g;
		var her;
		const modname : String = "depthtracker"
		var deepestyet:Number = 0.0;
		var recentdeepest3:RecentDeepest = new RecentDeepest();
		var recentdeepest5:RecentDeepest = new RecentDeepest();
		var recentdeepest60:RecentDeepest = new RecentDeepest();
		var lasthilt:Number = 0;

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

		function recentDeepest(herpos, now_seconds, recentdeepest:RecentDeepest, maxage:int)
		{
			herpos *= g.him.penis.scaleX;
			var recentdeepest_age = (now_seconds-recentdeepest.time);
			var decay = 100 / maxage;
			var recentdeepest_weighting = 1.0 - recentdeepest_age / decay;
			var weighted_recentdeepest = recentdeepest.depth * recentdeepest_weighting;
			
			if(herpos > weighted_recentdeepest || now_seconds > recentdeepest.time + maxage) {
				recentdeepest.depth=herpos;
				recentdeepest.time=now_seconds;
			}

			g.dialogueControl.advancedController._dialogueDataStore["dt_recentdeepest"+String(maxage)] = recentdeepest.depth;
			g.dialogueControl.advancedController._dialogueDataStore["dt_recentdeepestweighted"+String(maxage)] = weighted_recentdeepest;
			g.dialogueControl.advancedController._dialogueDataStore["dt_recentdeepesttime"+String(maxage)] = recentdeepest.time;
		}
		
		function doUpdate(a)
		{
			var herpos = g.her.pos;
			var now:Date = new Date();
			var now_seconds = now.getTime()/1000;
			g.dialogueControl.advancedController._dialogueDataStore["dt_time"] = now_seconds;
			g.dialogueControl.advancedController._dialogueDataStore["dt_penislength"] = g.him.penis.scaleX;
			g.dialogueControl.advancedController._dialogueDataStore["dt_penisgirth"] = g.him.penis.scaleY;
			g.dialogueControl.advancedController._dialogueDataStore["dt_herpos"] = herpos;

			recentDeepest(herpos, now_seconds, recentdeepest3, 3);
			recentDeepest(herpos, now_seconds, recentdeepest5, 5);
			recentDeepest(herpos, now_seconds, recentdeepest60, 60);//this could be error-prone with changing dialogs, characters, and positions...

			if(herpos > deepestyet) {
				deepestyet = herpos;
			}
			g.dialogueControl.advancedController._dialogueDataStore["dt_deepestyet"] = deepestyet;
			if(herpos > 0.99) {
				lasthilt = now_seconds;
			}
			g.dialogueControl.advancedController._dialogueDataStore["dt_lasthilt"] = lasthilt;
		}

		function doUnload()
		{
			//cMC.removeEventListener(Event.ENTER_FRAME, doUpdate);
		}
		
    }
}

