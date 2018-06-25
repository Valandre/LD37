class MyMaterial extends h3d.mat.Material {
	override function getDefaultProps(?type:String):Any {
		return super.getDefaultProps("ui");
	}
}

class MyMaterialSetup extends h3d.mat.MaterialSetup {
	public function new() {
		super("MyMaterial");
	}
	override function createMaterial() {
		return @:privateAccess new MyMaterial();
	}
}
