class MyMaterial extends h3d.mat.Material {
	override function getDefaultProps(?type:String):Any {
		var props = {
			kind : "Alpha",
			shadows : false,
			culling : true,
			light : false,
		};
		return props;
	}
}

class MyMaterialSetup extends h3d.mat.MaterialSetup {

	public function new() {
		super("Default");
	}

	override function loadMaterialProps( mat : h3d.mat.Material ) {
		var props = super.loadMaterialProps(mat);
		//trace(mat.name, props);
		return props;
	}

	override function createMaterial() {
		return @:privateAccess new MyMaterial();
	}
}
