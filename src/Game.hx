import hxd.Key in K;
import hxd.Res;
import lib.Controller;
import map.CustomScene;
import map.Composite;
import map.World;
import Sounds;
import ui.Menu;
import ui.Scores;
import ui.Win;
import Const;

enum CameraKind {
	Menu;
	Choose;
}

enum FontKind {
	Default;
	Corner;
}

class Game extends hxd.App {

	static public var PREFS = initPrefs();
	static function initPrefs() {
		var prefs = { fullScreen : #if hl false #else true #end, music : true };
		prefs = hxd.Save.load(prefs, "prefs");
		return prefs;
	}

	public var COLORS = [0xFFFFFF, 0xFF511C, 0x02DAD8, 0xA1F522, 0xF5227A];

	public var modelCache : h3d.prim.ModelCache;
	public var event : hxd.WaitEvent;
	public var world : map.World;
	public var entities : Array<ent.Entity>;
	public var players : Array<ent.Fairy>;
	public var bonus : Array<ent.Bonus>;
	public var renderer : map.Composite;
	public var customScene : map.CustomScene;
	public var inspector : hxd.inspect.Inspector;

	public var size = 60;
	var camPos : h3d.col.Point;
	var camTarget : h3d.col.Point;
	var camPosOffset : h3d.col.Point;
	var camTargetOffset : h3d.col.Point;
	public var autoCameraKind : CameraKind;

	var camDist = 4;
	var camZ = 5.5;

	var bmpViews : Array<h2d.Bitmap>;

	var pause = false;
	var gameOver = true;
	var IAOnly = false;

	public var windows : Array<ui.Form>;
	var ui : ui.Scores;
	var blackScreen : h2d.Bitmap;

	var bonusMaxCount : Int = 10;

	public var state : {players : Array<ent.Fairy.Props>, arenaId : Int, stars : Array<Int>};

	public var controllers : Array<lib.Controller> = [];
	public var keys : lib.Controller;

	var ambient = [];
	var ambientId = 0;

	var hideEntities = false;

	override function init() {
		customScene = new map.CustomScene();
		setScene(customScene);
		renderer = new map.Composite();
		/*
		try {
			ambient.push(haxe.Json.parse(hxd.Res.load("title.js").entry.getText()));
			ambient.push(haxe.Json.parse(hxd.Res.load("ambient.js").entry.getText()));
			ambientId = 0;
			new hxd.inspect.SceneProps(s3d).applyProps(ambient[0].s3d, function(msg) trace(msg));
		}
		catch(e : hxd.res.NotFound) {};
		*/

		modelCache = new h3d.prim.ModelCache();
		event = new hxd.WaitEvent();

		//world = new map.World(size, 0);
		entities = [];
		players = [];
		bonus = [];
		bmpViews = [];

		state = {players : [], arenaId : 0, stars : [0, 0, 0, 0]};

		windows = [];
		//new ui.Menu();
		new ui.ChoosePlayers();

		hxd.Pad.wait(function(p) {
			controllers.push(new lib.Controller(controllers.length, p));
			if(controllers.length == 1)
				keys = controllers[0];
		});

		if(PREFS.music)
			Sounds.play("Loop");

		transition(false);
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
			entities[0].remove();
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
			s3d.renderer = null;
		}
	}

	function start(){
		entities = [];
		if(world != null) world.remove();
		world = new map.World(size, state.arenaId );
		s3d.renderer = renderer;

		var nbPlayers = 0;
		for(p in state.players)
			if(p.kind == Player) nbPlayers++;

		switch(nbPlayers) {
			case 1 : renderer.width = 0; renderer.height = 0;
			case 2 : renderer.width = 1; renderer.height = 0;
			case 3, 4 : renderer.width = 1; renderer.height = 1;
			default : renderer.width = 0; renderer.height = 0;
		}

		var allChars = Data.chars.all;
		function addPlayer(k : ent.Entity.EntityKind, dir : h3d.col.Point, ?props : ent.Fairy.Props) {
			if(props == null)
				props = {kind : k, modelId : allChars[Std.random(allChars.length)].id, color : 0 };
			var pl = k == Player ? new ent.Player(props, dir) : new ent.IA(props, dir);
			players.push(pl);
			var cam = initCamera(pl);

			if(players.length <= nbPlayers) {
				var tex = new h3d.mat.Texture(s2d.width >> renderer.width, s2d.height >> renderer.height, [Target]);
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
		ui = new ui.Scores(s2d, function() {
			gameOver = false;
			for(p in players)
				p.canMove = true;
		});
		onResize();
	}

	public function setAmbient(id) {
		if(ambientId == id) return;
		if(ambient.length <= id) return;
		ambientId = id;
		new hxd.inspect.SceneProps(s3d).applyProps(ambient[id].s3d, function(msg) trace(msg));
	}

	public function initCamera(pl : ent.Fairy) {
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

	function setCameraValues(pl : ent.Fairy) {
		var pn = pl.worldNormal;
		var dir = pl.dir;
		var decal = camZ * 0.75;

		camPosOffset = new h3d.col.Point( -camDist * dir.x + camZ * pn.x, -camDist * dir.y + camZ * pn.y, -camDist * dir.z + camZ * pn.z);
		camTargetOffset = new h3d.col.Point(decal * pn.x, decal * pn.y, decal * pn.z);
		camPos = new h3d.col.Point(pl.x + camPosOffset.x, pl.y + camPosOffset.y, pl.z  + camPosOffset.z);
		camTarget = new h3d.col.Point(pl.x + camTargetOffset.x, pl.y + camTargetOffset.y, pl.z  + camTargetOffset.z);
	}

	function updatePlayerCamera(pl : ent.Fairy, dt : Float) {
		setCameraValues(pl);

		var pn = pl.worldNormal;
		var dir = pl.dir;
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

		//ADMIN
		if( K.isDown(K.CTRL) && K.isPressed("I".code) ) {
			if( inspector != null ) {
				inspector.dispose();
				inspector = null;
			} else {
				inspector = new hxd.inspect.Inspector(s3d);
			}
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

		if(pause || gameOver) return;

		for( pl in players)
			updatePlayerCamera(pl, dt);

		for(e in entities)
			e.update(dt);

		if(!gameOver) {
			/*
			if(bonus.length < bonusMaxCount && Math.random() < 0.01) {
				var b = new ent.Bonus();
				if(world.collideBounds(b.getBounds()))
					b.remove();
			}*/
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

		if(ui != null) ui.onResize();

		//
		for(i in 0...customScene.views.length) {
			var v = customScene.views[i];
			v.target.dispose();
			v.target = new h3d.mat.Texture(s2d.width >> renderer.width, s2d.height >> renderer.height, [Target]);
			bmpViews[i].tile = h2d.Tile.fromTexture(v.target);
		}

		for(i in 0...bmpViews.length) {
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
		inst = new Game();
		hxd.res.Resource.LIVE_UPDATE = true;
		hxd.Res.initLocal();
		Data.load(hxd.Res.data.entry.getText());
		Texts.load(hxd.Res.texts.entry.getText());
	}
}