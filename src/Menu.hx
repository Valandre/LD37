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
			case "START":
				tiles.push(hxd.Res.UI.Bt_Start0.toTile());
				tiles.push(hxd.Res.UI.Bt_Start1.toTile());
			case "SOUND":
				tiles.push(hxd.Res.UI.Bt_SoundOn0.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOn1.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOff0.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOff1.toTile());
			case "CREDITS":
				tiles.push(hxd.Res.UI.Bt_Credits0.toTile());
				tiles.push(hxd.Res.UI.Bt_Credits1.toTile());
			case "EXIT":
				tiles.push(hxd.Res.UI.Bt_Exit0.toTile());
				tiles.push(hxd.Res.UI.Bt_Exit1.toTile());
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

class Menu extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;

	var buttons : Array<Button> = [];
	var choose : ChoosePlayers;
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

		init();

		//hxd.Pad.wait(function(p) trace(p));
	}

	function init() {
		cont = new h2d.Flow(root);
		cont.horizontalAlign = Middle;
		cont.verticalAlign = Middle;
		cont.verticalSpacing = 30;
		cont.isVertical = true;
		cont.paddingLeft = 170;
		cont.paddingTop = 300;

		var start = new Button("START", cont);
		start.interactive.onClick = function(e) {
			slideOut(function() {
				choose = new ChoosePlayers(game.s2d, function(start : Bool) {
					lock = start;
					choose = null;
					slideIn();
				});
			});
		}
		buttons.push(start);


		var sound = new Button("SOUND", cont);
		sound.interactive.onClick = function(e) {
			sound.tiles.push(sound.tiles.shift());
			sound.tiles.push(sound.tiles.shift());
			sound.bt.tile = sound.tiles[1];
		};
		buttons.push(sound);

		var credits = new Button("CREDITS", cont);
		credits.interactive.onClick = function(e){};
		buttons.push(credits);

		var exit = new Button("EXIT", cont);
		exit.interactive.onClick = function(e) hxd.System.exit();
		buttons.push(exit);

		select(selectId);
		onResize();
		slideIn();
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
		if(lock) return;
		if(choose != null)
			choose.update(dt);
		else {
			if(K.isPressed(K.UP)) {
				selectId--;
				if(selectId < 0) selectId = buttons.length - 1;
				select(selectId);
			}
			if(K.isPressed(K.DOWN)) {
				selectId = (selectId + 1) % buttons.length;
				select(selectId);
			}

			if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE)) {
				buttons[selectId].onclick();
			}
		}
	}
}