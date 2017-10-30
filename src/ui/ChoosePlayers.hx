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

	public var pid : Int;
	public var selectId(default, set) : Int;
	public var state(default, set) : Int;
	public var visible(default, set) : Bool;
	public var color = 0;

	public function new(pid, follow) {
		game = Game.inst;
		this.pid = pid;
		this.follow = follow;

		while(true) {
			var id = chars[Std.random(chars.length)].selectId;
			if(id != Data.chars.get(Random).selectId) {
				selectId = id;
				break;
			}
		}
	}

	public function getKind() {
		return charKind;
	}

	function getModel() {
		for(c in chars)
			if(c.selectId == selectId)
				return hxd.Res.load("Chars/" + c.id.toString() + "01/Model.FBX").toModel();
		return null;
	}

	function getAnimSelection() {
		for(c in chars)
			if(c.selectId == selectId)
				return hxd.Res.load("Chars/" + c.id.toString() + "01/Anim_selection.FBX").toModel();
		return null;
	}

	function updateModel () {
		if(obj != null)
			obj.remove();
		res = getModel();
		if(res == null) return;

		obj = game.modelCache.loadModel(res);
		var a = game.modelCache.loadAnimation(getAnimSelection());
		obj.playAnimation(a);
		obj.currentAnimation.setFrame(Std.random(a.frameCount));
		obj.currentAnimation.speed *= 1 - hxd.Math.random(0.1);
		for(m in obj.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(obj);
		obj.follow = follow;

		for(c in chars)
			if(c.selectId == selectId) {
				charKind =  c.id;
				break;
			}
	}

	function set_selectId(v : Int) {
		if(selectId == v) return v;
		selectId = v;
		if(selectId != Data.chars.get(Random).selectId)
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
	}

	function removeSelector(){
		if(selector == null) return;
		selector.remove();
		selector = null;
	}

	public function setPos(o : h3d.scene.Object) {
		var pos = o.getAbsPos();
		selector.x = pos.tx;
		selector.y = pos.ty;
		selector.z = pos.tz;
	}

	public function remove() {
		if(obj != null) obj.remove();
		removeSelector();
	}
}

class ChoosePlayers extends ui.Form
{
	var obj : h3d.scene.Object;
	var pname : Array<h3d.scene.Mesh> = [];
	var pjoin : Array<h3d.scene.Mesh> = [];
	var pstate : Array<h3d.scene.Mesh> = [];
	var ppos : Array<h3d.scene.Object> = [];
	var mthumbs : Array<h3d.scene.Object> = [];
	var ready = false;


	var mSelect : h3d.scene.Mesh;
	var mBack : h3d.scene.Mesh;

	var nameTex : Array<h3d.mat.Texture> = [];
	var stateTex : Array<h3d.mat.Texture> = [];
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

		for(m in obj.getMeshes())
			m.material.shadows = false;

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
			pstate.push(obj.getObjectByName("StateP" + (i + 1)).toMesh());
			ppos.push(obj.getObjectByName("PosP" + (i + 1)));
		}

		stateTex.push(hxd.Res.UI.CharacterSelect.StateCPU.toTexture());
		for(i in 0...4)
			stateTex.push(hxd.Res.load("UI/CharacterSelect/StateP" + (i + 1) + ".png").toTexture());


		//
		mSelect = obj.getObjectByName("ButtonA").toMesh();
		mBack = obj.getObjectByName("ButtonB").toMesh();
		buttonTex = [];
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonA01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonA02.toTexture()]);
		buttonTex.push([hxd.Res.UI.CharacterSelect.ButtonB01.toTexture(), hxd.Res.UI.CharacterSelect.ButtonB02.toTexture()]);

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
			var props : ent.Fairy.Props = {kind : p.state <= 1 ? IA : Player, modelId : k, color : 0};
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
					if(c.pressed.xAxis > 0 || c.pressed.yAxis > 0)
						pl.selectId = pl.selectId >= mthumbs.length ? 1 : pl.selectId + 1;
					else if(c.pressed.xAxis < 0 || c.pressed.yAxis < 0)
						pl.selectId = pl.selectId <= 1 ? mthumbs.length : pl.selectId - 1;
				}

				if(c.pressed.A) {
					pl.state = hxd.Math.imin(3, pl.state + 1);
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
					}
				}
				if(c.pressed.B)
					pl.state = hxd.Math.imax(0, pl.state - 1);
				if(ready && pl.state != 0)
					pl.setPos(mthumbs[pl.selectId - 1]);
			}
			else pl.state = 0;

			/////
			// pl.state = 0 -> show join
			// pl.state = 1 -> choose player
			// pl.state = 2 -> ready
			pl.visible = pl.state != 0;
			pjoin[i].visible = pl.state == 0;
			pname[i].material.texture = nameTex[pl.selectId - 1];
			pname[i].visible = pl.visible;
			if(pl.state == 2)
				pstate[i].material.texture = hxd.Res.UI.CharacterSelect.ButtonOk.toTexture();
			else pstate[i].material.texture = stateTex[c != null && c.active ? i + 1 : 0];

			//
			mSelect.material.texture = buttonTex[0][(time % 40) < 20 ? 1 : 0];
			mBack.material.texture = buttonTex[1][(time % 40) < 20 ? 0 : 1];
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