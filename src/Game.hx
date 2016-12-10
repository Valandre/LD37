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
	public var player : ent.Player;
	public var renderer : Composite;
	public var inspector : hxd.inspect.Inspector;

	var size = 100;
	var camPos : h3d.col.Point;
	var camTarget : h3d.col.Point;
	var camPosOffset : h3d.col.Point;
	var camTargetOffset : h3d.col.Point;

	public var worldNormal : h3d.col.Point;

	var pause = false;

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
		entities = [];

		world = new map.World(size);

		worldNormal = new h3d.col.Point(0, 0, 1);

		player = new ent.Player( -10, 0, -(size >> 1), 1);
		updateCamera(1);

		var cam = s3d.camera;
		cam.pos.x = camPos.x;
		cam.pos.y = camPos.y;
		cam.pos.z = camPos.z;
		cam.target.x = camTarget.x;
		cam.target.y = camTarget.y;
		cam.target.z = camTarget.z;
		cam.fovY = 90;
	}

	public static function getSfxLevel() {
		return 1;
	}

	function updateCamera(dt : Float) {
		var dist = 2;
		var dz = 4;
		var dir = player.dir;
		camPosOffset = new h3d.col.Point( -dist * dir.x + dz * worldNormal.x, -dist * dir.y + dz * worldNormal.y, -dist * dir.z + dz * worldNormal.z);

		var decal = dz * 0.75;
		camTargetOffset = new h3d.col.Point(decal * worldNormal.x, decal * worldNormal.y, decal * worldNormal.z);

		camPos = new h3d.col.Point(player.x + camPosOffset.x, player.y + camPosOffset.y, player.z  + camPosOffset.z);
		camTarget = new h3d.col.Point(player.x + camTargetOffset.x, player.y + camTargetOffset.y, player.z  + camTargetOffset.z);

		var sp = 0.1 * dt;
		var cam = s3d.camera;

		//var oldx = cam.pos.x, oldy = cam.pos.y, oldz = cam.pos.z;
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

		/*
		while(!world.inBounds(cam.pos.x, cam.pos.y, cam.pos.z)){
			cam.pos.x -= n.x * 0.01;
			cam.pos.y -= n.y * 0.01;
			cam.pos.z -= n.z * 0.01;
		}*/

		s3d.camera.up.x += (worldNormal.x - s3d.camera.up.x) * sp;
		s3d.camera.up.y += (worldNormal.y - s3d.camera.up.y) * sp;
		s3d.camera.up.z += (worldNormal.z - s3d.camera.up.z) * sp;
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
		updateKeys(dt);

		if(pause) return;

		updateCamera(dt);
		event.update(dt);

		for(e in entities)
			e.update(dt);
	}

	public static var inst : Game;
	static function main() {
		inst = new Game();
		hxd.Res.initLocal();
	}
}