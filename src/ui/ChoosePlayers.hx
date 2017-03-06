package ui;
import hxd.Key in K;
import Sounds;

class ChoosePlayers extends ui.Form
{
	var players = [];
	var contRight : h2d.Flow;

	var onRemove : Bool -> Void;

	var fairies = [];
	var sticks : Array<h2d.Bitmap> = [];
	var ptiles = [];

	public function new(?parent, onRemove : Bool -> Void ) {
		super(parent);

		this.onRemove = onRemove;
		game.setAmbient(1);
	}

	override function slideOut(?onEnd : Void -> Void) {
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
				cont.visible = false;
				contRight.visible = false;
				bmp.remove();
				bg.visible = false;
				if(onEnd != null) onEnd();
				return true;
			}
			return false;
		});
	}

	override function slideIn(?onEnd : Void -> Void) {
		bg.x = game.s2d.width + 100;
		bg.visible = true;
		cont.visible = true;
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

	override function init() {
		super.init();

		var next = addButton("NEXT", cont);
		next.interactive.onClick = function(e) {
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

		var back = addButton("BACK", cont);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				game.setAmbient(0);
				while(game.players.length > 0)
					game.players.pop().remove();
				onRemove(false);
				remove();
			});
		}

		//
		contRight = new h2d.Flow(root);
		contRight.horizontalSpacing = 1;
		contRight.verticalSpacing = 1;
		contRight.isVertical = true;
//

		game.players = [];
		for(i in 0...4) {
			var e = new ent.Player(new h3d.col.Point(0, 0, 1));
			e.x = 4;
			e.y = -1 - 2 * (i % 2);
			e.z += 2 * (i < 2 ? 1 : 0);
			e.play("stand");
			var p = game.s3d.camera.pos;
			@:privateAccess {
				var fx = e.fxParts.get("ElfHead");
				if(fx != null) {
					fx.z += 1;
					fx.x -= 0.5;
				}
				// e.obj.setRotate(0, 0, hxd.Math.atan2(p.y - 6 - e.y, p.x - 5 - e.x));
				e.obj.currentAnimation.setFrame(Math.random() * (e.obj.currentAnimation.frameCount - 1));
				e.light.params = new h3d.Vector(0.8, 0.5, 0.1);
			}

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
	}

	override public function onResize() {
		var sc = game.s2d.height / bg.tile.height;
		super.onResize();

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

	override function update(dt : Float) {
		super.update(dt);

		for(i in 0...game.controllers.length) {
			if(i == 0) {
				game.controllers[0].active = true;
				continue;
			}
			var c = game.controllers[i];
			if(c.pressed.start) {
				Sounds.play("Select");
				c.active = !c.active;
				sticks[i].tile = c.active ? ptiles[i] : ptiles[4];
			}
			if(c.pressed.B) {
				Sounds.play("Select");
				c.active = false;
				sticks[i].tile = ptiles[4];
			}
		}
	}
}