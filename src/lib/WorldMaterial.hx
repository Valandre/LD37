class MyMaterial extends h3d.mat.Material {
	override function getDefaultProps(?type:String):Any {
		return super.getDefaultProps("ui");
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
