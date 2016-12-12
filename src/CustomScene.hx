package;

class View {
	public var camera : h3d.Camera;
	public var target : h3d.mat.Texture;

	public function new(camera : h3d.Camera, target : h3d.mat.Texture) {
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

	public function addView(camera : h3d.Camera, target : h3d.mat.Texture) {
		views.push(new View(camera, target));
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

		for(v in views) {
			camera = v.camera;
			//engine.pushTarget(v.target);
			//trace(engine.getCurrentTarget());
			super.render(engine);
		}
	}
}