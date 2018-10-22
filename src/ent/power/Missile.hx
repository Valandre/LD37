package ent.power;

class Missile {	
	var game : Game;
	var owner : ent.Unit;
	var target : ent.Unit;	
	var dir : h3d.Vector;
	var destroyed = false;
	var speed = 0.4;
	var speedMax = 1.7;
	var ray = 4.;
	var canCollide = false;
	var obj : h3d.scene.Object;

	public function new (owner, dir : h3d.Vector) {
		game = Game.inst;

		var res = hxd.Res.load("Fx/Missile01/Model.FBX").toModel();
		obj = game.modelCache.loadModel(res);			
		game.s3d.addChild(obj);

		this.owner = owner;
		obj.x = owner.x;
		obj.y = owner.y;
		obj.z = owner.z;
		this.dir = dir;
		obj.setDirection(dir);

		game.event.wait(0.3, function() {
			canCollide = true;
		});		
		game.event.waitUntil(function(dt) { 
			update(dt);
			return destroyed;
		});					
	}

	function worldCollide() {	
		var sensor = h3d.col.Ray.fromValues(obj.x, obj.y, obj.z, dir.x, dir.y, dir.z);
		for(w in game.world.walls) {
			var d = w.w.getBounds().rayIntersection(sensor, false);
			if(d > 0 && d < 1)
				return true;
		}

		return game.world.collide(new h3d.col.Point(obj.x, obj.y, obj.z), true);
	}

	function remove() {
		obj.remove();
		onRemoved();
	}

	public dynamic function onRemoved() {}

	function explode() {
		destroyed = true;
		remove();

		for(p in game.players) {
			if(p == owner || p.dead) continue;
			if(hxd.Math.distance(p.x-obj.x, p.y-obj.y, p.z-obj.z) < ray)
				p.destroy();
		}
	}

	function update(dt : Float) {
		if(destroyed) return;
		
		speed = Math.min(speedMax, speed+0.01*dt);
		obj.x += speed*dir.x*dt;
		obj.y += speed*dir.y*dt;
		obj.z += speed*dir.z*dt;

		if(canCollide && worldCollide()) 
			explode();
	}
}