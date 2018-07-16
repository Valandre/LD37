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
	var maxStars = 1;

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
		var m = hxd.Res.UI.Countdown.Model;
		var countDown = game.modelCache.loadModel(m);
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
		var m = hxd.Res.UI.Winner.Model;
		var winner = game.modelCache.loadModel(m);
		game.s3d.addChild(winner);		

		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		winner.playAnimation(a);
		winner.name = "ui";		

		var res = hxd.Res.load("Chars/" + pl.props.modelId + "01/Model.FBX").toModel();
		if(res != null) {
			var m = game.modelCache.loadModel(res);
			m.inheritCulled = true;			
			for(m in m.getMaterials()) {
				m.mainPass.enableLights = true;
				m.shadows = false;
				m.mainPass.culling = None;
			}	
			
			var path = res.entry.directory + "/Anim_stand";
			var a = game.modelCache.loadAnimation(hxd.Res.loader.load(path+".FBX").toModel());
			a.loop = true;
			m.playAnimation(a);
			setOutline(m, pl.getColor());

			var o = winner.getObjectByName("PosSushi");
			if(o != null) 
				o.addChild(m);
		}
		
		game.event.waitUntil(function(dt) {		

			var cam = game.s3d.camera;
			var a = hxd.Math.atan2(cam.pos.y - cam.target.y, cam.pos.x - cam.target.x);
			winner.x = cam.target.x;
			winner.y = cam.target.y;
			winner.z = cam.target.z;
			winner.rotate(0, 0, a);

			if(winner.currentAnimation.frame >= winner.currentAnimation.frameCount - 1) {
				game.state.stars[pl.id - 1]++;
				var s = scores[pl.id - 1];
				s.counterUpdate();
				game.event.wait(2, function() {
					winner.remove();
					if(game.state.stars[pl.id - 1] == maxStars)
						game.endGame();
					else game.restart();
				});
				return true;
			}
			return false;
		});
	}


	function setOutline(obj : h3d.scene.Object, color : Int) {
		var outlineShader = new shaders.Outline();
		outlineShader.size = 0.06;
		outlineShader.distance = 0.001;
		outlineShader.color.setColor(color);

		for( m in obj.getMeshes() ) {
			if( m.material.name != null && StringTools.startsWith(m.material.name, "FX") )
				continue;

			var p : h3d.prim.HMDModel = Std.instance(m.primitive, h3d.prim.HMDModel);
			if( p == null )
				continue;

			if( !p.hasBuffer("logicNormal") )
				p.recomputeNormals("logicNormal");

			var multi = Std.instance(m, h3d.scene.MultiMaterial);
			for( m in (multi != null ? multi.materials : [m.material]) ) {
				var p = m.allocPass("outline");
				p.culling = None;
				p.addShader(outlineShader);
			}
		}
	}

	public function update(dt : Float) {
		for(s in scores)
			s.update(dt);
	}
}