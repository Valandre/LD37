package ui;
//import Sounds;

private class EnergyGauge extends h2d.Flow {

	var bg : h2d.Tile;
	var fg : h2d.Tile;
	var bar : h2d.Bitmap;

	public var value(default, set) : Float;

	public function new(parent) {
		super(parent);
		var t = hxd.Res.UI.gauge.toTile();
		bg = t.sub(0, 0, t.width, t.height >> 1);
		fg = t.sub(0, t.height >> 1, t.width, t.height >> 1);

		var bmp = new h2d.Bitmap(bg, this);

		bar = new h2d.Bitmap(fg, this);
		getProperties(bar).isAbsolute = true;
		value = 0;
	}

	function set_value(v : Float) {
		bar.tile = fg.sub(0, 0, Math.ceil(fg.width * v), fg.height);
		return value = v;
	}
}

private class PlayerScore extends h2d.Flow {

	var game : Game;
	var pid : Int;

	var portrait : h2d.Bitmap;
	var stars : Array<h2d.Bitmap> = [];
	var starTileBg : h2d.Tile;
	public var starTile : h2d.Tile;

	var gauge : EnergyGauge;

	public function new(parent, pid) {
		super(parent);
		this.game = Game.inst;
		this.pid = pid;

		isVertical = false;
		verticalAlign = Top;

		/*
		var modelId = Data.chars.get(game.state.players[pid - 1].modelId).selectId;
		var res = hxd.Res.load("UI/CharacterSelect/Thumb" + (modelId < 10 ? "0" : "") + modelId + ".png");
		*/
		var res = hxd.Res.UI.portrait;
		portrait = new h2d.Bitmap(res.toTile(), this);
		portrait.smooth = true;

		//
		var right = new h2d.Flow(this);
		right.isVertical = true;
		right.verticalSpacing = 15;

		var sub = new h2d.Flow(right);
		starTileBg = hxd.Res.UI.pointSlotEmpty.toTile();
		starTile = hxd.Res.UI.pointSlot.toTile();
		sub.horizontalSpacing = 1;
		for(j in 0...5) {
			var b = new h2d.Bitmap(game.state.stars[pid - 1] > j ? starTile : starTileBg, sub);
			b.smooth = true;
			stars.push(b);
		}

		gauge = new EnergyGauge(right);
	}

	public function addStar() {
		stars[game.state.stars[pid - 1]].tile = starTile;
	}

	public function update(dt : Float) {
		var p = null;
		for( pl in game.players )
			if(pl.id == pid) {
				p = pl;
				break;
			}
		if(p != null)
			gauge.value = p.power.progress;
	}
}


class Scores extends h2d.Sprite
{
	var game : Game;
	var onReady : Void -> Void;
	var scores : Array<PlayerScore> = [];

	public function new(?parent, ?onReady) {
		super(parent);
		game = Game.inst;
		this.onReady = onReady;

		game.setAmbient(1);
		init();
	}

	function init() {
		for(i in 0...game.players.length)
			scores.push(new PlayerScore(this, game.players[i].id));

		game.event.wait(1, function() start());
		onResize();
	}

	function start() {
		var m = hxd.Res.UI.Countdown.Model;
		var obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		obj.playAnimation(a);
		obj.currentAnimation.onAnimEnd = function() {
			if(onReady != null) onReady();
			obj.remove();
		}

		for(m in obj.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(obj);

		var cam = game.s3d.camera;
		var a = hxd.Math.atan2(cam.pos.y - cam.target.y, cam.pos.x - cam.target.x);
		obj.x = cam.target.x;
		obj.y = cam.target.y;
		obj.z = cam.target.z;
		obj.rotate(0, 0, a);
	}

	public function nextRound(pl : ent.Fairy) {
		var t = hxd.Res.UI.Winner.toTile();
		var bmp = new h2d.Bitmap(t, this);
		bmp.smooth = true;
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

						//Sounds.play("Winner");
						s.addStar();

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
	}

	public function onResize() {
		var d = 25;
		scores[0].x = d;
		scores[0].y = d;
		scores[1].x = game.s2d.width - scores[1].getSize().width - d;
		scores[1].y = d;
		scores[2].x = d;
		scores[2].y = game.s2d.height - scores[1].getSize().height - d;
		scores[3].x = game.s2d.width - scores[1].getSize().width - d;
		scores[3].y = game.s2d.height - scores[1].getSize().height - d;
	}

	public function update(dt : Float) {
		for(s in scores)
			s.update(dt);
	}
}