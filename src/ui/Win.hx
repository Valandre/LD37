package ui;
import hxd.Key in K;
//import Sounds;

class ModelSlot {
	var game : Game;
	var obj : h3d.scene.Object;
	var follow : h3d.scene.Object;
	var charKind : Data.CharsKind;
	var outlineShader : shaders.Outline;

	var faceTextures : Array<h3d.mat.Texture> = [];
	var faceBlinking = false;

	var colorId : Int;

	public function new(charKind, colorId, follow, playAnim = true) {
		game = Game.inst;
		this.follow = follow;
		this.charKind = charKind;
		this.colorId = colorId;
		setModel(playAnim);
	}

	public function getKind() {
		return charKind;
	}

	function getModel() {
		return hxd.Res.load("Chars/" + charKind + "01/Model.FBX").toModel();
	}

	function getAnimSelection() {
		return hxd.Res.load("Chars/" + charKind + "01/Anim_selection.FBX").toModel();
	}

	function setModel (playAnim : Bool) {		
		var res = getModel();
		if(res == null) return;

		obj = game.modelCache.loadModel(res);
		if(playAnim) {
			var a = game.modelCache.loadAnimation(getAnimSelection());
			obj.playAnimation(a);
			obj.currentAnimation.setFrame(Std.random(a.frameCount));
			obj.currentAnimation.speed *= 1 - hxd.Math.random(0.1);
		}
		
		obj.follow = follow;
		game.s3d.addChild(obj);

		for(m in obj.getMaterials()) {
			m.mainPass.enableLights = true;
			m.receiveShadows = true;
			m.mainPass.culling = Back;
		}		

		var tex = game.getTexFromPath("Chars/" + charKind + "01/Texture01_normal.png");
		if(tex != null)
			for(m in obj.getMeshes())
				m.material.mainPass.addShader(new shaders.NormalMap(tex));

		faceTextures = [];
		for(m in obj.getMaterials()) {
			if(StringTools.startsWith(m.name, "Face")) {
				var i = 0;
				while(true) {
					var tex = game.getTexFromPath("Chars/" + charKind + "01/FaceA_0" + i + ".png");
					if(tex == null) break;
					faceTextures.push(tex);
					i++;
				}
			}
		}

		setOutline();
	}

	function setOutline() {
		if(outlineShader == null) {
			outlineShader = new shaders.Outline();
			outlineShader.size = 0.06;
			outlineShader.distance = 0.001;

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
		outlineShader.color.setColor(getColor());
	}

	function getColor() {
		var res = try { hxd.Res.load("wall0" + (colorId + 1) + ".png").toImage(); } catch(e : hxd.res.NotFound) { null; };
		var color = res == null ? 0 : res.toBitmap().getPixel(0, 0);
		return color;
	}

	var blinkRnd = 0.;
	function faceBlink() {
		var mat = null;
		for(m in obj.getMaterials())
			if(StringTools.startsWith(m.name, "Face")) {
				mat = m;
				break;
			}
		if(mat == null) return;

		faceBlinking = true;
		var t = 0.;
		var id = 0;
		var sp = 2 + Math.random();
		game.event.waitUntil(function(dt) {
			t += dt;
			if(t > sp) {
				if(id == faceTextures.length) {
					mat.texture = faceTextures[0];
					faceBlinking = false;
					return true;
				}
				mat.texture = faceTextures[id++];
				t -= sp;
			}
			return false;
		});
	}

	public function update(dt : Float) {
		blinkRnd += 0.00004 * dt;
		if(!faceBlinking && Math.random() < blinkRnd) {
			faceBlink();
			blinkRnd = 0;
		}
	}
}

class Win extends ui.Form 
{
	var ready = false;

	var colorTex : Array<h3d.mat.Texture> = [];
	var placeTex : Array<h3d.mat.Texture> = [];
	var stateTex : Array<h3d.mat.Texture> = [];
	var nameTex : Array<h3d.mat.Texture> = [];
	var models : Array<ModelSlot> = [];

	override function init() {
		super.init();
		
		//init scene
		var m = hxd.Res.UI.Podium.Model;
		obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		obj.playAnimation(a);
		obj.currentAnimation.onAnimEnd = function() {
			ready = true;
		}

		for(m in obj.getMeshes())
			m.material.shadows = false;

		addBg();

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;

		//
		for(i in 0...9)
			colorTex.push(game.getTexFromPath("UI/Podium/TrailColor0" + (i + 1) + ".png"));
		for(i in 0...4)
			placeTex.push(game.getTexFromPath("UI/Podium/Place0" + (i + 1) + ".png"));
		for(i in 0...4)
			stateTex.push(game.getTexFromPath("UI/CharacterSelect/StateP" + (i + 1) + ".png"));
	
		var i = 0;
		while(true) {	
			var name = game.getTexFromPath("UI/CharacterSelect/Name" + ((i < 9 ? "0" : "") + (i + 1)) + ".png");
			if(name == null) break;
			nameTex.push(name);			
			i++;
		}

		//
		var order : Array<{player : ent.Unit.Props, stars : Int}> = [];
		for(i in 0...game.state.players.length) {
			var index = 0;
			for(o in order) {
				if(game.state.stars[i] > o.stars) break;
				index++;
			}
			order.insert(index, {player : game.state.players[i], stars: game.state.stars[i]});
		}

		var curStars = order[0].stars;
		var place = 0;
		for(i in 0...order.length) {
			var o = order[i];

			//name
			var m = obj.getObjectByName("NameN"+(i+1));
			if(m != null)
				m.toMesh().material.texture = nameTex[Data.chars.get(o.player.modelId).selectId-1];			

			//bg 
			var m = obj.getObjectByName("TrailN"+(i+1));
			if(m != null)
				m.toMesh().material.texture = colorTex[o.player.colorId];

			//place number
			if(order[i].stars < curStars) {
				place = i;
				curStars = order[i].stars;
			}
			var m = obj.getObjectByName("PlaceN"+(i+1));
			if(m != null)
				m.toMesh().material.texture = placeTex[place];

			//player state
			var m = obj.getObjectByName("StateN"+(i+1));
			if(m != null) {			
				var index = game.state.players.indexOf(o.player);
				m.toMesh().material.texture = stateTex[index];
			}

			//model
			var m = obj.getObjectByName("PosN"+(i+1));
			if(m != null) 
				models.push(new ModelSlot(o.player.modelId, o.player.colorId, m, i == 0));
		}
	}

	override public function onRemove() {
		super.onRemove();
		obj.remove();
		for(m in models)
			@:privateAccess m.obj.remove();
		models = [];
	}

	override function update(dt : Float) {
		super.update(dt);	

		for(m in models) 
			m.update(dt);

		var c = game.controllers[0];
		if(c != null) {
			c.active = true;
			if(c.pressed.A && ready) {
				new ui.ChoosePlayers();
				remove();
			}
		}
	}
}