package map;


class World {

	var game : Game;
	var room : h3d.scene.Object;
	var obj : h3d.scene.Object;
	var size : Int;
	public var bounds : h3d.col.Bounds;
	public var walls : Array<{w : h3d.scene.Mesh, n : h3d.col.Point}>;
	public var lights : Array<h3d.scene.PointLight>;
	public var collides : Array<h3d.col.Collider>;

	public function new(size : Int) {
		game = Game.inst;
		this.size = size;

		walls = [];
		collides = [];
		lights = [];

		init();
	}

	function init() {
		var res = hxd.Res.load("Room/Model.FBX").toModel();
		if( res == null ) return;
		room = game.modelCache.loadModel(res);
		room.inheritCulled = true;
		game.s3d.addChild(room);

		for(m in room.getMeshes()) {
			m.material.mainPass.enableLights = true;
			m.material.shadows = false;
			m.material.allocPass("depth");
			m.material.allocPass("normal");
		}

		var w = size - 1;
		bounds = new h3d.col.Bounds();
		bounds.addPoint(new h3d.col.Point( -w * 0.5, -w * 0.5, -w * 0.5));
		bounds.addPoint(new h3d.col.Point( w * 0.5, w * 0.5, w * 0.5));

		//
	return;
		var res = hxd.Res.load("Room/Window01.FBX").toModel();
		if( res == null ) return;
		obj = game.modelCache.loadModel(res);
		obj.inheritCulled = true;
		game.s3d.addChild(obj);

		for(m in obj.getMeshes()) {
			if(m.name.substr(0, 7) == "Collide") {
				collides.push(m.primitive.getCollider());
				m.remove();
				continue;
			}
			m.material.mainPass.enableLights = true;
			m.material.shadows = false;
			m.material.allocPass("depth");
			m.material.allocPass("normal");
		}

	}

	public function reset() {
		while(walls.length > 0)
			walls.pop().w.remove();
		while(lights.length > 0)
			lights.pop().remove();
	}

	var pt = new h3d.col.Point();
	public function isCollide(e : ent.Entity) {

		var r = h3d.col.Ray.fromValues(e.x, e.y, e.z, e.dir.x, e.dir.y, e.dir.z);
		r.transform(obj.getInvPos());
		r.normalize();

		var p = new h3d.col.Point(e.x, e.y, e.z);
		p.transform(obj.getInvPos());

		for(c in collides) {
			if(c.contains(p)) return true;
			if(c.rayIntersection(r, pt) != null) return true;
		}

		return false;
	}

	public function inBounds(x : Float, y : Float, z : Float) {
		return bounds.contains(new h3d.col.Point(x, y, z));
	}

	public function inBoundsBox(b : h3d.col.Bounds) {
		return bounds.collide(b);
	}
}