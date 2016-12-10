import hxd.Key in K;
import hxd.Res;
import map.World;
class Game extends hxd.App {

	public var modelCache : h3d.prim.ModelCache;
	public var event : hxd.WaitEvent;
	public var sfx : Sfx;
	public var keys : Keys;
	public var entities : Array<ent.Entity>;
	public var world : map.World;
	public var players : Array<ent.Player>;
	public var renderer : Composite;
	public var inspector : hxd.inspect.Inspector;

	public var size = 100;
	var camPos : h3d.col.Point;
	var camTarget : h3d.col.Point;
	var camPosOffset : h3d.col.Point;
	var camTargetOffset : h3d.col.Point;

	var pause = false;

	var blackScreen : h2d.Bitmap;

	override function init() {
		renderer = new Composite();
		s3d.renderer = renderer;

		try {
			var t = haxe.Json.parse(hxd.Res.load("ambient.js").entry.getText());
			new hxd.inspect.SceneProps(s3d).applyProps(t.s3d, function(msg) trace(msg));
		}
		catch(e : hxd.res.NotFound) {};


		modelCache = new h3d.prim.ModelCache();
		sfx = new Sfx();
		keys = new Keys();
		event = new hxd.WaitEvent();

		world = new map.World(size);
		entities = [];
		players = [];
		restart();
	}

	public function restart() {
		blackScreen = new h2d.Bitmap(h2d.Tile.fromColor(0), s2d);
		blackScreen.scaleX = s2d.width;
		blackScreen.scaleY = s2d.height;
		blackScreen.alpha = 0;
		event.waitUntil(function(dt) {
			blackScreen.alpha = Math.min(1, blackScreen.alpha + 0.1 * dt);
			if(blackScreen.alpha == 1) {
				reset();
				start();
				event.wait(0.2, function() {
					event.waitUntil(function(dt) {
						if(blackScreen == null) return true;
						blackScreen.alpha = Math.max(0, blackScreen.alpha - 0.1 * dt);
						if(blackScreen.alpha == 0) {
							blackScreen.remove();
							blackScreen = null;
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

	function reset() {
		while(entities.length > 0)
			entities[0].remove();
		world.reset();
		while(players.length > 0)
			players.pop().remove();
	}

	function start(){
		entities = [];

		//players.push(new ent.Player( -35, 0, -(size >> 1), 1));
		players.push(new ent.Player(new h3d.col.Point(1, 0, 0), 1));

		updateCamera(1);

		var cam = s3d.camera;
		cam.pos.x = camPos.x;
		cam.pos.y = camPos.y;
		cam.pos.z = camPos.z;
		cam.target.x = camTarget.x;
		cam.target.y = camTarget.y;
		cam.target.z = camTarget.z;
		cam.fovY = 90;
		cam.up.x = 0;
		cam.up.y = 0;
		cam.up.z = 1;
	}

	public static function getSfxLevel() {
		return 1;
	}

	function updateCamera(dt : Float) {
		if(players.length == 0) return;

		var pl = players[0];
		var pn = pl.worldNormal;

		var dist = 2;
		var dz = 4;
		var dir = pl.dir;
		camPosOffset = new h3d.col.Point( -dist * dir.x + dz * pn.x, -dist * dir.y + dz * pn.y, -dist * dir.z + dz * pn.z);

		var decal = dz * 0.75;
		camTargetOffset = new h3d.col.Point(decal * pn.x, decal * pn.y, decal * pn.z);

		camPos = new h3d.col.Point(pl.x + camPosOffset.x, pl.y + camPosOffset.y, pl.z  + camPosOffset.z);
		camTarget = new h3d.col.Point(pl.x + camTargetOffset.x, pl.y + camTargetOffset.y, pl.z  + camTargetOffset.z);

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
	}

	function updateKeys(dt : Float) {
		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;

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
	}

	override function update(dt:Float) {

		if( K.isDown(K.SHIFT)) {
			var speed = K.isDown(K.CTRL) ? 0.1 : 5;
			hxd.Timer.deltaT *= speed;
			hxd.Timer.tmod *= speed;
			dt *= speed;
		}

		super.update(dt);
		event.update(dt);

		if(blackScreen != null) {
			updateCamera(dt);
			return;
		}

		updateKeys(dt);
		keys.update(dt);

		if(pause) return;

		updateCamera(dt);
		for(e in entities)
			e.update(dt);
	}

	override function onResize() {
		super.onResize();
		if(blackScreen != null) {
			blackScreen.scaleX = s2d.width;
			blackScreen.scaleY = s2d.height;
		}
	}

	public static var inst : Game;
	static function main() {
		inst = new Game();
		hxd.Res.initLocal();
	}
}