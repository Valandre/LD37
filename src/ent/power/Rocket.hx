package ent.power;

class Rocket {	
	var game : Game;
	var owner : ent.Unit;
	var target : ent.Unit;	
	var dir : h3d.Vector;
	var targetDir : h3d.Vector;
	var destroyed = false;
	var speed = 0.1;
	var speedMax = 1.4;
	var ray = 4.;
	var canCollide = false;
	var obj : h3d.scene.Object;

	public function new (owner, ?prim) {
		game = Game.inst;

		var res = hxd.Res.load("Fx/Rocket01/Model.FBX").toModel();
		obj = game.modelCache.loadModel(res);			
		game.s3d.addChild(obj);

		this.owner = owner;
		obj.x = owner.x;
		obj.y = owner.y;
		obj.z = owner.z;

		dir = owner.worldNormal.toVector().clone();
		dir.x += owner.dir.x == 0 ? hxd.Math.srand(0.2) : owner.dir.x;
		dir.y += owner.dir.y == 0 ? hxd.Math.srand(0.2) : owner.dir.y;
		dir.z += owner.dir.z == 0 ? hxd.Math.srand(0.2) : owner.dir.z;
		targetDir = dir.clone();
		obj.setDirection(dir);

		game.event.wait(0.3, function() {
			searchTarget();
			canCollide = true;
		});		
		game.event.waitUntil(function(dt) { 
			update(dt);
			return destroyed;
		});					
	}

	function searchTarget() {
		var targets = [for(p in game.players) if(p != owner) p];
		target = targets[Std.random(targets.length)];
		/*
		var d = 1e9;
		for(p in game.players) {
			if(p == owner) continue;
			var dist = hxd.Math.distance(p.x-x, p.y-y, p.z-z);
			if(dist < d) {
				target = p;
				d = dist;
			}
		}*/
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

		for(p in game.players) {
			if(hxd.Math.distance(p.x-obj.x, p.y-obj.y, p.z-obj.z) < ray)
				p.destroy();
		}
		remove();
	}

	function update(dt : Float) {
		if(destroyed) return;
		if(target != null) {
			targetDir.x = target.x-obj.x;
			targetDir.y = target.y-obj.y;
			targetDir.z = target.z-obj.z;		
			targetDir.normalize();

			dir.x += (targetDir.x-dir.x)*0.1*dt;	
			dir.y += (targetDir.y-dir.y)*0.1*dt;	
			dir.z += (targetDir.z-dir.z)*0.1*dt;	
			dir.normalize();
			obj.setDirection(dir);
		}

		speed = Math.min(speedMax, speed+0.01*dt);
		obj.x += speed*dir.x*dt;
		obj.y += speed*dir.y*dt;
		obj.z += speed*dir.z*dt;

		if(canCollide && worldCollide()) 
			explode();
	}
}
