package ui;

enum ButtonKind {
	MainMenu;
	CharSelect;
	ArenaSelect;
}

class MenuButton extends h2d.Sprite
{
	public var enable(default, set) : Bool;
	public var selected(default, set) : Bool;

	var game : Game;
	var tiles : Array<h2d.Tile> = [];
	var bg : h2d.Bitmap;
	var title : h2d.Text;
	var kind : ButtonKind;

	var root : h2d.Sprite;

	public function new(str : String, kind : ButtonKind, ?parent) {
		super(parent);
		game = Game.inst;
		this.kind = kind;

		root = new h2d.Sprite(this);

		var t = switch(kind) {
			case MainMenu : hxd.Res.UI.v2.menuButton.toTile();
			case CharSelect : hxd.Res.UI.v2.charButton.toTile();
			case ArenaSelect : hxd.Res.UI.v2.arenaButton.toTile();
			default: throw "TODO";
		}

		var size = t.height;
		tiles = t.gridFlatten(size, -size >> 1, -size >> 1);
		bg = new h2d.Bitmap(tiles[0], root);
		bg.smooth = true;
		bg.rotation = -Math.PI * 0.25;

		title = game.text(str, root);
		title.x = -title.textWidth >> 1;
		title.y = -title.textHeight >> 1;
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