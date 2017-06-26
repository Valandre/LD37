package map;


class World {

	var game : Game;
	var room : h3d.scene.Object;
	var col : h3d.scene.Object;
	var size : Int;
	var arenaId : Int;


	public var bounds : h3d.col.Bounds;
	public var walls : Array<{w : h3d.scene.Mesh, n : h3d.col.Point}>;
	public var lights : Array<h3d.scene.PointLight>;
	public var collides : Array<{m : h3d.Matrix, c : h3d.col.Collider}>;

	public function new(size : Int, arenaId : Int) {
		game = Game.inst;
		this.size = size;
		this.arenaId = arenaId;

		walls = [];
		collides = [];
		lights = [];

		init();
	}

	function init() {
		var res = hxd.Res.load("World/World0" + (arenaId + 1) + "/Model.FBX").toModel();
		if( res == null ) return;
		room = game.modelCache.loadModel(res);
		room.inheritCulled = true;
		room.setScale(size / 100);
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
		switch(arenaId) {
			case 1:
				var res = hxd.Res.load("World/World0" + (arenaId + 1) + "/Window01.FBX").toModel();
				if( res == null ) return;
				col = game.modelCache.loadModel(res);
				col.inheritCulled = true;
				col.setScale(size / 100);
				game.s3d.addChild(col);

				for(m in col.getMeshes()) {
					if(m.name.substr(0, 7) == "Collide") {
						collides.push({m : m.getInvPos(), c : m.primitive.getCollider()});
						m.remove();
						continue;
					}
					m.material.mainPass.enableLights = true;
					m.material.shadows = false;
					m.material.allocPass("depth");
					m.material.allocPass("normal");
				}
			default:
		}
	}

	public function remove() {
		reset();
		if(room != null) room.remove();
		if(col != null) col.remove();
		bounds = null;
	}

	public function reset() {
		while(walls.length > 0)
			walls.pop().w.remove();
		while(lights.length > 0)
			lights.pop().remove();
	}

	public function removeWall(wall : h3d.scene.Mesh) {
		for(w in walls)
			if(w.w == wall) {
				walls.remove(w);
				break;
			}
	}

	var pt = new h3d.col.Point();
	public function collide(e : ent.Fairy) {
		for(c in collides) {
			var r = h3d.col.Ray.fromValues(e.x, e.y, e.z, e.dir.x, e.dir.y, e.dir.z);
			r.transform(c.m);
			var d = c.c.rayIntersection(r, true);
			//if(e.kind == Player) trace(d, r); //incomprehensible -> renvoi brutalement -1 alors que 'd' diminue correctement préalablement (cf Nico)
			if(d != -1){
				if(d > 1) continue;
				return true;
			}
		}

		return false;
	}

	public function collideBounds(b : h3d.col.Bounds) {
		if(!inBoundsBox(b)) return false;

		for(c in collides) {
			if(c.c.contains(new h3d.col.Point(b.xMin, b.yMin, b.zMin))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMin, b.yMin, b.zMax))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMin, b.yMax, b.zMin))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMin, b.yMax, b.zMax))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMax, b.yMin, b.zMin))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMax, b.yMin, b.zMax))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMax, b.yMax, b.zMin))) return true;
			if(c.c.contains(new h3d.col.Point(b.xMax, b.yMax, b.zMax))) return true;
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