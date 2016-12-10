package map;


class World {

	var game : Game;
	var obj : h3d.scene.Object;
	var size : Int;
	public var bounds : h3d.col.Bounds;
	public var walls : Array<h3d.scene.Mesh>;
	public var lights : Array<h3d.scene.PointLight>;

	public function new(size : Int) {
		game = Game.inst;
		this.size = size;
		init();

		walls = [];
		lights = [];
	}

	function init() {
		var res = hxd.Res.load("Room/Model.FBX").toModel();
		if( res == null ) return;
		obj = game.modelCache.loadModel(res);
		obj.inheritCulled = true;
		game.s3d.addChild(obj);

		for(m in obj.getMeshes()) {
			m.material.mainPass.enableLights = true;
			m.material.receiveShadows = false;
			m.material.castShadows = true;
			m.material.allocPass("depth");
			m.material.allocPass("normal");
		}

		var w = size - 1;
		bounds = new h3d.col.Bounds();
		bounds.addPoint(new h3d.col.Point( -w * 0.5, -w * 0.5, -w * 0.5));
		bounds.addPoint(new h3d.col.Point( w * 0.5, w * 0.5, w * 0.5));
	}

	public function reset() {
		while(walls.length > 0)
			walls.pop().remove();
		while(lights.length > 0)
			lights.pop().remove();
	}

	public function inBounds(x : Float, y : Float, z : Float) {
		return bounds.contains(new h3d.col.Point(x, y, z));
	}

	public function inBoundsBox(b : h3d.col.Bounds) {
		return bounds.collide(b);
	}
}