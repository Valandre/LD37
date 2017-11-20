package ui;
import hxd.Key in K;
//import Sounds;

class Win extends ui.Form
{
	override function init() {
		super.init();
		//addBg();
		//game.setAmbient(1);
	}

	override function update(dt : Float) {
		super.update(dt);

		/*
		var c = game.controllers[0];
		if(c != null) {
			c.active = true;
			if(c.pressed.A) {
				new ui.ChoosePlayers();
				remove();
			}
		}*/
		new ui.ChoosePlayers();
		remove();

	}
}