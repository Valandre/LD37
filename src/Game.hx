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

	override function init() {
		modelCache = new h3d.prim.ModelCache();
		sfx = new Sfx();
		keys = new Keys();
		event = new hxd.WaitEvent();

		world = new map.World();
	}

	public static function getSfxLevel() {
		return 1;
	}

	function updateCamera(dt : Float) {

	}

	function updateKeys(dt : Float) {

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