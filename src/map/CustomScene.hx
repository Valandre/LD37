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
			camera = v.camera;
			engine.pushTarget(v.target);
			super.render(engine);
			engine.popTarget();
		}

	}
}