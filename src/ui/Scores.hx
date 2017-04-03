package ui;
import Sounds;

class Scores extends h2d.Sprite
{
	var game : Game;
	var onReady : Void -> Void;

	var tiles = [];
	var bmp : h2d.Bitmap;
	var bmp2 : h2d.Bitmap;

	var stars = [];
	var scores : Array<h2d.Flow> = [];
	var bonus : Array<h2d.Bitmap> = [];

	public function new(?parent, ?onReady) {
		super(parent);
		game = Game.inst;
		this.onReady = onReady;

		game.setAmbient(1);
		init();
	}

	function init() {
		tiles.push(hxd.Res.UI.num3.toTile());
		tiles.push(hxd.Res.UI.num2.toTile());
		tiles.push(hxd.Res.UI.num1.toTile());
		tiles.push(hxd.Res.UI.Go.toTile());

		for( t in tiles) {
			t.dx -= t.width >> 1;
			t.dy -= t.height >> 1;
		}

		bmp2 = new h2d.Bitmap(null, this);
		bmp2.blendMode = Alpha;
		bmp2.filter = true;
		bmp2.alpha = 0;
		bmp2.x = game.s2d.width >> 1;
		bmp2.y = game.s2d.height >> 1;
		bmp2.colorAdd = new h3d.Vector(1, 1, 1);

		bmp = new h2d.Bitmap(null, this);
		bmp.blendMode = Alpha;
		bmp.filter = true;
		bmp.alpha = 0;
		bmp.x = game.s2d.width >> 1;
		bmp.y = game.s2d.height >> 1;

		stars.push(hxd.Res.UI.Star0.toTile());
		stars.push(hxd.Res.UI.Star1.toTile());
		stars.push(hxd.Res.UI.Star2.toTile());
		stars.push(hxd.Res.UI.Star3.toTile());
		stars.push(hxd.Res.UI.Star4.toTile());

		for(i in 0...4) {
			var s = new h2d.Flow(this);
			s.horizontalSpacing = -30;
			for(j in 0...5) {
				var b = new h2d.Bitmap(stars[game.state.stars[i] > j ? game.players[i].id : 0], s);
				b.filter = true;
				b.setScale(0.5);
			}
			scores.push(s);
		}

		game.event.wait(1, function() start(0));
		onResize();
	}

	function start(id : Int) {
		bmp.alpha = 1;
		bmp2.alpha = 0;
		bmp.tile = tiles[id];
		bmp2.tile = tiles[id];
		bmp2.setScale(1);

		var sc = 5.;
		bmp.setScale(sc);
		game.event.waitUntil(function(dt) {
			sc -= 0.4 * dt;
			bmp.setScale(sc);
			if(sc <= 1){
				game.shake(0.025);
				Sounds.play(id < 3 ? "Count" : "Go");
				bmp2.alpha = 1;
				game.event.waitUntil(function(dt) {
					sc += 0.05 * dt;
					bmp2.setScale(sc);
					bmp2.alpha -= 0.08 * dt;
					return bmp2.alpha <= 0;
				});
				game.event.wait(0.5, function() {
					if(id < 3)
						start(++id);
					else {
						if(onReady != null) onReady();
						game.event.waitUntil(function(dt) {
							bmp.alpha -= 0.05 * dt;
							if(bmp.alpha <= 0)
								return true;
							return false;
						});
					}
				});
				return true;
			}
			return false;
		});
	}

	public function nextRound(pl : ent.Fairy) {
		var t = hxd.Res.UI.Winner.toTile();
		var bmp = new h2d.Bitmap(t, this);
		bmp.filter = true;
		var sc = 1;
		bmp.setScale(sc);

		var d = 25;
		var s = scores[pl.id - 1];
		var to = 0.;
		switch(pl.id) {
			case 1 :
				bmp.x = -t.width * sc - 100;
				bmp.y = s.y + s.getSize().height + d;
				to = d;
			case 2 :
				bmp.x = game.s2d.width + 100;
				bmp.y = s.y + s.getSize().height + d;
				to = game.s2d.width - t.width * sc - d;
			case 3 :
				bmp.x = -t.width * sc - 100;
				bmp.y = s.y - t.height * sc - d;
				to = d;
			case 4 :
				bmp.x = game.s2d.width + 100;
				bmp.y = s.y - t.height * sc - d;
				to = game.s2d.width - t.width * sc - d;
			default :
		}

		game.event.waitUntil(function(dt) {
			bmp.x += (to - bmp.x) * 0.25 * dt;
			if(Math.abs(to - bmp.x) < 1) {
				var c = 1.;
				bmp.colorAdd = new h3d.Vector(c, c, c);
				game.event.waitUntil(function(dt) {
					c -= 0.05 * dt;
					bmp.colorAdd.x = bmp.colorAdd.y = bmp.colorAdd.y = c;
					if(c <= 0) {
						bmp.colorAdd = null;

						Sounds.play("Winner");

						var t = stars[pl.id].clone();
						t.dx -= t.width >> 1;
						t.dy -= t.height >> 1;
						var star = new h2d.Bitmap(t, this);
						var sc = 3.;
						star.setScale(sc);
						var target = s.getChildAt(game.state.stars[pl.id-1]);
						Std.instance(target, h2d.Bitmap).tile = stars[pl.id];
						star.x = target.absX;
						star.y = target.absY + 25;

						game.event.waitUntil(function(dt) {
							sc -= 0.25 * dt;
							star.setScale(sc);
							if(sc <= 1) {
								star.remove();
								game.event.wait(2, function() {
									bmp.remove();
									game.state.stars[pl.id - 1]++;
									if(game.state.stars[pl.id - 1] == 5)
										game.endGame();
									else game.restart();
								});
								return true;
							}
							return false;
						});

						return true;
					}
					return false;
				});
				return true;
			}
			return false;
		});
	}

	public function onResize() {
		bmp.x = game.s2d.width >> 1;
		bmp.y = game.s2d.height >> 1;
		bmp2.x = game.s2d.width >> 1;
		bmp2.y = game.s2d.height >> 1;

		var d = 25;
		scores[0].x = d;
		scores[0].y = d;
		scores[1].x = game.s2d.width - scores[1].getSize().width - d;
		scores[1].y = d;
		scores[2].x = d;
		scores[2].y = game.s2d.height - scores[1].getSize().height - d;
		scores[3].x = game.s2d.width - scores[1].getSize().width - d;
		scores[3].y = game.s2d.height - scores[1].getSize().height - d;

		placeBonus(0);
		placeBonus(1);
		placeBonus(2);
		placeBonus(3);
	}

	function placeBonus(id : Int) {
		var d = 50;
		switch(id) {
		case 0 :
			if(bonus[0] != null) {
				bonus[0].x = d + scores[0].getSize().width;
				bonus[0].y = scores[0].y;
			}
		case 1 :
			if(bonus[1] != null) {
				bonus[1].x = scores[1].x - d - bonus[1].tile.width;
				bonus[1].y = scores[1].y;
			}
		case 2 :
			if(bonus[2] != null) {
				bonus[2].x = d + scores[2].getSize().width;
				bonus[2].y = scores[2].y;
			}
		case 3 :
			if(bonus[3] != null) {
				bonus[3].x = scores[3].x - d - bonus[3].tile.width;
				bonus[3].y = scores[3].y;
			}
		}
	}

	public function update(dt : Float) {
		for(p in game.players) {
			var b = bonus[p.id - 1];
			if(p.currBonus == null) {
				if(b != null) {
					b.remove();
					b = null;
				}
				continue;
			}

			if(b == null) {
				b = new h2d.Bitmap(h2d.Tile.fromColor(ent.Bonus.getBonusColor(p.currBonus.kind), 50, 50), this);
				bonus[p.id - 1] = b;
			}
			else b.tile = h2d.Tile.fromColor(ent.Bonus.getBonusColor(p.currBonus.kind), 50, 50);
			placeBonus(p.id - 1);
		}
	}
}