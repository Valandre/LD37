package;
import hxd.Key in K;

private class Button extends h2d.Flow {
	var game : Game;
	public var selected(default, set) = false;
	public var tiles = [];
	public var bt : h2d.Bitmap;
	var str : String;

	public function new (name : String, ?parent : h2d.Sprite) {
		super(parent);
		game = Game.inst;

		str = name;

		switch(name) {
			case "BACK":
				tiles.push(hxd.Res.UI.Bt_Back0.toTile());
				tiles.push(hxd.Res.UI.Bt_Back1.toTile());
		}

		bt = new h2d.Bitmap(tiles[0], this);
		bt.blendMode = Alpha;
		enableInteractive = true;
	}

	function onOver() {
		bt.tile = tiles[1];
	}

	function onOut() {
		bt.tile = tiles[0];
	}

	public function onclick() {
		interactive.onClick(null);
	}

	public function setAlpha(v : Float) {
		bt.alpha = v;
	}

	function set_selected(b : Bool) {
		if(b) onOver();
		else onOut();
		return selected = b;
	}
}

class Win extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var bmpwin : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;

	var buttons : Array<Button> = [];
	public var choose : ChoosePlayers;
	var title : h2d.Bitmap;
	var cont : h2d.Flow;
	var lock = false;

	public function new(?parent) {
		super(parent);
		game = Game.inst;

		bg = new h2d.Bitmap(hxd.Res.UI.Bg01.toTile(), this);
		bg.blendMode = Add;
		bg.filter = true;

		title = new h2d.Bitmap(hxd.Res.UI.Title.toTile(), this);
		title.blendMode = Alpha;
		title.filter = true;
		title.x = 50;
		title.y = 50;

		root = new h2d.Flow(this);
		root.horizontalAlign = Middle;
		root.verticalAlign = Middle;
		root.verticalSpacing = 5;
		root.isVertical = true;

		game.setAmbient(1);
		init();
	}

	function init() {

		cont = new h2d.Flow(root);
		cont.horizontalAlign = Middle;
		cont.verticalAlign = Middle;
		cont.verticalSpacing = 30;
		cont.isVertical = true;
		cont.paddingLeft = 170;
		cont.paddingTop = 300;

		var back = new Button("BACK", cont);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				game.choose();
				remove();
			});
		}
		buttons.push(back);

		select(selectId);
		onResize();
		slideIn();

		var id = 0;
		var n = 0;
		for(i in 0...game.stars.length)
			if(game.stars[i] > n){
				id = i + 1;
				n = game.stars[i];
			}

		var e = new ent.Player(new h3d.col.Point(0, 0, 1), 1, id);
		e.x = 3;
		e.y = -2;
		e.play("stand");
		var p = game.s3d.camera.pos;
		@:privateAccess e.fxParts.get("ElfHead").z += 1;
		@:privateAccess e.fxParts.get("ElfHead").x -= 0.5;
		@:privateAccess e.obj.currentAnimation.setFrame(Math.random() * (e.obj.currentAnimation.frameCount - 1));
		@:privateAccess e.light.params = new h3d.Vector(0.8, 0.5, 0.1);
		@:privateAccess e.obj.setScale(1.5);
		game.players.push(e);


		var t = hxd.Res.UI.Winner.toTile();
		bmpwin = new h2d.Bitmap(t);
		bmpwin.filter = true;
		bmpwin.x = -t.width;
		bmpwin.y = 50;
		bmpwin.blendMode = Alpha;
		addChildAt(bmpwin, 0);
		var to = game.s2d.width * 0.5;

		game.event.wait(1, function() {
			game.event.waitUntil(function(dt) {
				bmpwin.x += (to - bmpwin.x) * 0.25 * dt;
				if(Math.abs(to - bmpwin.x) < 1) {
					var c = 1.;
					bmpwin.colorAdd = new h3d.Vector(c, c, c);
					game.event.waitUntil(function(dt) {
						c -= 0.05 * dt;
						bmpwin.colorAdd.x = bmpwin.colorAdd.y = bmpwin.colorAdd.y = c;
						if(c <= 0) {
							bmpwin.colorAdd = null;
							return true;
						}
						return false;
					});
					return true;
				}
				return false;
			});
		});
	}

	function slideOut(?onEnd : Void -> Void) {
		var bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF));
		bmp.scaleY = game.s2d.height;
		addChildAt(bmp, 0);

		var a = 1.;
		var sp = 10.;
		game.event.waitUntil(function(dt){
			a = Math.max(0, a - 0.1 * dt);
			title.alpha = a;
			for(b in buttons)
				b.setAlpha(a);
			bmpwin.alpha = a;
			bg.x += sp;
			sp += 15;
			bmp.scaleX = bg.x;
			if(bmp.scaleX > game.s2d.width) {
				cont.visible = false;
				bmp.remove();
				bg.visible = false;
				if(onEnd != null) onEnd();
				return true;
			}
			return false;
		});
	}

	function slideIn(?onEnd : Void -> Void) {
		bg.x = game.s2d.width + 100;
		bg.visible = true;
		cont.visible = true;
		title.alpha = 0;
		for( b in buttons)
			b.setAlpha(0);

		var bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF));
		addChildAt(bmp, 0);
		bmp.scaleX = bg.x;
		bmp.scaleY = game.s2d.height;

		var sp = 10.;
		game.event.waitUntil(function(dt){
			bg.x -= sp;
			sp += 15;
			bmp.scaleX = bg.x;
			if(bmp.scaleX <= 0) {
				bg.x = 0;
				bmp.remove();
				var a = 0.;
				game.event.waitUntil(function(dt){
					a = Math.min(1, a + 0.1 * dt);
					title.alpha = a;
					for(b in buttons)
						b.setAlpha(a);
					if(a == 1) {
						if(onEnd != null) onEnd();
						return true;
					}
					return false;
				});
				return true;
			}
			return false;
		});
	}

	function select(id : Int) {
		for( b in buttons)
			b.selected = false;
		buttons[id].selected = true;
	}

	public function onResize() {
		var sc = game.s2d.height / bg.tile.height;
		bg.setScale(sc);

		root.minWidth = root.maxWidth = Std.int(bg.scaleX);
		root.minHeight = root.maxHeight = game.s2d.height;
		root.needReflow = true;

		title.setScale(sc);

		cont.paddingLeft = Std.int(170 * sc);
		cont.paddingTop = Std.int(300 * sc);

		if(choose != null)
			choose.onResize();
	}

	public function update(dt : Float) {
		if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE) || (game.keys != null && game.keys.pressed.A)) {
			Sounds.play("Select");
			buttons[selectId].onclick();
		}
	}
}