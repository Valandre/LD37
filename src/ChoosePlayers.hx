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
			case "READY":
				tiles.push(hxd.Res.UI.Bt_Ready0.toTile());
				tiles.push(hxd.Res.UI.Bt_Ready1.toTile());
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

class ChoosePlayers extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;
	var title : h2d.Bitmap;

	var players = [];
	var contLeft : h2d.Flow;
	var contRight : h2d.Flow;

	var buttons : Array<Button> = [];
	var onRemove : Bool -> Void;

	var fairies = [];
	var sticks : Array<h2d.Bitmap> = [];
	var ptiles = [];

	public function new(?parent, onRemove : Bool -> Void ) {
		super(parent);
		game = Game.inst;

		this.onRemove = onRemove;

		bg = new h2d.Bitmap(hxd.Res.UI.Bg01.toTile(), this);
		bg.blendMode = Add;
		bg.filter = true;

		title = new h2d.Bitmap(hxd.Res.UI.Title.toTile(), this);
		title.blendMode = Alpha;
		title.filter = true;
		title.x = 50;
		title.y = 50;

		root = new h2d.Flow(this);
		root.horizontalAlign = Left;
		root.isVertical = false;
		root.horizontalSpacing = 0;
		root.verticalSpacing = 0;

		game.setAmbient(1);
		init();
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
			for(b in sticks)
				b.alpha = a;
			bg.x += sp;
			sp += 15;
			bmp.scaleX = bg.x;
			if(bmp.scaleX > game.s2d.width) {
				contLeft.visible = false;
				contRight.visible = false;
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
		contLeft.visible = true;
		contRight.visible = true;

		title.alpha = 0;
		for( b in buttons)
			b.setAlpha(0);
		for(b in sticks)
			b.alpha = 0;

		var bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF));
		bmp.scaleX = bg.x;
		bmp.scaleY = game.s2d.height;
		addChildAt(bmp, 0);

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
					for(b in sticks)
						b.alpha = a;
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

	function init() {
		//
		contLeft = new h2d.Flow(root);
		contLeft.horizontalAlign = Middle;
		contLeft.verticalAlign = Middle;
		contLeft.verticalSpacing = 30;
		contLeft.isVertical = true;
		contLeft.paddingLeft = 170;
		contLeft.paddingTop = 300;

		var ready = new Button("READY", contLeft);
		ready.interactive.onClick = function(e) {
			slideOut(function() {
				remove();
				while(game.players.length > 0)
					game.players.pop().remove();
				game.nbPlayers = 0;
				for( c in game.controllers)
					if(c.active) game.nbPlayers++;
				if(game.nbPlayers == 0)
					game.nbPlayers = 1;
				onRemove(true);
				game.restart();
			});
		}
		buttons.push(ready);

		var back = new Button("BACK", contLeft);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				game.setAmbient(0);
				while(game.players.length > 0)
					game.players.pop().remove();
				onRemove(false);
				remove();
			});
		}
		buttons.push(back);

		select(selectId);

		//
		contRight = new h2d.Flow(root);
		contRight.horizontalSpacing = 1;
		contRight.verticalSpacing = 1;
		contRight.isVertical = true;
		contRight.debug = true;

//


		game.players = [];
		for(i in 0...4) {
			var e = new ent.Player(new h3d.col.Point(0, 0, 1));
			e.x = 4;
			e.y = -1 - 2 * (i % 2);
			e.z += 2 * (i < 2 ? 1 : 0);
			e.play("stand");
			var p = game.s3d.camera.pos;
			@:privateAccess e.fxParts.get("ElfHead").z += 1;
			@:privateAccess e.fxParts.get("ElfHead").x -= 0.5;
			//@:privateAccess e.obj.setRotate(0, 0, hxd.Math.atan2(p.y - 6 - e.y, p.x - 5 - e.x));
			@:privateAccess e.obj.currentAnimation.setFrame(Math.random() * (e.obj.currentAnimation.frameCount - 1));
			@:privateAccess e.light.params = new h3d.Vector(0.8, 0.5, 0.1);

			fairies.push(e);
			game.players.push(e);
		}

		ptiles = [];
		ptiles.push(hxd.Res.UI.Player1.toTile());
		ptiles.push(hxd.Res.UI.Player2.toTile());
		ptiles.push(hxd.Res.UI.Player3.toTile());
		ptiles.push(hxd.Res.UI.Player4.toTile());
		ptiles.push(hxd.Res.UI.PressStart.toTile());

		for(t in ptiles) {
			t.dx -= t.width >> 1;
			t.dy -= t.height >> 1;
		}

		sticks = [];
		var b = new h2d.Bitmap(ptiles[0], this);
		b.filter = true;
		sticks.push(b);
		for(i in 0...3) {
			var b = new h2d.Bitmap(ptiles[4], this);
			b.blendMode = Alpha;
			b.filter = true;
			sticks.push(b);
		}

		onResize();
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

		contLeft.paddingLeft = Std.int(170 * sc);
		contLeft.paddingTop = Std.int(300 * sc);

		contRight.minWidth = contRight.maxWidth = Std.int(game.s2d.width * 0.7);
		contRight.minHeight = contRight.maxHeight = game.s2d.height;
		contRight.needReflow = true;

		root.needReflow = true;

		sticks[0].setScale(0.85 * sc);
		sticks[0].x = game.s2d.width * 0.53;
		sticks[0].y = game.s2d.height * 0.45;

		sticks[1].setScale(0.85 * sc);
		sticks[1].x = game.s2d.width * 0.80;
		sticks[1].y = game.s2d.height * 0.45;

		sticks[2].setScale(0.85 * sc);
		sticks[2].x = game.s2d.width * 0.53;
		sticks[2].y = game.s2d.height * 0.84;

		sticks[3].setScale(0.85 * sc);
		sticks[3].x = game.s2d.width * 0.78;
		sticks[3].y = game.s2d.height * 0.88;
	}

	public function update(dt : Float) {
		if(K.isPressed(K.UP) || (game.keys != null && game.keys.pressed.yAxis < 0)) {
			Sounds.play("Over");
			selectId--;
			if(selectId < 0) selectId = buttons.length - 1;
			select(selectId);
		}
		if(K.isPressed(K.DOWN) || (game.keys != null && game.keys.pressed.yAxis > 0)) {
			Sounds.play("Over");
			selectId = (selectId + 1) % buttons.length;
			select(selectId);
		}

		if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE) || (game.keys != null && game.keys.pressed.A)) {
			Sounds.play("Select");
			buttons[selectId].onclick();
		}

		for(i in 0...game.controllers.length) {
			if(i == 0) {
				game.controllers[0].active = true;
				continue;
			}
			var c = game.controllers[i];
			if(c.pressed.start) {
				c.active = !c.active;
				sticks[i].tile = c.active ? ptiles[i] : ptiles[4];
			}
			if(c.pressed.B) {
				c.active = false;
				sticks[i].tile = ptiles[4];
			}
		}
	}
}