package ui;
import hxd.Key in K;
import Sounds;

class ChooseArena extends ui.Form
{
	var players = [];
	var contRight : h2d.Flow;

	public function new(?parent) {
		super(parent);
		game.setAmbient(1);
	}

	override function init() {
		super.init();

		game.state.arenaId = 0;

		var next = addButton("START", cont);
		next.interactive.onClick = function(e) {
			slideOut(function() {
				remove();
				game.restart();
			});
		}

		var back = addButton("BACK", cont);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				new ui.ChoosePlayers();
				remove();
			});
		}
	}

	override function update(dt : Float) {
		super.update(dt);
	}
}