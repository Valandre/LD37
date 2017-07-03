package ui;
import hxd.Key in K;
import Sounds;

class PlayerSlot {
	var game : Game;
	var obj : h3d.scene.Object;
	var selector : h3d.scene.Object;
	var id : Int;

	public var selectId : Int = 3;
	public var state(default, set) : Int;
	public var color = 0;

	public function new(id, follow) {
		game = Game.inst;
		this.id = id;
		obj = game.modelCache.loadModel(hxd.Res.Chars.Emperor01.Model);
		var a = game.modelCache.loadAnimation(hxd.Res.Chars.Emperor01.Anim_selection);
		obj.playAnimation(a);
		obj.currentAnimation.setFrame(Std.random(a.frameCount));
		obj.currentAnimation.speed *= 1 - hxd.Math.random(0.1);
		for(m in obj.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(obj);
		obj.follow = follow;
	}

	function set_state(v : Int) {
		if(state == v) return v;
		if(v == 0) removeSelector();
		else addSelector();
		return state = v;
	}

	function addSelector() {
		if(selector != null) return;
		var m = hxd.Res.UI.Selector.Model;
		selector = game.modelCache.loadModel(m);
		for(m in selector.getMeshes()) {
			m.material.shadows = false;
			m.material.texture = hxd.Res.load("UI/Selector/SelectorP" + (id + 1) + ".png").toTexture();
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
		obj.remove();
		removeSelector();
	}
}

class ChoosePlayers extends ui.Form
{
	var obj : h3d.scene.Object;
	var pname : Array<h3d.scene.Mesh> = [];
	var pbutton : Array<h3d.scene.Mesh> = [];
	var pjoin : Array<h3d.scene.Mesh> = [];
	var pstate : Array<h3d.scene.Mesh> = [];
	var ppos : Array<h3d.scene.Object> = [];
	var mthumbs : Array<h3d.scene.Object> = [];
	var ready = false;

	var joinTex : Array<h3d.mat.Texture> = [];
	var stateTex : Array<h3d.mat.Texture> = [];
	var buttonTex : Array<h3d.mat.Texture> = [];

	var players : Array<PlayerSlot> = [];

	var CharsIds : Array<Int> = [];

	override function init() {
		super.init();

		//init scene
		var m = hxd.Res.UI.CharacterSelect.Model;
		obj = game.modelCache.loadModel(m);
		var a = game.modelCache.loadAnimation(m);
		a.loop = false;
		obj.playAnimation(a);
		obj.currentAnimation.onAnimEnd = function() {
			ready = true;
		}

		for(m in obj.getMeshes())
			m.material.shadows = false;

		game.s3d.addChild(obj);
		game.s3d.camera.follow = {pos : obj.getObjectByName("CamScreen"), target : obj.getObjectByName("CamScreen.Target")};
		game.autoCameraKind = Choose;
		game.s3d.lightSystem.ambientLight.setColor(0xFFFFFF);

		for(i in 0...10)
			mthumbs.push(obj.getObjectByName("PosThumb" + ((i < 9 ? "0" : "") + (i + 1))));

		for(i in 0...4) {
			pname.push(obj.getObjectByName("NameP" + (i + 1)).toMesh());
			pjoin.push(obj.getObjectByName("JoinP" + (i + 1)).toMesh());
			pbutton.push(obj.getObjectByName("ButtonP" + (i + 1)).toMesh());
			pstate.push(obj.getObjectByName("StateP" + (i + 1)).toMesh());
			ppos.push(obj.getObjectByName("PosP" + (i + 1)));
		}

		stateTex.push(hxd.Res.UI.CharacterSelect.StateCPU.toTexture());
		for(i in 0...4)
			stateTex.push(hxd.Res.load("UI/CharacterSelect/StateP" + (i + 1) + ".png").toTexture());

		joinTex.push(hxd.Res.UI.CharacterSelect.Join.toTexture());
		joinTex.push(hxd.Res.UI.CharacterSelect.ColorSelect.toTexture());

		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX01.toTexture());
		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX02.toTexture());
		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonOk.toTexture());

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
		game.state.nbPlayers = 1;
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
			if(pl.state == 4)
				nextStep();
		}

		for(i in 0...4) {
			var c = game.controllers[i];
			if(players[i] == null) addPlayer(i, ppos[i]);
			var pl = players[i];
			if(c != null && c.active) {
				if(c.pressed.A)
					pl.state = hxd.Math.imin(4, pl.state + 1);
				if(c.pressed.B)
					pl.state = hxd.Math.imax(0, pl.state - 1);
				if(ready && pl.state != 0)
					pl.setPos(mthumbs[pl.selectId]);
			}

			/////
			// pl.state = 0 -> not a player : show join
			// pl.state = 1 -> choix player : pas de join
			// pl.state = 2 -> choix color : join = Colorselect
			// pl.state = 3 -> ready : join = buttonOk

			var join = pjoin[i];
			join.visible = true;
			switch(pl.state) {
				case 0 : join.material.texture = joinTex[0];
				case 2 : join.material.texture = joinTex[1];
				default: join.visible = false;
			}
			//join.setScale(1 + 0.008 * Math.sin(0.1 * time));

			var but = pbutton[i];
			switch(pl.state) {
				case 3 : but.material.texture = buttonTex[2];
				default: but.material.texture = buttonTex[(time % 40) < 20 ? 1 : 0];
			}
			pstate[i].material.texture = stateTex[c != null && c.active ? i + 1 : 0];
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