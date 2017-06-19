package ui;
import hxd.Key in K;
import Sounds;

class PlayerSlot {
	var game : Game;
	var obj : h3d.scene.Object;
	var id : Int;
	public var state = 0;
	public var color = 0;

	public function new(id, follow) {
		game = Game.inst;
		this.id = id;
		obj = game.modelCache.loadModel(hxd.Res.Chars.KingKnight01.Model);
		for(m in obj.getMeshes())
			m.material.shadows = false;
		game.s3d.addChild(obj);
		obj.follow = follow;
	}

	public function remove() {
		obj.remove();
	}
}

class ChoosePlayers extends ui.Form
{
	var obj : h3d.scene.Object;
	var pname : Array<h3d.scene.Mesh> = [];
	var pbutton : Array<h3d.scene.Mesh> = [];
	var pjoin : Array<h3d.scene.Mesh> = [];
	var pselector : Array<h3d.scene.Mesh> = [];
	var pstate : Array<h3d.scene.Mesh> = [];
	var ppos : Array<h3d.scene.Object> = [];
	var ready = false;

	var stateTex : Array<h3d.mat.Texture> = [];
	var buttonTex : Array<h3d.mat.Texture> = [];

	var players : Array<PlayerSlot> = [];

	override function init() {
		super.init();
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

		for(i in 0...4) {
			pname.push(obj.getObjectByName("NameP" + (i + 1)).toMesh());
			pjoin.push(obj.getObjectByName("JoinP" + (i + 1)).toMesh());
			pbutton.push(obj.getObjectByName("ButtonP" + (i + 1)).toMesh());
			pselector.push(obj.getObjectByName("SelectorP" + (i + 1)).toMesh());
			pstate.push(obj.getObjectByName("StateP" + (i + 1)).toMesh());
			ppos.push(obj.getObjectByName("PosP" + (i + 1)));
		}

		stateTex.push(hxd.Res.UI.CharacterSelect.StateCPU.toTexture());
		for(i in 0...4)
			stateTex.push(hxd.Res.load("UI/CharacterSelect/StateP" + (i + 1) + ".png").toTexture());

		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX01.toTexture());
		buttonTex.push(hxd.Res.UI.CharacterSelect.ButtonX02.toTexture());

		//game.setAmbient(0);
	}

	function nextStep() {
		game.state.nbPlayers = 1;
		//new ui.ChooseArena();
		game.state.arenaId = 0;
		game.restart();
		remove();
	}

	override public function onRemove() {
		super.onRemove();
		obj.remove();
	}

	var time = 0.;
	override function update(dt : Float) {
		super.update(dt);
		time += dt;

		var c = game.controllers[0];
		if(c != null) {
			c.active = true;
			//if(c.pressed.B || K.isPressed(K.BACKSPACE)) btBack.onClick();
			 if(c.pressed.A || K.isPressed(K.ENTER) || K.isPressed(K.SPACE)) {
				var pl = players[0];
				switch(pl.state) {
					case 0 :
						pl.state++;
					case 1 :
						pl.state++;
					default :
						nextStep();
				}
			 }
		}

		for(i in 0...4) {
			var c = game.controllers[i];
			if(players[i] == null) players[i] = new PlayerSlot(i, ppos[i]);
			var pl = players[i];

			var join = pjoin[i];
			join.visible = c == null || !c.active;

			//TODO : pl.state = 0 -> choix player : pas de join
			// pl.state = 1 -> choix color : join = Colorselect
			// pl.state = 2 -> ready : join = buttonOk

			//pjoin[i].setScale(1 + 0.008 * Math.sin(0.1 * time)); //NON : faire une translation vers la camera (?)
			pbutton[i].material.texture = buttonTex[(time % 40) < 20 ? 1 : 0];
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