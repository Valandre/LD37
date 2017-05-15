package ui;
import hxd.Key in K;
import Sounds;

class ChoosePlayers extends ui.Form
{
	var players = [];
	//var contRight : h2d.Flow;

	var fairies = [];
	var sticks : Array<h2d.Bitmap> = [];
	var ptiles = [];

	var container: h2d.Sprite;
	var btBack: NavigateButton;
	var btNext: NavigateButton;

	public function new(?parent) {
		super(parent);
		game.setAmbient(1);
		game.autoCameraKind = Choose;
	}

	override function init() {
		super.init();

		setInfos(Texts.ui.choose_character);

		container = new h2d.Sprite(this);
		showPlayers();


		btBack = new NavigateButton(Texts.navigate.back, this);
		btBack.onClick = function() {
			new ui.Menu();
			remove();
		}

		btNext = new NavigateButton(Texts.navigate.next, this);
		btNext.onClick = function() {
			game.state.nbPlayers = 1;
			new ui.ChooseArena();
			remove();
		}

		onResize();
/*
		var next = addButtonOld("NEXT", cont);
		next.interactive.onClick = function(e) {
			slideOut(function() {
				while(game.players.length > 0)
					game.players.pop().remove();
				game.state.nbPlayers = 0;
				for( c in game.controllers)
					if(c.active) game.state.nbPlayers++;
				if(game.state.nbPlayers == 0)
					game.state.nbPlayers = 1;
				new ui.ChooseArena();
				remove();
			});
		}

		var back = addButtonOld("BACK", cont);
		back.interactive.onClick = function(e) {
			slideOut(function() {
				while(game.players.length > 0)
					game.players.pop().remove();
				new ui.Menu();
				remove();
			});
		}

		//
		contRight = new h2d.Flow(root);
		contRight.horizontalSpacing = 1;
		contRight.verticalSpacing = 1;
		contRight.isVertical = true;

		showPlayers();

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
		}*/
	}

	public function showPlayers() {
		players = [];

		for(a in Data.chars.all)
			var bt = addButton(a.name, CharSelect, container);

		orderButtons(8, true);

		//
		/*
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
		}*/
	}

	override public function onResize() {
		super.onResize();

		var sc = game.s2d.height / 1080;
		container.setScale(sc);

		var contSize = container.getSize();
		container.x = (game.s2d.width - contSize.width) * 0.5 - contSize.x;
		container.y = (game.s2d.height - contSize.height) * 0.2 - contSize.y;

		btBack.x = 50;
		btBack.y = game.s2d.height - btBack.getSize().height - 50;

		btNext.x = game.s2d.width - btBack.getSize().width - 50;
		btNext.y = game.s2d.height - btBack.getSize().height - 50;

		/*
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
		*/
	}

	override function update(dt : Float) {
		super.update(dt);


		var c = game.controllers[0];
		c.active = true;
		if(c.pressed.B) btBack.onClick();
		if(c.pressed.A) btNext.onClick();

		/*
		for(i in 0...game.controllers.length) {
			if(i == 0) {
				game.controllers[0].active = true;
				continue;
			}
			var c = game.controllers[i];

			if(c.pressed.start) {
				//Sounds.play("Select");
				c.active = !c.active;
				//sticks[i].tile = c.active ? ptiles[i] : ptiles[4];
			}
			if(c.pressed.B) {
				//Sounds.play("Select");
				c.active = false;
				//sticks[i].tile = ptiles[4];
			}
		}*/
	}
}