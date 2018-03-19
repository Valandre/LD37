package ui;
import hxd.Key in K;
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
/*
		for(m in obj.getMeshes())
			m.material.shadows = false;
*/
		var res = try {hxd.Res.load("Chars/" + charKind + "01/Texture01_normal.png"); } catch(e : Dynamic) {null;}
		if(res != null) {
			var tex = res.toTexture();
			for(m in obj.getMeshes()) {

				m.material.mainPass.addShader(new shaders.NormalMap(tex));
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
					p.depthWrite = false;
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
		for(m in selector.getMeshes()) {
			m.material.shadows = false;
			m.material.texture = hxd.Res.load("UI/Selector/SelectorP" + (pid + 1) + ".png").toTexture();
		}
		game.s3d.addChild(selector);
		selector.visible = false;
	}

	function removeSelector(){
		if(selector == null) return;
		selector.remove();
		selector = null;
	}

	var posInitialized = false;
	public function setPos(o : h3d.scene.Object) {
		var pos = o.getAbsPos();
		var curId = selectId;

		selector.visible = true;
		if(!posInitialized) {
			posInitialized = true;
			selector.x = pos.tx;
			selector.y = pos.ty;
			selector.z = pos.tz;
			return;
		}

		game.event.waitUntil(function(dt) {
			if(curId != selectId) return true;
			selector.x += (pos.tx - selector.x) * 0.5 * dt;
			selector.y += (pos.ty - selector.y) * 0.5 * dt;
			selector.z += (pos.tz - selector.z) * 0.5 * dt;

			return(pos.tx - selector.x < 0.01 && pos.ty - selector.y < 0.01 && pos.tz - selector.z < 0.01);
		});
	}

	public function remove() {
		if(obj != null) obj.remove();
		removeSelector();
	}
}

class ChoosePlayers extends ui.Form
{
	var pname : Array<h3d.scene.Mesh> = [];
	var pjoin : Array<h3d.scene.Mesh> = [];
	var pstate : Array<h3d.scene.Mesh> = [];
	var pslot : Array<h3d.scene.Mesh> = [];
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

	var players : Array<PlayerSlot> = [];
	var CharsIds : Array<Int> = [];

	override function init() {
		super.init();

		//init scene
		var m = hxd.Res.UI.CharacterSelect.Model;
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
/*
		for(m in obj.getMeshes())
			m.material.shadows = false;
*/
		addBg();

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;
		game.s3d.lightSystem.ambientLight.setColor(0xFFFFFF);

		var i = 0;
		while(true) {
			var o = obj.getObjectByName("PosThumb" + ((i < 9 ? "0" : "") + (i + 1)));
			if(o == null) break;
			mthumbs.push(o);

			var name = null;
			try {
				name = hxd.Res.load("UI/CharacterSelect/Name" + ((i < 9 ? "0" : "") + (i + 1)) + ".png").toTexture();
			}
			catch(e:hxd.res.NotFound) {};
			nameTex.push(name);
			i++;
		}

		for(i in 0...4) {
			pname.push(obj.getObjectByName("NameP" + (i + 1)).toMesh());
			pjoin.push(obj.getObjectByName("JoinP" + (i + 1)).toMesh());
			pslot.push(obj.getObjectByName("SlotP" + (i + 1)).toMesh());
			pstate.push(obj.getObjectByName("StateP" + (i + 1)).toMesh());
			ppos.push(obj.getObjectByName("PosP" + (i + 1)));
		}

		stateTex.push(hxd.Res.UI.CharacterSelect.StateCPU.toTexture());
		for(i in 0...4)
			stateTex.push(hxd.Res.load("UI/CharacterSelect/StateP" + (i + 1) + ".png").toTexture());


		for(i in 0...9)
			slotTex.push(hxd.Res.load("UI/CharacterSelect/Slot0" + (i + 1) + ".png").toTexture());
		pslot[0].material.texture = slotTex[1];
		pslot[1].material.texture = slotTex[3];
		pslot[2].material.texture = slotTex[4];
		pslot[3].material.texture = slotTex[7];


		//
		mSelect = obj.getObjectByName("ButtonA").toMesh();
		mBack = obj.getObjectByName("ButtonB").toMesh();
		mUp = obj.getObjectByName("ButtonUp").toMesh();
		buttonTex = [];
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonA01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonA02.toTexture()]);
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonB01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonB02.toTexture()]);
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonUp01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonUp02.toTexture()]);

		//iniy player 1
		addPlayer(0, ppos[0]);

		//game.setAmbient(0);
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
		if(c != null) {
			c.active = true;
			var pl = players[0];
			if(pl.state == 3)
				nextStep();
		}

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
					if(c.pressed.B)
						pl.state = hxd.Math.imax(0, pl.state - 1);
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
			if(pl.state >= 2)
				pstate[i].material.texture = hxd.Res.UI.CharacterSelect.ButtonOk.toTexture();
			else {
				pstate[i].material.texture = stateTex[c != null && c.active ? i + 1 : 0];
				pslot[i].material.texture = slotTex[pl.colorId];
			}

			//
			mSelect.material.texture = buttonTex[0][(time % 40) < 20 ? 1 : 0];
			mBack.material.texture = buttonTex[1][(time % 40) < 20 ? 0 : 1];
			mUp.material.texture = buttonTex[2][((10 + time) % 40) < 20 ? 0 : 1];
		}

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