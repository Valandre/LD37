package ui;
import hxd.Key in K;
import Sounds;

class ChooseArena extends ui.Form
{
	var players = [];
	var contRight : h2d.Flow;
	var onRemove : Bool -> Void;

	public function new(?parent, onRemove : Bool -> Void ) {
		super(parent);

		this.onRemove = onRemove;
		game.setAmbient(1);
	}

	override function init() {
		super.init();

		game.arenaId = 0;

		var next = addButton("START", cont);
		next.interactive.onClick = function(e) {
			slideOut(function() {
				remove();
				onRemove(true);
				game.restart();
			});
		}

		var back = addButton("BACK", cont);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				onRemove(false);
				remove();
			});
		}
	}

	override function update(dt : Float) {
		super.update(dt);
	}
}