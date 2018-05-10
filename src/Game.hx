import hxd.Key in K;
import hxd.Res;
import lib.Controller;
import map.CustomScene;
import map.WorldComposite;
import map.World;
//import Sounds;
import ui.GameUI;
import ui.Win;

enum CameraKind {
	Menu;
	Choose;
}

enum FontKind {
	Default;
	Corner;
}

class MyModelCache extends h3d.prim.ModelCache {

	override public function loadModel(res:hxd.res.Model):h3d.scene.Object {
		var m = super.loadModel(res);
		for( mat in m.getMaterials() )
			mat.texture.filter = Nearest;
		return m;
	}

	override public function loadTexture(model:hxd.res.Model, texturePath):h3d.mat.Texture {
		var tex = super.loadTexture(model, texturePath);
		if(tex != null)	tex.filter = Nearest;
		return tex;
	}
}

class Game extends hxd.App {

	static public var PREFS = initPrefs();
	static function initPrefs() {
		var prefs = { fullScreen : #if hl false #else true #end, music : true };
		prefs = hxd.Save.load(prefs, "prefs");
		return prefs;
	}

	public var modelCache : MyModelCache;
	public var event : hxd.WaitEvent;
	public var world : map.World;
	public var entities : Array<ent.Entity>;
	public var players : Array<ent.Unit>;
	public var bonus : Array<ent.Energy>;
	public var worldRenderer : map.WorldComposite;
	public var uiRenderer : map.UIComposite;
	public var customScene : map.CustomScene;

	public var size = 60;
	var camPos : h3d.col.Point;
	var camTarget : h3d.col.Point;
	var camPosOffset : h3d.col.Point;
	var camTargetOffset : h3d.col.Point;
	public var autoCameraKind : CameraKind;

	var camDist = 4;
	var camZ = 5.5;

	public var bmpViews : Array<h2d.Bitmap>;

	var pause = false;
	public var gameOver = true;
	var IAOnly = false;

	public var windows : Array<ui.Form>;
	var ui : ui.GameUI;
	var blackScreen : h2d.Bitmap;

	var bonusMaxCount : Int = 25;

	public var state : {players : Array<ent.Unit.Props>, arenaId : Int, stars : Array<Int>};

	public var controllers : Array<lib.Controller> = [];
	public var keys : lib.Controller;

	var ambient = [];
	var ambientId = 0;

	var hideEntities = false;

	override function init() {
		customScene = new map.CustomScene();
		setScene(customScene);
		worldRenderer = new map.WorldComposite();

		uiRenderer = new map.UIComposite();
		s3d.renderer = uiRenderer;

		s3d.lightSystem = new h3d.pass.LightSystem();
		var t = new shaders.CellShader();
		t.shadowColor.setColor(0xD0BFDE);
		@:privateAccess {
			s3d.lightSystem.ambientShader = t;
			s3d.lightSystem.perPixelLighting = true;
		}

		var dir = new h3d.Vector(-9.7, -1.25, -1.6);
		new h3d.scene.DirLight(dir, s3d);

		/*
		try {
			ambient.push(haxe.Json.parse(hxd.Res.load("title.js").entry.getText()));
			ambient.push(haxe.Json.parse(hxd.Res.load("ambient.js").entry.getText()));
			ambientId = 0;
		}
		catch(e : hxd.res.NotFound) {};
		*/

		modelCache = new MyModelCache();
		event = new hxd.WaitEvent();

		event.waitUntil(function(dt) {
			if(hxd.Key.isDown(K.NUMPAD_1)) { dir.x -= 0.02 * dt;	trace(dir); };
			if(hxd.Key.isDown(K.NUMPAD_2)) { dir.x += 0.02 * dt;	trace(dir); };
			if(hxd.Key.isDown(K.NUMPAD_4)) { dir.y -= 0.02 * dt;	trace(dir); };
			if(hxd.Key.isDown(K.NUMPAD_5)) { dir.y += 0.02 * dt;	trace(dir); };
			if(hxd.Key.isDown(K.NUMPAD_7)) { dir.z -= 0.02 * dt;	trace(dir); };
			if(hxd.Key.isDown(K.NUMPAD_8)) { dir.z += 0.02 * dt;	trace(dir); };
			//if(hxd.Key.isDown(K.NUMPAD_ADD)) { t.alpha = hxd.Math.clamp(t.alpha + 0.01 * dt); trace(t.alpha); };
			//if(hxd.Key.isDown(K.NUMPAD_SUB)) { t.alpha = hxd.Math.clamp(t.alpha - 0.01 * dt); trace(t.alpha); };
			return false;
		});



		//world = new map.World(size, 0);
		entities = [];
		players = [];
		bonus = [];
		bmpViews = [];

		state = {players : [], arenaId : 0, stars : [0, 0, 0, 0]};

		windows = [];

		hxd.Pad.wait(function(p) {
			controllers.push(new lib.Controller(controllers.length, p));
			if(controllers.length == 1)
				keys = controllers[0];
		});
/*
		if(PREFS.music)
			Sounds.play("Loop");*/

		transition(function() {
			//new ui.Menu();
			new ui.ChoosePlayers();
		} ,false);
	}

	public static function savePrefs() {
		hxd.Save.save(PREFS, "prefs");
	}

	public function text(str : String, ?kind : FontKind, ?parent) {
		var tf = new h2d.Text(resolveFont(kind), parent);
		tf.text = str;
		return tf;
	}

	inline function resolveFont(kind : FontKind) {
		if(kind == null) kind = Default;
		var res = switch(kind) {
			case Corner : hxd.Res.font.poetsen_one_regular_65;
			case Default : hxd.Res.font.poetsen_one_regular_32;
		}
		return res.toFont();
	}

	public function transition(?onReady : Void -> Void, ?onDone : Void -> Void, fadeIn = true ) {
		blackScreen = new h2d.Bitmap(h2d.Tile.fromColor(0xFFFFFF), s2d);
		blackScreen.scaleX = s2d.width;
		blackScreen.scaleY = s2d.height;
		blackScreen.alpha = fadeIn ? 0 : 1;
		event.waitUntil(function(dt) {
			blackScreen.alpha = Math.min(1, blackScreen.alpha + 0.1 * dt);
			if(blackScreen.alpha == 1) {
				if(onReady != null) onReady();
				event.wait(0.2, function() {
					event.waitUntil(function(dt) {
						if(blackScreen == null) return true;
						blackScreen.alpha = Math.max(0, blackScreen.alpha - 0.1 * dt);
						if(blackScreen.alpha == 0) {
							blackScreen.remove();
							blackScreen = null;
							if(onDone != null) onDone();
							return true;
						}
						return false;
					});
				});
				return true;
			}
			return false;
		});
	}

	public function getTexFromPath(path : String){
		var res = try hxd.Res.load(path) catch(e : hxd.res.NotFound) null;
		if(res == null) return null;
		var tex = res.toTexture();
		tex.filter = Nearest;
		return tex;
	}

	public function endGame() {
		transition(function() {
			reset();
			new ui.Win();
			for( c in controllers)
				c.active = false;
			state.stars = [0, 0, 0, 0];
			gameOver = true;
		}, true);
	}

	public function choose() {
		reset();
		new ui.ChoosePlayers();
	}

	public function restart() {
		transition(function() {
			reset();
			start();
		}, false);
	}

	function reset() {
		autoCameraKind = null;
		while(entities.length > 0)
			entities.pop().remove();
		while(players.length > 0)
			players.pop().remove();
		while(bonus.length > 0)
			bonus.pop().remove();
		while(bmpViews.length > 0)
			bmpViews.pop().remove();
		for(w in windows) w.remove();
		if(ui != null) ui.remove();
		customScene.clearViews();

		if(controllers.length > 0)
			controllers[0].active = true;

		if(world != null) {
			world.reset();
			s3d.renderer = new h3d.scene.Renderer();
		}
	}

	function start(){
		entities = [];
		autoCameraKind = null;
		if(world != null) world.remove();
		world = new map.World(size, state.arenaId );
		s3d.renderer = worldRenderer;

		var nbPlayers = 0;
		for(p in state.players)
			if(p.kind == Player) nbPlayers++;

//nbPlayers = 4;

		switch(nbPlayers) {
			case 1 : worldRenderer.width = 0; worldRenderer.height = 0;
			case 2 : worldRenderer.width = 1; worldRenderer.height = 0;
			case 3, 4 : worldRenderer.width = 1; worldRenderer.height = 1;
			default : worldRenderer.width = 0; worldRenderer.height = 0;
		}

		var allChars = Data.chars.all;
		function addPlayer(k : ent.Entity.EntityKind, dir : h3d.col.Point, ?props : ent.Unit.Props) {
			if(props == null)
				props = {kind : k, modelId : allChars[Std.random(allChars.length)].id, colorId : 0 };
			var pl = k == Player ? new ent.Player(props, dir) : new ent.IA(props, dir);
			players.push(pl);
			var cam = initCamera(pl);

			if(players.length <= nbPlayers) {
				var tex = new h3d.mat.Texture(s2d.width >> worldRenderer.width, s2d.height >> worldRenderer.height, [Target]);
				customScene.addView(pl.id, cam, tex);
				var b = new h2d.Bitmap(h2d.Tile.fromTexture(tex), s2d);
				b.blendMode = None;
				bmpViews.push(b);
			}
			return pl;
		}

		var dirs = [
			new h3d.col.Point(1, 0, 0),
			new h3d.col.Point( -1, 0, 0),
			new h3d.col.Point(0, 1, 0),
			new h3d.col.Point(0, -1, 0)
			];


		for(i in 0...state.players.length) {
			var p = state.players[i];
			addPlayer(p.kind, dirs.shift(), p);
		}

		for(c in controllers) {
			if(c.active)
				players[c.id].controller = c;
		}

		if(ui != null) ui.remove();
		ui = new ui.GameUI();
		onResize();
	}

	public function setAmbient(id) {
		if(ambientId == id) return;
		if(ambient.length <= id) return;
		ambientId = id;
	}

	public function initCamera(pl : ent.Unit) {
		setCameraValues(pl);
		var cam = new h3d.Camera();
		cam.pos.x = camPos.x;
		cam.pos.y = camPos.y;
		cam.pos.z = camPos.z;
		cam.target.x = camTarget.x;
		cam.target.y = camTarget.y;
		cam.target.z = camTarget.z;
		cam.fovY = 80;
		var pn = pl.worldNormal;
		cam.up.x = pn.x;
		cam.up.y = pn.y;
		cam.up.z = pn.z;

		var decal = camZ * 0.75;
		var n = new h3d.Vector(cam.pos.x - cam.target.x, cam.pos.y - cam.target.y, cam.pos.z - cam.target.z);
		var d = camDist + decal;
		if(n.x * n.x + n.y * n.y + n.z * n.z < d * d) {
			n.normalize();
			cam.pos.x = cam.target.x + n.x * d;
			cam.pos.y = cam.target.y + n.y * d;
			cam.pos.z = cam.target.z + n.z * d;
		}
		return cam;
	}

	function setCameraValues(pl : ent.Unit) {
		var pn = pl.worldNormal;
		var dir = pl.dir;
		var decal = camZ * 0.75;

		camPosOffset = new h3d.col.Point( -camDist * dir.x + camZ * pn.x, -camDist * dir.y + camZ * pn.y, -camDist * dir.z + camZ * pn.z);
		camTargetOffset = new h3d.col.Point(decal * pn.x, decal * pn.y, decal * pn.z);
		camPos = new h3d.col.Point(pl.x + camPosOffset.x, pl.y + camPosOffset.y, pl.z  + camPosOffset.z);
		camTarget = new h3d.col.Point(pl.x + camTargetOffset.x, pl.y + camTargetOffset.y, pl.z  + camTargetOffset.z);
	}

	function updatePlayerCamera(pl : ent.Unit, dt : Float) {
		setCameraValues(pl);

		var pn = pl.worldNormal;
		var decal = camZ * 0.75;

		var sp = 0.15 * dt;
		var v = customScene.getView(pl.id);
		if(v == null) return null;
		var cam = v.camera;

		cam.pos.x += (camPos.x - cam.pos.x) * sp;
		cam.pos.y += (camPos.y - cam.pos.y) * sp;
		cam.pos.z += (camPos.z - cam.pos.z) * sp;
		cam.target.x += (camTarget.x - cam.target.x) * sp;
		cam.target.y += (camTarget.y - cam.target.y) * sp;
		cam.target.z += (camTarget.z - cam.target.z) * sp;

		var n = new h3d.Vector(cam.pos.x - cam.target.x, cam.pos.y - cam.target.y, cam.pos.z - cam.target.z);
		var d = camDist + decal;
		if(n.x * n.x + n.y * n.y + n.z * n.z < d * d) {
			n.normalize();
			cam.pos.x = cam.target.x + n.x * d;
			cam.pos.y = cam.target.y + n.y * d;
			cam.pos.z = cam.target.z + n.z * d;
		}

		cam.up.x += (pn.x - cam.up.x) * sp * 0.5;
		cam.up.y += (pn.y - cam.up.y) * sp * 0.5;
		cam.up.z += (pn.z - cam.up.z) * sp * 0.5;


		cam.target.x += pshake.x;
		cam.pos.x += pshake.y;
		cam.target.y += pshake.y;
		cam.pos.y += pshake.x;
		cam.target.z += pshake.y;
		cam.pos.z += pshake.y;

		return cam;
	}

	var camRot = -1.;
	function autoCameraUpdate(dt : Float) {
		var cam = s3d.camera;
		cam.up.x = 0;
		cam.up.y = 0;
		cam.up.z = 1;
		switch(autoCameraKind) {
			case Menu:
				cam.pos.x = 12 * Math.cos(camRot);
				cam.pos.y = 12 * Math.sin(camRot);
				cam.pos.z = 12 - (size >> 1);
				cam.target.x = 0;
				cam.target.y = 0;
				cam.target.z = 10 - size >> 1;
				cam.fovY = 90;
				camRot += 0.0025 * dt;
			case Choose:
				cam.fovY = 11.5;
			default: trace("TODO");
		}
	}

	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code)) {
			engine.fullScreen = !engine.fullScreen;
		}

		if(K.isPressed("P".code))
			pause = !pause;

		if(K.isPressed(K.F1) && !gameOver) {
			hideEntities = !hideEntities;
			for(e in entities)
				@:privateAccess e.obj.visible = !hideEntities;
			for(w in world.walls)
				w.w.visible = !hideEntities;
		}

	}

	override function update(dt:Float) {
		for(c in controllers)
			c.update(dt);

		for(w in windows)
			w.update(dt);

		//admin
		if( K.isDown(K.SHIFT)) {
			var speed = K.isDown(K.CTRL) ? 0.1 : 5;
			hxd.Timer.deltaT *= speed;
			hxd.Timer.tmod *= speed;
			dt *= speed;
		}
		//

		super.update(dt);
		event.update(dt);

		if(autoCameraKind != null)
			autoCameraUpdate(dt);

		if(blackScreen != null)
			return;

		updateKeys(dt);

		if(pause) return;

		for( pl in players)
			updatePlayerCamera(pl, dt);

		for(e in entities)
			e.update(dt);

		if(ui != null)
			ui.update(dt);

		if(!gameOver) {
			if(bonus.length < bonusMaxCount && Math.random() < 0.05) {
				var b = new ent.Energy();
				if(world.collideBounds(b.getBounds()))
					b.remove();
			}
			if(players.length == 1) {
				gameOver = true;
				ui.nextRound(players[0]);
			}
		}
	}

	var pshake = new h2d.col.Point();
	public function shake(pow = 0.1, fade = 0.8) {
		pshake.x = 0;
		pshake.y = 0;

		event.waitUntil(function(dt) {
			pshake.x = hxd.Math.srand(pow);
			pshake.y = hxd.Math.srand(pow);
			pow *= Math.pow(fade, dt);
			if(pow < 0.01) {
				pshake.x = pshake.y = 0;
				return true;
			}
			return false;
		});
	}

	override function onResize() {
		super.onResize();
		if(blackScreen != null) {
			blackScreen.scaleX = s2d.width;
			blackScreen.scaleY = s2d.height;
		}

		for( w in windows)
			w.onResize();

		//
		var hasUIOver = false;
		for(i in 0...customScene.views.length) {
			var v = customScene.views[i];
			v.target.dispose();

			if(v.id == -1) {
				//ui
				v.target = new h3d.mat.Texture(s2d.width, s2d.height, [Target]);
				v.target.clear(0, 0);
				hasUIOver = true;
			}
			else {
				//player
				v.target = new h3d.mat.Texture(s2d.width >> worldRenderer.width, s2d.height >> worldRenderer.height, [Target]);
			}
			bmpViews[i].tile = h2d.Tile.fromTexture(v.target);
		}

		for(i in 0...bmpViews.length - (hasUIOver ? 1 : 0)) {
			var b = bmpViews[i];
			switch(i){
				case 1 :
					b.x = s2d.width >> 1;
				case 2 :
					b.y = s2d.height >> 1;
				case 3 :
					b.x = s2d.width >> 1;
					b.y = s2d.height >> 1;
				default:
			}
		}
	}

	public static var inst : Game;
	static function main() {
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		Data.load(hxd.Res.data.entry.getText());
		Texts.load(hxd.Res.texts.entry.getText());
		inst = new Game();
	}

}