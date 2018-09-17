class MyMaterial extends h3d.mat.Material {
	override function getDefaultProps(?type:String):Any {
		return super.getDefaultProps("ui");
	}
}

class MyMaterialSetup extends h3d.mat.MaterialSetup {
	var oldDB : MaterialDatabase;

	public function new() {
		super("Default");
		oldDB = new MaterialDatabase("materials.props");
	}

	override function loadMaterialProps( mat : h3d.mat.Material ) {
		var props = super.loadMaterialProps(mat);
		if( props == null ) props = oldDB.loadProps(mat, this);
		return props;
	}

	override function createMaterial() {
		return @:privateAccess new MyMaterial();
	}
}
