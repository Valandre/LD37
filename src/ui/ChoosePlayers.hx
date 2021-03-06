package ui;
//import Sounds;

class PlayerSlot {
	var game : Game;
	var obj : h3d.scene.Object;
	var follow : h3d.scene.Object;
	var selector : h3d.scene.Object;
	var chars = Data.chars.all;
	var res : hxd.res.Model;
	var charKind : Data.CharsKind;
	var outlineShader : shaders.Outline;

	var faceTextures : Array<h3d.mat.Texture> = [];
	var faceBlinking = false;

	public var powerTex : h3d.mat.Texture;

	public var pid : Int;
	public var selectId(default, set) : Int;
	public var state(default, set) : Int;
	public var visible(default, set) : Bool;
	public var colorId(default, set) = 0;

	public function new(pid, follow) {
		game = Game.inst;
		this.pid = pid;
		this.follow = follow;
		this.colorId = switch(pid) {
			case 0 : 1;
			case 1 : 3;
			case 2 : 4;
			case 3 : 7;
			default : 0;
		}

		while(true) {
			var id = chars[Std.random(chars.length)].selectId;
			//if(id != Data.chars.get(Random).selectId) {
			selectId = id;
			break;
			//}
		}
	}

	function set_colorId(v : Int) {
		colorId = v;
		if(obj != null) setOutline();
		return colorId;
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

	function updateModel () {
		for(c in chars)
			if(c.selectId == selectId) {
				charKind =  c.id;
				break;
			}

		if(obj != null) {
			obj.remove();
			outlineShader = null;
		}
		res = getModel();
		if(res == null) return;

		obj = game.modelCache.loadModel(res);
		var a = game.modelCache.loadAnimation(getAnimSelection());
		obj.playAnimation(a);
		obj.currentAnimation.setFrame(Std.random(a.frameCount));
		obj.currentAnimation.speed *= 1 - hxd.Math.random(0.1);
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

		powerTex = game.getTexFromPath("UI/CharacterSelect/Power" + Data.chars.get(charKind).powerId + ".png");


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

	function set_selectId(v : Int) {
		if(selectId == v) return v;
		selectId = v;
		
		//if(selectId != Data.chars.get(Random).selectId)
			updateModel();
		return selectId;
	}

	function set_state(v : Int) {
		if(state == v) return v;
		if(v == 0) removeSelector();
		else addSelector();
		return state = v;
	}

	function set_visible(b : Bool) {
		if(obj != null)
			for(m in obj.getMeshes())
				m.visible = b;
		return visible = b;
	}

	function addSelector() {
		if(selector != null) return;
		var m = hxd.Res.UI.Selector.Model;
		selector = game.modelCache.loadModel(m);

		var name = "SelectorP" + (pid + 1);

		for(m in selector.getMeshes()) 
			m.material.texture = game.getTexFromPath("UI/Selector/"+ name + ".png");
		game.s3d.addChild(selector);
		selector.visible = false;
		
		ChoosePlayers.getAnim("UI/Selector/"+name);
		ChoosePlayers.playAnim(name, selector.getObjectByName(name).toMesh());	

		for(i in 0...4) {
			var o = selector.getObjectByName("SelectorP"+(i+1));
			if(o != null)
				o.visible = pid == i;
		}
	}

	function removeSelector(){
		if(selector == null) return;
		selector.remove();
		selector = null;
	}

	public function setPos(o : h3d.scene.Object) {
		if(selector == null) return;
		var pos = o.getAbsPos();
		selector.visible = true;
		selector.x = pos.tx;
		selector.y = pos.ty;
		selector.z = pos.tz;
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

	public function remove() {
		if(obj != null) obj.remove();
		removeSelector();
	}

	public function update(dt : Float) {
		blinkRnd += 0.00004 * dt;
		if(!faceBlinking && Math.random() < blinkRnd) {
			faceBlink();
			blinkRnd = 0;
		}
	}
}

class ChoosePlayers extends ui.Form
{
	var pname : Array<h3d.scene.Mesh> = [];
	var pjoin : Array<h3d.scene.Mesh> = [];
	var pstate : Array<h3d.scene.Mesh> = [];
	var pslot : Array<h3d.scene.Mesh> = [];
	var ppower : Array<h3d.scene.Mesh> = [];
	var ppos : Array<h3d.scene.Object> = [];
	var mthumbs : Array<h3d.scene.Object> = [];
	var ready = false;

	var mSelect : h3d.scene.Mesh;
	var mBack : h3d.scene.Mesh;

	var mUp : h3d.scene.Mesh;
	var mDown : h3d.scene.Mesh;

	var nameTex : Array<h3d.mat.Texture> = [];
	var stateTex : Array<h3d.mat.Texture> = [];
	var slotTex : Array<h3d.mat.Texture> = [];
	var buttonTex : Array<Array<h3d.mat.Texture>> = [];

	public static var texAnim : Map<String, {frames : Array<h3d.mat.Texture>, loop : Bool}> = new Map();

	var players : Array<PlayerSlot> = [];
	var CharsIds : Array<Int> = [];

	override function init() {
		super.init();

		//init scene
		var m = hxd.Res.UI.CharacterSelect.Model_fbx;
		obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		if(a != null) {
			a.loop = false;
			obj.playAnimation(a);
			obj.currentAnimation.onAnimEnd = function() {
				ready = true;
			}
		}
		else ready = true;

		addBg();

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;

		var i = 0;
		while(true) {
			var o = obj.getObjectByName("PosThumb" + ((i < 9 ? "0" : "") + (i + 1)));
			if(o == null) break;
			mthumbs.push(o);

			var name = game.getTexFromPath("UI/CharacterSelect/Name" + ((i < 9 ? "0" : "") + (i + 1)) + ".png");
			nameTex.push(name);
			i++;
		}

		for(i in 0...4) {
			pname.push(obj.getObjectByName("NameP" + (i + 1)).toMesh());
			pjoin.push(obj.getObjectByName("JoinP" + (i + 1)).toMesh());
			pslot.push(obj.getObjectByName("SlotP" + (i + 1)).toMesh());
			pstate.push(obj.getObjectByName("StateP" + (i + 1)).toMesh());
			ppower.push(obj.getObjectByName("PowerP" + (i + 1)).toMesh());
			ppos.push(obj.getObjectByName("PosP" + (i + 1)));
		}

		stateTex.push(game.getTexFromPath("UI/CharacterSelect/StateCPU.png"));
		for(i in 0...4)
			stateTex.push(game.getTexFromPath("UI/CharacterSelect/StateP" + (i + 1) + ".png"));

		for(i in 0...9)
			slotTex.push(game.getTexFromPath("UI/CharacterSelect/Slot0" + (i + 1) + ".png"));
		pslot[0].material.texture = slotTex[1];
		pslot[1].material.texture = slotTex[3];
		pslot[2].material.texture = slotTex[4];
		pslot[3].material.texture = slotTex[7];

		getAnim("UI/CharacterSelect/PowerReady");

		//
		mSelect = obj.getObjectByName("ButtonA").toMesh();
		mBack = obj.getObjectByName("ButtonB").toMesh();
		mUp = obj.getObjectByName("ButtonUp").toMesh();
		buttonTex = [];

		buttonTex.push([game.getTexFromPath("UI/CharacterSelect/ButtonA01.png"), game.getTexFromPath("UI/CharacterSelect/ButtonA02.png")]);
		buttonTex.push([game.getTexFromPath("UI/CharacterSelect/ButtonB01.png"),game.getTexFromPath("UI/CharacterSelect/ButtonB02.png")]);
		buttonTex.push([game.getTexFromPath("UI/CharacterSelect/ButtonUp01.png"), game.getTexFromPath("UI/CharacterSelect/ButtonUp02.png")]);

		//iniy player 1
		addPlayer(0, ppos[0]);

		//game.setAmbient(0);
	}

	public static function getAnim(path : String) {
		var name = path.split("/").pop();
		var frames = [];
		var loop = false;
		while(true) {
			var n = (frames.length < 9 ? "0" : "") + (frames.length + 1);
			var tex = null;
			if(frames.length == 0) 
				tex = Game.inst.getTexFromPath(path+"[" + n + "]L.png"); //has loop flag [xx]L?
			if(tex != null)
				loop = true;
			else tex = Game.inst.getTexFromPath(path+"[" + n + "].png");
			if(tex == null) break;
			frames.push(tex);
		}

		texAnim.set(name, {frames : frames, loop : loop});
	}

	public static function playAnim(name : String, parent : h3d.scene.Mesh, ?onStop : Void -> Bool, ?onEnd : Void -> Void) {
		var a = texAnim.get(name);
		if(a == null) return;
					
		var t = 0.;
		Game.inst.event.waitUntil(function(dt) {
			if(onStop != null && onStop()) return true;
			t += dt / 60;
			var n = Std.int(30 * t);
			if(n >= a.frames.length) {
				if(onEnd != null) onEnd();
				if(!a.loop) return true;
				n -= a.frames.length;
				t = n * 30;
			}
			parent.material.texture = a.frames[n];
			return false;
		});
	}

	function addPlayer(id, o : h3d.scene.Object) {
		var p = new PlayerSlot(id, o);
		p.state = 1;
		players[id] = p;
		return p;
	}

	function nextStep() {
		game.state.players = [];
		for(p in players) {
			var k = p.getKind();
			var props : ent.Unit.Props = {kind : p.state <= 1 ? IA : Player, modelId : k, colorId : p.colorId};
			if(k != null) game.state.players[p.pid] = props;
		}
		new ui.ChooseArena();
		remove();
	}

	override public function onRemove() {
		super.onRemove();
		obj.remove();
		for(p in players)
			p.remove();
		ready = false;
	}


	var allChars = Data.chars.all;
	function isValidId(id : Int) {
		for(c in allChars)
			if(c.selectId == id) return true;
		return false;
	}

	var time = 0.;
	override function update(dt : Float) {
		super.update(dt);
		time += dt;

		var c = game.controllers[0];
		if(c != null) 
			c.active = true;

		for(i in 0...4) {
			var c = game.controllers[i];
			if(players[i] == null) addPlayer(i, ppos[i]);
			var pl = players[i];
			if(c != null && c.active) {
				if(pl.state == 1) {
					if(c.pressed.xAxis > 0 )
						do pl.selectId = pl.selectId >= mthumbs.length ? 1 : pl.selectId + 1 while(!isValidId(pl.selectId));
					else if(c.pressed.xAxis < 0)
						do pl.selectId = pl.selectId <= 1 ? mthumbs.length : pl.selectId - 1 while(!isValidId(pl.selectId));
					if(c.pressed.yAxis > 0 )
						pl.colorId = pl.colorId == slotTex.length - 1 ? 0 : pl.colorId + 1;
					else if(c.pressed.yAxis < 0)
						pl.colorId = pl.colorId == 0 ? slotTex.length - 1 : pl.colorId - 1;
				}

				if(ready) {
					if(c.pressed.A) {
						pl.state = hxd.Math.imin(3, pl.state + 1);

						if(pl.state == 3) {
							var allReady = true;
							for(i in 0...game.controllers.length)
								if(game.controllers[i].active && players[i] != null) {
									if(players[i].state < 2)
										allReady = false;
								}
							if(allReady)
								nextStep();	
						}
						/*
						if(pl.state == 2 && pl.selectId == Data.chars.get(Random).selectId) {
							var all = Data.chars.all;
							while(true) {
								var ch = all[Std.random(all.length - 1)];
								if(ch.selectId != pl.selectId) {
									pl.selectId = ch.selectId; //change id to update model kind
									pl.selectId = Data.chars.get(Random).selectId; //restore selected cursor
									break;
								}
							}
						}*/
					}
					if(c.pressed.B) {
						if(i == 0 && pl.state == 0) {
							//main player : back to menu
							new ui.Title();
							remove();
						}						
						pl.state = hxd.Math.imax(0, pl.state - 1);
					}
					if(pl.state != 0)
						pl.setPos(mthumbs[pl.selectId - 1]);
				}
			}
			else pl.state = 0;

			/////
			// pl.state = 0 -> show join
			// pl.state = 1 -> choose player + color
			// pl.state = 2 -> ready
			pl.visible = pl.state != 0;
			pjoin[i].visible = pl.state == 0;
			pname[i].material.texture = nameTex[pl.selectId - 1];
			pname[i].visible = pl.visible;
			ppower[i].visible = pl.visible;
			if(pl.state >= 2) {
				if(ppower[i].material.texture == pl.powerTex)
					playAnim("PowerReady", ppower[i], function() {return pl.state < 2;});
			}
			else {
				ppower[i].material.texture = pl.powerTex;
				pstate[i].material.texture = stateTex[c != null && c.active ? i + 1 : 0];
				pslot[i].material.texture = slotTex[pl.colorId];
			}

			//
			mSelect.material.texture = buttonTex[0][(time % 40) < 20 ? 1 : 0];
			mBack.material.texture = buttonTex[1][(time % 40) < 20 ? 0 : 1];
			mUp.material.texture = buttonTex[2][((10 + time) % 40) < 20 ? 0 : 1];
		}

		for(p in players)
			p.update(dt);

		
		for(i in 0...game.controllers.length) {
			if(i == 0) {
				game.controllers[0].active = true;
				continue;
			}
			var pl = players[i];
			var c = game.controllers[i];
			if(c.pressed.start || (c.pressed.A && pl.state == 0)) {
				//Sounds.play("Select");
				if(!c.active) {
					c.active = true;
					pl.state = 1;
				}
			}
			if(c.pressed.back || (c.pressed.B && pl.state <= 1)) {
				//Sounds.play("Select");
				c.active = false;
				pl.state = 0;
			}
		}
	}
}