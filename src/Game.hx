import hxd.Key in K;
import hxd.Res;
import map.World;
class Game extends hxd.App {

	public var COLORS = [0xFFFFFF, 0xFF511C, 0x02DAD8, 0xA1F522, 0xF5227A];

	public var modelCache : h3d.prim.ModelCache;
	public var event : hxd.WaitEvent;
	public var sfx : Sfx;
	public var keys : Keys;
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
	var ui : UI;
	var blackScreen : h2d.Bitmap;

	public var stars : Array<Int>;

	override function init() {

		customScene = new CustomScene();
		setScene3D(customScene);
		renderer = new Composite();
		s3d.renderer = renderer;

		try {
			var t = haxe.Json.parse(hxd.Res.load("ambient.js").entry.getText());
			new hxd.inspect.SceneProps(customScene).applyProps(t.s3d, function(msg) trace(msg));
		}
		catch(e : hxd.res.NotFound) {};


		modelCache = new h3d.prim.ModelCache();
		sfx = new Sfx();
		keys = new Keys();
		event = new hxd.WaitEvent();

		world = new map.World(size);
		entities = [];
		players = [];
		bmpViews = [];
		stars = [0, 0, 0, 0];

		menu = new Menu(s2d);
		//restart();
	}

	public static function getSfxLevel() {
		return 1;
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
			stars = [0, 0, 0, 0];
			gameOver = true;
			menu = new Menu(s2d);
		}, false);
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
		customScene.clearViews();
	}

	function start(){
		entities = [];

		function addPlayer(k : ent.Entity.EntityKind, dir : h3d.col.Point) {
			var pl = k == Player ? new ent.Player(dir) : new ent.IA(dir);
			players.push(pl);
			var cam = initCamera(pl);
			if(k == Player) {
				var tex = new h3d.mat.Texture(s2d.width >> renderer.width, s2d.height >> renderer.height);
				tex.clear(0xFF0000, 1);
				customScene.addView(cam, tex);
				//bmpViews.push(new h2d.Bitmap(h2d.Tile.fromTexture(tex), s2d));
			}
		}

		addPlayer(Player, new h3d.col.Point(1, 0, 0)); IAOnly = false;
		//addPlayer(IA, new h3d.col.Point(1, 0, 0)); IAOnly = true;
		addPlayer(IA, new h3d.col.Point(-1, 0, 0));
		addPlayer(IA, new h3d.col.Point(0, 1, 0));
		addPlayer(IA, new h3d.col.Point(0, -1, 0));

		if(ui != null) ui.remove();
		ui = new UI(s2d, function() {
			gameOver = false;
			for(p in players)
				p.canMove = true;
		});
	}

	function initCamera(pl : ent.Entity) {
		setCameraValues(pl);
		var cam = s3d.camera;
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
		return cam;
	}

	function setCamera(pl : ent.Entity) {
		if(pl == null) return;
		setCameraValues(pl);
		var cam = s3d.camera;
		cam.pos.x = camPos.x;
		cam.pos.y = camPos.y;
		cam.pos.z = camPos.z;
		cam.target.x = camTarget.x;
		cam.target.y = camTarget.y;
		cam.target.z = camTarget.z;

		var pn = pl.worldNormal;
		cam.up.x = pn.x;
		cam.up.y = pn.y;
		cam.up.z = pn.z;
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
		var cam = customScene.views[pl.id - 1].camera;

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

		s3d.camera.up.x += (pn.x - s3d.camera.up.x) * sp;
		s3d.camera.up.y += (pn.y - s3d.camera.up.y) * sp;
		s3d.camera.up.z += (pn.z - s3d.camera.up.z) * sp;


		cam.target.x += pshake.x;
		cam.pos.x += pshake.y;
		cam.target.y += pshake.y;
		cam.pos.y += pshake.x;
		cam.target.z += pshake.y;
		cam.pos.z += pshake.y;

		return cam;
	}

	function updateDefaultCamera(dt : Float) {
		if( players.length == 0) return;

		var pl = players[0];
		setCameraValues(pl);

		var pn = pl.worldNormal;
		var dist = 2;
		var dz = 4;
		var dir = pl.dir;
		var decal = dz * 0.75;

		var sp = 0.1 * dt;
		var cam = s3d.camera;

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

		s3d.camera.up.x += (pn.x - s3d.camera.up.x) * sp;
		s3d.camera.up.y += (pn.y - s3d.camera.up.y) * sp;
		s3d.camera.up.z += (pn.z - s3d.camera.up.z) * sp;


		cam.target.x += pshake.x;
		cam.pos.x += pshake.y;
		cam.target.y += pshake.y;
		cam.pos.y += pshake.x;
		cam.target.z += pshake.y;
		cam.pos.z += pshake.y;
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

		if(K.isPressed(K.BACKSPACE))
			restart();

		if(IAOnly && K.isPressed(K.TAB))
			players.push(players.shift());

		if(K.isPressed("P".code))
			pause = !pause;
	}

	override function update(dt:Float) {
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

		if(blackScreen != null) {
			updateDefaultCamera(dt);
			return;
		}

		updateKeys(dt);
		keys.update(dt);

		if(pause) return;

		for( pl in players)
			if(pl.kind == Player)
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
	}

	public static var inst : Game;
	static function main() {
		inst = new Game();
		hxd.Res.initLocal();
	}
}