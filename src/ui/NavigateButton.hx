package ui;

class NavigateButton extends h2d.Sprite
{
	public var enable(default, set) : Bool;
	public var selected(default, set) : Bool;

	var game : Game;
	var tiles : Array<h2d.Tile> = [];
	var bg : h2d.Bitmap;
	var title : h2d.Text;

	var root : h2d.Sprite;

	public function new(str : String, ?parent) {
		super(parent);
		game = Game.inst;

		root = new h2d.Sprite(this);

		var t = hxd.Res.UI.v2.navigateButton.toTile();
		var size = t.height;
		tiles = t.gridFlatten(size, -size >> 1, -size >> 1);
		bg = new h2d.Bitmap(tiles[0], root);
		bg.rotation = Math.PI * 0.25;

		title = game.text(str, root);
		title.x = 5;
		title.y = -14 - title.textHeight >> 1;
		title.smooth = true;
	}

	function set_enable(b : Bool) {
		if(b) {
			if(selected)
				bg.tile = tiles[1];
			else bg.tile = tiles[0];
			title.alpha = 1;
		}
		else {
			bg.tile = tiles[2];
			title.alpha = 0.5;
		}
		return enable = b;
	}


	function set_selected(b : Bool) {
		if(b) {
			bg.tile = tiles[1];
			scaleTo(1.08);
		}
		else {
			bg.tile = tiles[0];
			scaleTo(1);
		}
		return selected = b;
	}

	function scaleTo(v : Float) {
		var sc = scaleX;
		game.event.waitUntil(function(dt) {
			sc += (v - sc) * 0.3 * dt;
			setScale(sc);

			if(Math.abs(v - sc) < 0.01) {
				setScale(v);
				return true;
			}
			return false;
		});
	}

	dynamic public function onClick() {

	}

}