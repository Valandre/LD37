package ui;


class MenuButton extends h2d.Sprite
{
	public var enable(default, set) : Bool;
	public var selected(default, set) : Bool;

	var game : Game;
	var tiles : Array<h2d.Tile> = [];
	var bg : h2d.Bitmap;
	var title : h2d.Text;

	var root : h2d.Sprite;
	var scaleOffset : Int;
	var size = 256;

	public function new(str : String, scaleOffset, ?parent) {
		super(parent);
		game = Game.inst;

		this.scaleOffset = scaleOffset;

		root = new h2d.Sprite(this);

		tiles = hxd.Res.UI.menuButton.toTile().gridFlatten(size, -size >> 1, -size >> 1);
		bg = new h2d.Bitmap(tiles[0], root);
		bg.filter = true;
		bg.rotation = -Math.PI * 0.25;

		title = game.text(str, root);
		title.x = -title.textWidth >> 1;
		title.y = -title.textHeight >> 1;
		title.filter = true;
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
			scaleTo(1.15);
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
			root.y = (size >> 1) * 1.4 * scaleOffset * (1 - sc);

			if(Math.abs(v - sc) < 0.01) {
				setScale(v);
				root.y = (size >> 1) * 1.4 * scaleOffset * (1 - sc);
				return true;
			}
			return false;
		});
	}

	public function onResize() {

	}

}