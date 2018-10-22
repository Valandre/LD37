package ent.power;

class Tentacle extends h3d.scene.Mesh {	
	var game : Game;
	var owner : ent.Unit;
	var target : ent.Unit;	
	var dir : h3d.Vector;
	var removed = false;
	var time = 0.;
	var pt = new h3d.col.Point();
	
	public function new (owner, time : Float, value : Float, ?parent) {
		
		var size = value;
		var c = new h3d.prim.Cube(size, size, size);
		c.addUVs();
		c.addNormals();	
		c.translate(-size*0.5, -size*0.5, -size*0.5);

		super(c, null, parent);
		game = Game.inst;
		material.color.setColor(0xFFFF00FF);
		material.mainPass.enableLights = true;

		this.time = time * 60;
		this.owner = owner;
		this.dir = owner.worldNormal.toVector().clone();

		var dist = 16;
		x = owner.x + dist * owner.dir.x;
		y = owner.y + dist * owner.dir.y;
		z = owner.z + dist * owner.dir.z;
		setDirection(dir);

		game.world.collides.push(this);		
		game.event.waitUntil(function(dt) { 
			update(dt);
			return removed;
		});
	}

	override function onRemove() {
		super.onRemove();
		removed = true;
		onRemoved();
	}

	public dynamic function onRemoved() {}

	function update(dt : Float) {
		if(removed) return;		

		for(p in game.players) {
			if(p == owner || p.dead) continue;
			pt.x = p.x; pt.y = p.y; pt.z = p.z;
			if(getBounds().contains(pt)) 		
				p.destroy();
		}	

		time -= dt;
		if(time < 0) {			
			game.world.collides.remove(this);
			remove();	
		}
	}
}