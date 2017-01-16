package ent;
import lib.Controller;
import Sounds;

class Fairy extends Entity
{
	public var dir : h3d.col.Point;
	public var dead = false;
	public var id = 0;
	public var controller : lib.Controller;
	public var enableWalls = true;
	public var enableCollides = true;
	public var canMove = false;

	var color : Int = 0xFFFFFF;
	var speedRef = 0.35;
	var speed = 0.;
	var speedAspi = 0.;

	var wall : h3d.scene.Mesh;
	var lastwall : h3d.scene.Mesh;
	var light : h3d.scene.PointLight;
	var w = 1;
	var wallSize = 0.3;
	var wallTex : h3d.mat.Texture;

	var sensor : h3d.col.Ray;
	var dray = 5;

	public function new(kind, x = 0., y = 0., z = 0., scale = 1., ?id) {
		if(id == null) this.id = game.players.length + 1;
		else this.id = id;
		color = game.COLORS[this.id];

		super(kind, x, y, z, scale);

		wallTex = hxd.Res.load("wall0" + this.id + ".png").toTexture();
		speed = speedRef;
		sensor = h3d.col.Ray.fromValues(x, y, z, 0, 0, 0);
	}

	override public function remove() {
		super.remove();
		game.players.remove(this);
	}

	override function getModel() : hxd.res.Model {
		return hxd.Res.load("Elf/Model.FBX").toModel();
	}

	override function init() {
		super.init();

		for(m in obj.getMeshes()) {
			m.material.mainPass.enableLights = true;
			m.material.shadows = false;
			m.material.allocPass("depth");
			m.material.allocPass("normal");
			m.material.texture = hxd.Res.load("Elf/0" + id + ".jpg").toTexture();
			m.setScale(1.2);
		}

		meshRotate(obj);
		play("fly");
		obj.currentAnimation.setFrame(Math.random() * (obj.currentAnimation.frameCount - 1));

		light = new h3d.scene.PointLight();
		light.color.setColor(color);
		light.params = new h3d.Vector(0.5, 0.1, 0.02);
		light.y += 1;
		obj.addChild(light);
		fxParts = new Map();
		addTrailFx();
		addHeadFx();
	}

	function addTrailFx() {
		for(i in 0...obj.numChildren) {
			var o = obj.getChildAt(i);
			if( o.name == null ) continue;
			var tmp = o.name.split("_");
			if(tmp[0] == "body") {
				var name = "TrailStart";
				var fx = addFx(name);
				if( fx != null ) {
					fx.getGroup(name).texture = hxd.Res.load("Fx/Drop0" + id + "[ADD].jpg").toTexture();
					fx.visible = canMove;
					o.addChild(fx);

					var g = fx.getGroup(name);
					var sc = 0.;
					fx.setScale(0);
					game.event.waitUntil(function(dt) {
						if(fx == null) return true;
						sc = Math.min(1, sc + 0.01 * dt);
						fx.setScale(sc);
						return sc == 1;
					});
				}
			}
		}
	}

	function addHeadFx() {
		for(i in 0...obj.numChildren) {
			var o = obj.getChildAt(i);
			if( o.name == null ) continue;
			var tmp = o.name.split("_");
			if(tmp[0] == "body") {
				var name = "ElfHead";
				var fx = addFx(name);
				if( fx != null ) {
					fx.getGroup(name).texture = hxd.Res.load("Fx/Flame0" + id + "[ADD].jpg").toTexture();
					fx.x += 0.8;
					o.addChild(fx);
				}
			}
		}
	}

	public function createWall() {
		if(!enableWalls) {
			addTrailFx();
			return;
		}
		if(wall != null) lastwall = wall;

		var n = worldNormal;
		var c = new h3d.prim.Cube(1, wallSize, 1);
		c.addNormals();
		c.addUVs();
		c.translate(0, -wallSize * 0.5, -0.5);

		wall = new h3d.scene.Mesh(c, game.s3d);
		wall.material.mainPass.culling = None;
		wall.material.blendMode = Add;
		wall.material.texture = wallTex;
		wall.material.texture.wrap = Repeat;
		wall.scaleX = 0;
		wall.scaleZ = 0.95;

		wall.x = x - dir.x * 0.05;
		wall.y = y - dir.y * 0.05;
		wall.z = z - dir.z * 0.05;
		game.world.walls.push({w : wall, n : n.clone()});

		meshRotate(wall);
		addTrailFx();
	}

	function move(dt : Float) {
		speed = Math.min(speedRef, speed + 0.01 * dt);
		speedAspi += (calcAspiration() - speedAspi) * 0.05 * dt;
		speed += speedAspi;
		x += dir.x * speed * dt;
		y += dir.y * speed * dt;
		z += dir.z * speed * dt;

		if(checkFaceHit()) faceRotate();
	}

	function checkFaceHit() {
		if(game.world.inBounds(x, y, z)) return false;
		do {
			x -= dir.x * speed * 0.01;
			y -= dir.y * speed * 0.01;
			z -= dir.z * speed * 0.01;
		}
		while(!game.world.inBounds(x, y, z));
		return true;
	}

	function faceRotate() {
		if(wall != null)
			wall.scaleX = hxd.Math.distance(x + dir.x * 0.5 - wall.x, y + dir.y * 0.5 - wall.y, z + dir.z * 0.5 - wall.z);

		fadeTrailFx();

		var tmp = dir.clone();
		dir = worldNormal.clone();
		tmp.scale(-1);
		worldNormal = tmp;
		speed = speedRef * 0.5;
		createWall();

		meshRotate(obj);
	}


	function meshRotate(m : h3d.scene.Object) {
		var a = Math.PI * 0.5;
		var n = worldNormal;

		if(n.z != 0) {
			m.setRotate(0, 0, dir.x != 0 ? a * (dir.x - 1) : a * dir.y);
			if(n.z < 0) m.rotate(dir.x * 2 * a, dir.y * 2 * a, 0);
		}
		else if(n.x != 0) {
			m.setRotate(0, 0, 0);
			if(n.x > 0) m.rotate(0, 0, 2 * a);
			m.rotate(0, n.x * a, 0);
			m.rotate( -dir.y * a + (dir.z < 0 ? 2 * a : 0), 0, 0);
		}
		else if(n.y != 0) {
			m.setRotate(0, 0, 0);
			m.rotate(0, -dir.z * a, -n.y * a);
			if(dir.x != 0)	m.rotate(0, dir.x * a, n.y * dir.x * a);
			if(dir.z < 0) m.rotate(0, 0, 2 * a);
		}
	}

	function changeDir(v : Int) {
		if(v == 0) return;
		if(wall != null)
			wall.scaleX = hxd.Math.distance(x + dir.x * wallSize * 0.5 - wall.x, y + dir.y * wallSize * 0.5 - wall.y, z + dir.z * wallSize * 0.5 - wall.z);
		fadeTrailFx();
		dir = setDir(dir, v);
		createWall();
		meshRotate(obj);
	}

	function setDir(dir : h3d.col.Point, v : Int) {
		var d = dir.clone();
		var n = worldNormal;
		if(n.z != 0) {
			var tmp = d.x;
			d.x = d.y * v * -n.z;
			d.y = -tmp * v * -n.z;
		}
		else if(n.x != 0) {
			var tmp = d.y;
			d.y = d.z * v * -n.x;
			d.z = -tmp * v * -n.x;
		}
		else if(n.y != 0) {
			var tmp = d.z;
			d.z = d.x * v * -n.y;
			d.x = -tmp * v * -n.y;
		}
		return d;
	}

	function calcAspiration() {
		//return 0.;

		var v = 0.;
		var r = 1.5;

		sensor.px = x + dir.x; sensor.py = y + dir.y; sensor.pz = z + dir.z;

		var d = setDir(dir, -1);
		sensor.lx = r * d.x; sensor.ly = r * d.y; sensor.lz = r * d.z;
		if(sensorCollide(r))
			v += r - Math.min(r, hxd.Math.distance(pt.x - x, pt.y - y));

		var d = setDir(dir, 1);
		sensor.lx = r * d.x; sensor.ly = r * d.y; sensor.lz = r * d.z;
		if(sensorCollide(r))
			v += r - Math.min(r, hxd.Math.distance(pt.x - x, pt.y - y));
		return v * 0.15;
	}

	function sensorCollide(ray : Float) {
		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == lastwall) continue;
			if(w.n.x != worldNormal.x || w.n.y != worldNormal.y || w.n.z != worldNormal.z) continue;
			if(w.w.getBounds().rayIntersection(sensor, pt) != null) {
				var n = new h3d.col.Point(pt.x - sensor.px, pt.y - sensor.py, pt.z - sensor.pz);
				if(hxd.Math.distanceSq(n.x, n.y, n.z) > ray * ray) continue;
				n.normalize();
				var v = sensor.getDir();
				v.normalize();
				if(v.dot(n) > 0)
					return true;
			}
		}

		for(c in game.world.collides) {
			var r = sensor.clone();
			r.transform(c.m);
			r.normalize();
			if(c.c.rayIntersection(r, pt) != null){
				var n = new h3d.col.Point(pt.x - r.px, pt.y - r.py, pt.z - r.pz);
				if(hxd.Math.distanceSq(n.x, n.y, n.z) > ray * ray) continue;
				return true;
			}
		}

		return false;
	}

	function fadeTrailFx() {
		if(fxParts == null) return;
		var fx = fxParts.get("TrailStart");
		if(fx == null) return;
		fxParts.set("TrailStart", null);

		//
		fx.remove();
		return;
		//

		game.s3d.addChild(fx);
		fxs.push(fx);
		fx.follow = null;
		if(obj == null) {
			fx.remove();
			return;
		}
		fx.x = x;
		fx.y = y;
		fx.z = z;
		meshRotate(fx);
	}

	public function hitBonus(k : ent.Bonus.BonusKind) {
		trace(k);
	}

	function destroy() {
		dead = true;
		if(wall != null)
			wall.scaleX = hxd.Math.distance(x - wall.x, y - wall.y, z - wall.z);

		obj.visible = false;
		fadeTrailFx();

		//
		Sounds.play("Crash");
		if(game.players[0] == this)
			game.shake(0.1, 0.9);

		var parts = new h3d.parts.Particles();
		parts.x = x;
		parts.y = y;
		parts.z = z;
		parts.material.texture = hxd.Res.load("Fx/Drop0" + id + "[ADD].jpg").toTexture();
		parts.material.blendMode = Add;
		game.s3d.addChild(parts);

		for(i in 0...200) {
			var p = parts.alloc();
			p.size = 0.1 + Math.random() * 0.2;

			var pow = i > 100 ? 0.5 : 1.5;
			var n = new h3d.Vector(dir.x + hxd.Math.srand(pow), dir.y + hxd.Math.srand(pow), dir.z + hxd.Math.srand(pow));
			n.normalize();
			p.dx = n.x;
			p.dy = n.y;
			p.dz = n.z;
			p.fx = (i > 150 ? 0.5 : 0.1) + Math.random() * 0.5; //speed
			p.fy = -0.003; //growth
			p.fz = 0;	//gravity
		}

		var wsize = game.size >> 1;
		game.event.waitUntil(function(dt) {
			for(p in parts.getParticles()) {
				p.x += p.dx * p.fx;
				p.y += p.dy * p.fx;
				p.z += p.dz * p.fx;
				p.fx *= Math.pow(0.99, dt);

				p.z += p.fz;
				p.fz -= 0.005 * dt;
				if(p.z < -wsize) {
					p.z = -wsize + 0.2;
					p.fz = -p.fz * 0.5;
				}

				if(p.size > 0) {
					p.size += p.fy * dt;
					if(p.size <= 0.05) {
						p.size = 0;
						p.remove();
					}
				}
			}

			if(parts.count == 0) {
				game.players.remove(this);
				if(kind != IA && game.customScene.views.length == 1 && game.players.length > 0) {
					var pl = game.players[0];
					var v = game.customScene.views[0];
					v.id = pl.id;
					v.camera = game.initCamera(pl);
					game.s3d.camera = v.camera;
				}
				parts.remove();
				parts.dispose();
				return true;
			}
			return false;
		});
	}

	var box : h3d.scene.Box;
	function hitTest() {
		if(!enableCollides) return false;
		var n = worldNormal;

		var colBounds = obj.getBounds();
		colBounds.scaleCenter(0.1);
		colBounds.offset( -dir.x * 0.75, -dir.y * 0.75 , -dir.z * 0.75);

		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == lastwall) continue;
			if(w.n.x != n.x || w.n.y != n.y || w.n.z != n.z) continue;
			var b = w.w.getBounds();
			if(b.collide(colBounds)) {
				//new h3d.scene.Box(b, false, game.s3d);
				destroy();
				return true;
			}
		}
/*
		if(game.players[0] == this){
			if(box != null) box.remove();
			box = new h3d.scene.Box(colBounds, false, game.s3d);
			obj.visible = false;
		}
*/
		if(game.world.collide(this)) {
			destroy();
			return true;
		}
		return false;
	}

	override public function update(dt : Float) {
		super.update(dt);
		hitTest();
		if(!dead && wall != null)
			wall.scaleX = hxd.Math.distance(x - wall.x, y - wall.y, z - wall.z);

		if(!dead && canMove && wall == null && enableWalls) {
			createWall();
			if(fxParts != null) {
				var fx = fxParts.get("TrailStart");
				if(fx != null)
					fx.visible = canMove;
			}
		}
	}
}