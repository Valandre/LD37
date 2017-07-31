package ui;
import hxd.Key in K;
//import Sounds;

class Menu extends ui.Form
{
	var creditsBmp : h2d.Bitmap;
	var container: h2d.Sprite;

	public function new(?parent) {
		super(parent);
		//game.setAmbient(0);
		//game.autoCameraKind = Menu;
	}

	override function init() {
		super.init();
/*
		setInfos(Texts.ui.main_menu);

		container = new h2d.Sprite(this);
		var btSingle = addButton(Texts.button.single_player, MainMenu, container);
		btSingle.onClick = function() {
			while(game.players.length > 0)
				game.players.pop().remove();
			new ui.ChoosePlayers();
			remove();
		}

		var btLocal = addButton(Texts.button.local_battle, MainMenu, container);
		btLocal.onClick = function() {
			while(game.players.length > 0)
				game.players.pop().remove();
			new ui.ChoosePlayers();
			remove();
		}

		var btOnline = addButton(Texts.button.online_battle, MainMenu, container);
		var btShop = addButton(Texts.button.wizard_shop, MainMenu, container);
		var btSettings = addButton(Texts.button.settings, MainMenu, container);
		var btCredits = addButton(Texts.button.credits, MainMenu, container);

		orderButtons(18);
*/
		/*
		var start = addButtonOld("NEWGAME", cont);
		start.interactive.onClick = function(e) {
			if(creditsBmp != null) toggleCredits();
			slideOut(function() {
				while(game.players.length > 0)
					game.players.pop().remove();
				new ui.ChoosePlayers();
				remove();
			});
		}

		var sound = addButtonOld("SOUND", cont);
		if(!Game.PREFS.music) {
			sound.tiles.push(sound.tiles.shift());
			sound.tiles.push(sound.tiles.shift()); //twice !
			sound.bt.tile = sound.tiles[1];
		}
		sound.interactive.onClick = function(e) {
			sound.tiles.push(sound.tiles.shift());
			sound.tiles.push(sound.tiles.shift()); //twice !
			sound.bt.tile = sound.tiles[1];
			Game.PREFS.music = !Game.PREFS.music;
			Game.savePrefs();
			if(!Game.PREFS.music) Sounds.stop("Loop");
			else Sounds.play("Loop");
			if(creditsBmp != null) toggleCredits();
		};

		var credits = addButtonOld("CREDITS", cont);
		credits.interactive.onClick = function(e){ toggleCredits(); };
		var exit = addButtonOld("EXIT", cont);
		exit.interactive.onClick = function(e) hxd.System.exit();
*/

		//createFairies();

		onResize();
		//select(0);
	}

	function createFairies() {
		var dirs = [
		new h3d.col.Point(1, 0, 0),
		new h3d.col.Point( -1, 0, 0),
		new h3d.col.Point(0, 1, 0),
		new h3d.col.Point(0, -1, 0)
		];

		game.players = [];
		/*
		for( i in 0...12) {
			var e = new ent.IA(dirs[Std.random(dirs.length)], 1, 1 + Std.random(4));
			e.x = hxd.Math.srand(game.size * 0.4);
			e.y = hxd.Math.srand(game.size * 0.4);
			e.enableCollides = false;
			e.enableWalls = false;
			e.canMove = true;
			@:privateAccess e.speed *= 5;
			game.players.push(e);
			for(j in 0...100)
				e.update(1);
		}*/
	}
/*
	function toggleCredits() {
		if(creditsBmp == null) {
			creditsBmp = new h2d.Bitmap(hxd.Res.UI.Credits.toTile());
			creditsBmp.blendMode = Alpha;
			creditsBmp.smooth = true;
			creditsBmp.alpha = 0;
			creditsBmp.x = game.s2d.width * 0.4;
			creditsBmp.y = (game.s2d.height - creditsBmp.tile.height) * 0.5;
			addChildAt(creditsBmp, 0);

			bmpSlide = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF));
			bmpSlide.scaleY = game.s2d.height;
			addChildAt(bmpSlide, 0);

			var a = 0.;
			var sp = 10.;
			game.event.waitUntil(function(dt){
				bg.x += sp;
				sp += 15;
				bmpSlide.scaleX = bg.x;
				if(bmpSlide.scaleX > game.s2d.width) {
					game.event.waitUntil(function(dt){
						a = Math.min(1, a + 0.1 * dt);
						creditsBmp.alpha = a;
						if(a == 1) {
							return true;
						}
						return false;
					});

					return true;
				}
				return false;
			});
		}
		else {
			var a = 1.;
			var sp = 10.;
			game.event.waitUntil(function(dt){
				a = Math.max(0, a - 0.1 * dt);
				creditsBmp.alpha = a;
				bg.x -= sp;
				sp += 15;
				bmpSlide.scaleX = bg.x;
				if(bmpSlide.scaleX <= 0) {
					bg.x = 0;
					bmpSlide.remove();
					bmpSlide = null;
					creditsBmp.remove();
					creditsBmp = null;
					return true;
				}
				return false;
			});
		}
	}
*/
	override function onResize() {
		super.onResize();
/*
		var sc = game.s2d.height / 1080;
		container.setScale(sc);

		var contSize = container.getSize();
		container.x = (game.s2d.width - contSize.width) * 0.5 - contSize.x;
		container.y = (game.s2d.height - contSize.height) * 0.5 - contSize.y;

		if(creditsBmp != null) {
			creditsBmp.x = game.s2d.width * 0.4;
			creditsBmp.y = (game.s2d.height - creditsBmp.tile.height) * 0.5;
		}
		if(bmpSlide != null) {
			bmpSlide.scaleY = game.s2d.height;
		}*/
	}
}