import hxd.Key in K;
import hxd.Res;
import map.World;
class Game extends hxd.App {

	public var COLORS = [0xFFFFFF, 0xFF511C, 0x02DAD8, 0xA1F522, 0xF5227A];

	public var modelCache : h3d.prim.ModelCache;
	public var event : hxd.WaitEvent;
	public var entities : Array<ent.Entity>;
	public var world : map.World;
	public var players : Array<ent.Entity>;
	public var renderer : Composite;
	public var customScene : CustomScene;
	public var inspector : hxd.inspect.Inspector;

	public var size = 60;
	var camPos : h3d.col.Point;
	var camTarget : h3d.col.Point;
	var camPosOffset : h3d.col.Point;
	var camTargetOffset : h3d.col.Point;

	var bmpViews : Array<h2d.Bitmap>;

	var pause = false;
	var gameOver = true;
	var IAOnly = false;

	var menu : Menu;
	var win : Win;
	var ui : UI;
	var blackScreen : h2d.Bitmap;

	public var mute = false;

	public var nbPlayers = 1;
	public var stars : Array<Int>;

	public var controllers : Array<Controller> = [];
	public var keys : Controller;

	var ambient = [];
	var ambientId = 0;

	override function init() {

		customScene = new CustomScene();
		setScene3D(customScene);
		renderer = new Composite();
		s3d.renderer = renderer;

		try {
			ambient.push(haxe.Json.parse(hxd.Res.load("title.js").entry.getText()));
			ambient.push(haxe.Json.parse(hxd.Res.load("ambient.js").entry.getText()));
			ambientId = 0;
			new hxd.inspect.SceneProps(s3d).applyProps(ambient[0].s3d, function(msg) trace(msg));
		}
		catch(e : hxd.res.NotFound) {};

		modelCache = new h3d.prim.ModelCache();
		event = new hxd.WaitEvent();

		world = new map.World(size);
		entities = [];
		players = [];
		bmpViews = [];
		stars = [0, 0, 0, 0];

		menu = new Menu(s2d);
		//restart();

		hxd.Pad.wait(function(p) {
			controllers.push(new Controller(controllers.length, p));
			if(controllers.length == 1)
				keys = controllers[0];
		});
		Sounds.play("Loop");
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
			win = new Win(s2d);
			for( c in controllers)
				c.active = false;
			stars = [0, 0, 0, 0];
			gameOver = true;
		}, true);
	}

	public function choose() {
		reset();
		menu = new Menu(s2d);
		menu.openChoose();
		win = null;
	}

	public function restart() {
		transition(function() {
			reset();
			start();
		}, false);
	}

	function reset() {
		while(entities.length > 0)
			entities[0].remove();
		world.reset();
		while(players.length > 0)
			players.pop().remove();
		while(bmpViews.length > 0)
			bmpViews.pop().remove();
		if(menu != null) menu.remove();
		if(ui != null) ui.remove();
		menu = null;
		ui = null;
		customScene.clearViews();

		if(controllers.length > 0)
			controllers[0].active = true;
	}

	function start(){
		entities = [];

		switch(nbPlayers) {
			case 1 : renderer.width = 0; renderer.height = 0;
			case 2 : renderer.width = 1; renderer.height = 0;
			case 3, 4 : renderer.width = 1; renderer.height = 1;
			default : renderer.width = 0; renderer.height = 0;
		}

		function addPlayer(k : ent.Entity.EntityKind, dir : h3d.col.Point) {
			var pl = k == Player ? new ent.Player(dir) : new ent.IA(dir);
			players.push(pl);
			var cam = initCamera(pl);

			if(k == Player) {
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


		if(controllers.length == 0)
			addPlayer(Player, dirs.shift());
		for(c in controllers) {
			if(c.active) {
				var pl = addPlayer(Player, dirs.shift());
				pl.controller = c;
			}
			else addPlayer(IA, dirs.shift());
		}

		for(i in 0...4 - players.length)
			addPlayer(IA, dirs.shift());

		if(ui != null) ui.remove();
		ui = new UI(s2d, function() {
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

	public function initCamera(pl : ent.Entity) {
		setCameraValues(pl);
		var cam = new h3d.Camera();
		cam.pos.x = camPos.x;
		cam.pos.y = camPos.y;
		cam.pos.z = camPos.z;
		cam.target.x = camTarget.x;
		cam.target.y = camTarget.y;
		cam.target.z = camTarget.z;
		cam.fovY = 90;
		var pn = pl.worldNormal;
		cam.up.x = pn.x;
		cam.up.y = pn.y;
		cam.up.z = pn.z;

		var dz = 4;
		var dist = 2;
		var decal = dz * 0.75;
		var n = new h3d.Vector(cam.pos.x - cam.target.x, cam.pos.y - cam.target.y, cam.pos.z - cam.target.z);
		var d = dist + decal;
		if(n.x * n.x + n.y * n.y + n.z * n.z < d * d) {
			n.normalize();
			cam.pos.x = cam.target.x + n.x * d;
			cam.pos.y = cam.target.y + n.y * d;
			cam.pos.z = cam.target.z + n.z * d;
		}
		return cam;
	}

	function setCameraValues(pl : ent.Entity) {
		var pn = pl.worldNormal;
		var dist = 2;
		var dz = 4;
		var dir = pl.dir;
		var decal = dz * 0.75;

		camPosOffset = new h3d.col.Point( -dist * dir.x + dz * pn.x, -dist * dir.y + dz * pn.y, -dist * dir.z + dz * pn.z);
		camTargetOffset = new h3d.col.Point(decal * pn.x, decal * pn.y, decal * pn.z);
		camPos = new h3d.col.Point(pl.x + camPosOffset.x, pl.y + camPosOffset.y, pl.z  + camPosOffset.z);
		camTarget = new h3d.col.Point(pl.x + camTargetOffset.x, pl.y + camTargetOffset.y, pl.z  + camTargetOffset.z);
	}

	function updatePlayerCamera(pl : ent.Entity, dt : Float) {
		setCameraValues(pl);

		var pn = pl.worldNormal;
		var dist = 2;
		var dz = 4;
		var dir = pl.dir;
		var decal = dz * 0.75;

		var sp = 0.1 * dt;
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
		var d = dist + decal;
		if(n.x * n.x + n.y * n.y + n.z * n.z < d * d) {
			n.normalize();
			cam.pos.x = cam.target.x + n.x * d;
			cam.pos.y = cam.target.y + n.y * d;
			cam.pos.z = cam.target.z + n.z * d;
		}

		cam.up.x += (pn.x - cam.up.x) * sp;
		cam.up.y += (pn.y - cam.up.y) * sp;
		cam.up.z += (pn.z - cam.up.z) * sp;


		cam.target.x += pshake.x;
		cam.pos.x += pshake.y;
		cam.target.y += pshake.y;
		cam.pos.y += pshake.x;
		cam.target.z += pshake.y;
		cam.pos.z += pshake.y;

		return cam;
	}

	var camRot = -1.;
	function updateDefaultCamera(dt : Float) {
		var cam = s3d.camera;
		cam.pos.x = 12 * Math.cos(camRot);
		cam.pos.y = 12 * Math.sin(camRot);
		cam.pos.z = 12 - (size >> 1);
		cam.target.x = 0;
		cam.target.y = 0;
		cam.target.z = 10 - size >> 1;
		cam.up.x = 0;
		cam.up.y = 0;
		cam.up.z = 1;
		cam.fovY = 90;
		camRot += 0.0025 * dt;
	}

	function updateChooseCamera(dt : Float) {
		var cam = s3d.camera;
		cam.pos.x = 8;
		cam.pos.y = -1.5;
		cam.pos.z = 2.75 - (size >> 1);
		cam.target.x = 0;
		cam.target.y = 0;
		cam.target.z = 1.75 - (size >> 1);
		cam.up.x = 0;
		cam.up.y = 0;
		cam.up.z = 1;
		cam.fovY = 60;
	}

	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code)) {
			engine.fullScreen = !engine.fullScreen;
		}

		if( K.isDown(K.CTRL) && K.isPressed("I".code) ) {
			if( inspector != null ) {
				inspector.dispose();
				inspector = null;
			} else {
				inspector = new hxd.inspect.Inspector(s3d);
			}
		}
/*
		if(K.isPressed("P".code))
			pause = !pause;*/
	}

	override function update(dt:Float) {
		for(c in controllers)
			c.update(dt);

		if(menu != null) menu.update(dt);
		if(ui != null) ui.update(dt);

		if( K.isDown(K.SHIFT)) {
			var speed = K.isDown(K.CTRL) ? 0.1 : 5;
			hxd.Timer.deltaT *= speed;
			hxd.Timer.tmod *= speed;
			dt *= speed;
		}

		super.update(dt);
		event.update(dt);

		if(menu != null) {
			if(menu.choose == null)
				updateDefaultCamera(dt);
			else updateChooseCamera(dt);
		}
		if(win != null)
			updateChooseCamera(dt);

		if(blackScreen != null)
			return;

		updateKeys(dt);

		if(pause) return;

		for( pl in players)
			updatePlayerCamera(pl, dt);

		for(e in entities)
			e.update(dt);

		if(!gameOver) {
			if(players.length == 1) {
				gameOver = true;
				ui.nextRound(players[0]);
			}
		}
	}

	var pshake = new h2d.col.Point();
	public function shake(pow : Float = 0.1) {
		pshake.x = 0;
		pshake.y = 0;

		event.waitUntil(function(dt) {
			pshake.x = hxd.Math.srand(pow);
			pshake.y = hxd.Math.srand(pow);
			pow *= Math.pow(0.8, dt);
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
		if(menu != null)
			menu.onResize();
		if(ui != null)
			ui.onResize();
		if(win != null)
			win.onResize();

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
		hxd.Res.initLocal();
	}
}