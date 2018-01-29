package map;

class View {
	public var id : Int;
	public var camera : h3d.Camera;
	public var target : h3d.mat.Texture;

	public function new(id : Int, camera : h3d.Camera, target : h3d.mat.Texture) {
		this.id = id;
		this.camera = camera;
		this.target = target;
	}
}

class CustomScene extends h3d.scene.Scene
{
	var game = Game.inst;
	public var views : Array<View>;

	public function new() {
		super();
		views = [];
	}

	public function getView(id : Int) {
		for(v in views)
			if(v.id == id)
				return v;
		return null;
	}

	public function addView(id : Int, camera : h3d.Camera, target : h3d.mat.Texture) {
		views.push(new View(id, camera, target));
	}

	public function removeView(view : View) {
		view.target.dispose();
		views.remove(view);
	}

	public function clearViews() {
		while(views.length > 0)
			views.pop().target.dispose();
	}

	override public function render(engine:h3d.Engine) {
		if(views.length == 0) {
			super.render(engine);
			return;
		}

		ctx.elapsedTime /= views.length;

		for(v in views) {
			if(v.id == -1) {
				//ui
				/*
				for(i in 0...game.s3d.numChildren) {
					var o = game.s3d.getChildAt(i);
					o.visible = o.name == "ui";
				}*/
				camera = v.camera;
			}
			else {
				/*
				for(i in 0...game.s3d.numChildren) {
					var o = game.s3d.getChildAt(i);
					o.visible = o.name != "ui";
				}*/
				//player view
				updatePlayers(v.id);
				camera = v.camera;
				updateWalls();
			}

			engine.pushTarget(v.target);
			super.render(engine);
			engine.popTarget();
		}
	}

	function updateWalls() {
		var dir = camera.target.sub(camera.pos);
		dir.normalize();
		var d = new h3d.col.Point(dir.x, dir.y, dir.z);
		for(w in game.world.walls) {
			var c = d.dot(w.n);
			var a = 1 - c;
			w.w.visible = a > 0.3;
			w.w.material.color.w = a > 0.7 ? 1 : a;
		}
	}

	function updatePlayers(id : Int) {
		var players = game.players;
		for(p in players) {
			if(p.dead) continue;
			@:privateAccess p.obj.visible = true;
			if(p.id == id) continue;
			if(p.isPowerActive(Ghost))
				@:privateAccess p.obj.visible = false;
		}
	}
}