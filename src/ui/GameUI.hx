package ui;
//import Sounds;



private class PlayerScore {

	var game : Game;
	var pid : Int;
	var modelId : Int;
	var me : ent.Unit;
	var portrait : h3d.scene.Object;
	var counter : h3d.scene.Object;
	var powerReadyText : h3d.scene.Object;
	var energyMesh : h3d.scene.Object;
	var iconState = 0; //0 = alive, 1 = burst, 2 = dead 

	public function new(parent : GameUI, pid) {
		this.game = Game.inst;
		this.pid = pid;

		for( pl in game.players )
			if(pl.id == pid) {
				me = pl;
				break;
			}

		var root = @:privateAccess parent.root;
		modelId = Data.chars.get(me.props.modelId).selectId;

		portrait = root.getObjectByName("ThumbP" + pid);
		getPortrait();

		//flames = [root.getObjectByName("FlameAP" + pid), root.getObjectByName("FlameBP" + pid)];
		powerReadyText = root.getObjectByName("ReadyP" + pid);

		energyMesh = root.getObjectByName("Energy" + pid);
		var tex = game.getTexFromPath("wall" + (me.props.colorId < 10 ? "0" : "") + (me.props.colorId + 1) + ".png");
		energyMesh.toMesh().material.texture = tex;
		energyMesh.toMesh().material.blendMode = Alpha;
		energyMesh.scaleY = me.power.progress;
		update(0);

		counter = root.getObjectByName("P" + pid + "Counter");
		counterUpdate();
	}

	function getPortrait(state = 0) {
		var suf = "";
		if(state == 1) suf = "_burst";
		else if(state == 2) suf = "_dead";

		var tex = try {
			game.getTexFromPath("UI/LifeBar/Thumb" + (modelId < 10 ? "0" : "") + modelId + suf + ".png");
		}
		catch(e : hxd.res.NotFound) {
			game.getTexFromPath("UI/CharacterSelect/Thumb00.png");
		};

		portrait.toMesh().material.texture = tex;
	}

	public function counterUpdate() {
		if(counter != null) {
			var stars = game.state.stars[pid - 1];
			var tex = game.getTexFromPath("UI/LifeBar/Counter0" + stars + ".png");
			counter.toMesh().material.texture = tex;
		}
	}

	function iconUpdate() {
		if(me.dead) {
			if(iconState != 2) {
				iconState = 2;
				getPortrait(iconState);
			}
			return;
		}
		if(me.power.progress == 1) {
			if(iconState != 1) {
				iconState = 1;
				getPortrait(iconState);
			}
			return;
		}
		if(iconState != 0) {
			iconState = 0;
			getPortrait(iconState);
		}		
	}

	public function update(dt : Float) {
		powerReadyText.visible = me.power.progress == 1;
		energyMesh.scaleY += (me.power.progress - energyMesh.scaleY) * 0.1 * dt;
		iconUpdate();
	}
}


class GameUI
{
	var game : Game;
	var scores : Array<PlayerScore> = [];

	var root : h3d.scene.Object;
	var countDown : h3d.scene.Object;

	var maxStars = 5;

	public function new() {
		game = Game.inst;
		game.setAmbient(1);
		init();
	}

	function init() {
		var m = hxd.Res.UI.LifeBar.Model;
		root = game.modelCache.loadModel(m);
		game.s3d.addChild(root);
		root.name = "ui";

		var a = game.modelCache.loadAnimation(m);
		root.playAnimation(a);

		game.s3d.camera.follow = {pos : root.getObjectByName("CamScreen"), target : root.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;

		var tex = new h3d.mat.Texture(game.s2d.width, game.s2d.height, [Target]);
		game.customScene.addView(-1, game.s3d.camera, tex);
		var b = new h2d.Bitmap(h2d.Tile.fromTexture(tex), game.s2d);
		b.blendMode = Alpha;
		game.bmpViews.push(b);

		for(i in 0...game.players.length)
			scores.push(new PlayerScore(this, game.players[i].id));

		game.event.wait(1, function() startRace());
	}

	public function remove() {
		root.remove();
	}

	function startRace() {
		var m = hxd.Res.UI.Countdown.Model_fbx;
		countDown = game.modelCache.loadModel(m);
		game.s3d.addChild(countDown);

		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		countDown.playAnimation(a);
		countDown.name = "ui";

		var cam = game.s3d.camera;
		var a = hxd.Math.atan2(cam.pos.y - cam.target.y, cam.pos.x - cam.target.x);
		countDown.x = cam.target.x;
		countDown.y = cam.target.y;
		countDown.z = cam.target.z;
		countDown.rotate(0, 0, a);

		for(m in countDown.getMeshes()) {
			if(m.name != "Square")
				m.material.mainPass.depthWrite = false;
		}

		game.event.waitUntil(function(dt) {
			if(countDown.currentAnimation.frame >= countDown.currentAnimation.frameCount - 1) {
				game.gameOver = false;
				for(p in game.players)
					p.canMove = true;
				countDown.remove();
				return true;
			}
			return false;
		});
	}

	public function nextRound(pl : ent.Unit) {

		if(pl == null) {
			//mort simultanée : pas de gagnant
			game.event.wait(2, function() {
				game.restart();
			});
			return;
		}

		var t = hxd.Res.UI.winner.toTile();
		var bmp = new h2d.Bitmap(t, game.s2d);
		bmp.smooth = true;
		var sc = 1;
		bmp.setScale(sc);

		var d = 25;
		var to = 0.;
		switch(pl.id) {
			case 1 :
				bmp.x = -t.width * sc - 100;
				bmp.y = 100 + d;
				to = d;
			case 2 :
				bmp.x = game.s2d.width + 100;
				bmp.y = 100 + d;
				to = game.s2d.width - t.width * sc - d;
			case 3 :
				bmp.x = -t.width * sc - 100;
				bmp.y = game.s2d.height - 100 - t.height * sc - d;
				to = d;
			case 4 :
				bmp.x = game.s2d.width + 100;
				bmp.y = game.s2d.height - 100 - t.height * sc - d;
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
						game.state.stars[pl.id - 1]++;
						var s = scores[pl.id - 1];
						s.counterUpdate();

						game.event.wait(2, function() {
							bmp.remove();
							if(game.state.stars[pl.id - 1] == maxStars)
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

	public function update(dt : Float) {
		for(s in scores)
			s.update(dt);
	}
}