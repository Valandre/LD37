package ent.power;

class Duplicate {	
	var game : Game;
	var p : ent.Unit;
	var obj : h3d.scene.Object;
	var dir : h3d.col.Point;
	var worldNormal : h3d.col.Point;
	var speed : Float;
	var wsize : Float;		
	var wall : ent.Unit.Wall;
	var lastWall : ent.Unit.Wall;
			
	public function new (orient : Int, distMax : Float, owner : ent.Unit) {
		game = Game.inst;
		p = owner;
		@:privateAccess {
			wsize = p.wallSize;		
			dir = p.setDir(p.dir, orient);
			speed = p.speed;
			worldNormal = p.worldNormal.clone();
			lastWall = p.lastWall;						
			
			var res = hxd.Res.load("Fx/Copycat01/Model.FBX").toModel();
			obj = game.modelCache.loadModel(res);
			obj.x = p.x;
			obj.y = p.y;
			obj.z = p.z;	
			obj.playAnimation(game.modelCache.loadAnimation(res));
			game.s3d.addChild(obj);	
			p.meshRotate(obj);

			wall = createWall();				

			game.event.waitUntil(function(dt) {
				var sc = wall.scaleX + speed * 1.5 * dt;
				wall.scaleX = sc;
				
				var pt = new h3d.col.Point(wall.x+dir.x*wall.scaleX, wall.y+dir.y*wall.scaleX, wall.z+dir.z*wall.scaleX);
				obj.x = pt.x;
				obj.y = pt.y;
				obj.z = pt.z;	


				if(checkFaceHit()) 
					faceRotate();
				else {
					var col = false;
					if(game.world.collide(pt, true))
						col = true;
					if(sc >= distMax || col) {
						wall.scaleX = Std.int(sc) + Std.int((sc % 1) / wsize) * wsize;
						obj.remove();
						return true;
					}	
				}				
	
				return false;
			});
		}
	}
	

	function createWall() {
		var c = new h3d.prim.Cube(1, wsize, 1);
		c.addNormals();
		c.addUVs();
		c.translate(0, -wsize * 0.5, -0.5);

		@:privateAccess {
			var pos = getSizedPos();
			var wall = new ent.Unit.Wall(p.wallTex, c, game.s3d);
			wall.prev = lastWall;
			wall.worldNormal = worldNormal;
			wall.dir = dir;
			wall.scaleX = 0;
			wall.x = pos.x - p.dir.x * wsize;
			wall.y = pos.y - p.dir.y * wsize;
			wall.z = pos.z - p.dir.z * wsize;		
			lastWall = wall;						
			p.walls.unshift(wall);
			game.world.walls.unshift({w : wall, n : worldNormal.clone()});
			p.meshRotate(wall, dir);

			return wall;
		}
	}

	function getSizedPos() {
		//replace la position arrondie au multiple de l'epaisseur d'un mur
		var p = new h3d.col.Point();
		p.x = Std.int(obj.x) + Std.int((obj.x % 1) / wsize) * wsize;
		p.y = Std.int(obj.y) + Std.int((obj.y % 1) / wsize) * wsize;
		p.z = Std.int(obj.z) + Std.int((obj.z % 1) / wsize) * wsize;
		return p;
	}

	function checkFaceHit() {
		if(game.world.inBounds(obj.x, obj.y, obj.z)) return false;
		do {
			obj.x -= dir.x * speed * 0.05;
			obj.y -= dir.y * speed * 0.05;
			obj.z -= dir.z * speed * 0.05;
		}
		while(!game.world.inBounds(obj.x, obj.y, obj.z));
		return true;
	}

	function faceRotate() {
		var pos = getSizedPos();
		obj.x = pos.x; obj.y = pos.y; obj.z = pos.z;

		if(lastWall != null)
			lastWall.scaleX = hxd.Math.distance(obj.x - lastWall.x + dir.x * wsize * 2, obj.y - lastWall.y + dir.y * wsize * 2, obj.z - lastWall.z + dir.z * wsize * 2);

		var tmp = dir.clone();
		dir = worldNormal.clone();
		tmp.scale(-1);
		worldNormal = tmp;
		speed = @:privateAccess p.speedRef * 0.5;
		wall = createWall();

		@:privateAccess p.meshRotate(obj);
	}
}