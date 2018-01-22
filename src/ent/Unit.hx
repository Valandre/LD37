package ent;
import lib.Controller;
//import Sounds;

typedef Props = {
	kind : Entity.EntityKind,
	modelId : Data.CharsKind,
	color : Int,
}

private class Power {
	public var kind : Data.PowerKind;
	public var time : Float;
	public var value : Float;
	public var progress(default, set) : Float = 0;
	public var active : Bool;

	var data : Data.Power;

	public function new (k : Data.PowerKind) {
		kind = k;
		data = Data.power.get(k);
	}

	public function start() {
		time = data.time;
		value = data.value;
		progress = 0;
		active = true;
	}

	function set_progress(v : Float) {
		return progress = hxd.Math.clamp(v, 0, 1);
	}

	public function ready() {
		return !active && progress == 1;
	}
}

class Wall extends h3d.scene.Mesh {
	public var prev : Wall;
	public var worldNormal : h3d.col.Point;
	public var dir : h3d.col.Point;
	public function new (?prim, ?parent) {
		super(prim, null, parent);
	}
}

class Unit extends Entity
{
	public var dir : h3d.col.Point;
	public var dead = false;
	public var id = 0;
	public var controller : lib.Controller;
	public var enableWalls = true;
	public var enableCollides = true;
	public var canMove = false;
	public var attractRay = 3;

	var props : Props;
	var color : Int = 0xFFFFFF;
	var speedRef = 0.35;
	var speed = 0.;
	var speedBonus = 0.;
	var oldPos : h3d.col.Point;

	var walls : Array<Wall> = [];
	var lastWall(get, null) : Wall;
	var light : h3d.scene.PointLight;
	var w = 1;
	var wallSize = 0.25;
	var wallTex : h3d.mat.Texture;

	var shield : h3d.scene.Mesh;
	var sensor : h3d.col.Ray;
	var boxCollide : h3d.scene.Box;
	var outlineShader : shaders.Outline;

	public var power : Power;

	public function new(kind, props, x = 0., y = 0., z = 0., scale = 1., ?id) {
		if(id == null) this.id = game.players.length + 1;
		else this.id = id;
		color = game.COLORS[this.id];
		this.props = props;

		power = new Power(Data.chars.get(props.modelId).powerId);

		super(kind, x, y, z, scale);

		wallTex = hxd.Res.load("wall0" + this.id + ".png").toTexture();
		speed = speedRef;
		sensor = h3d.col.Ray.fromValues(x, y, z, 0, 0, 0);
		oldPos = new h3d.col.Point();
	}

	override public function remove() {
		super.remove();
		game.players.remove(this);
	}

	override function getModel() : hxd.res.Model {
		return hxd.Res.load("Chars/" + props.modelId + "01/Model.FBX").toModel();
	}

	override function init() {
		super.init();

		for(m in obj.getMeshes()) {
			m.material.mainPass.enableLights = true;
			m.material.shadows = false;
			m.material.allocPass("depth");
			m.material.allocPass("normal");
			m.setScale(1.2);
		}

		setOutline();

		meshRotate(obj);
		play("stand");
		obj.currentAnimation.setFrame(Math.random() * (obj.currentAnimation.frameCount - 1));

		light = new h3d.scene.PointLight();
		light.color.setColor(color);
		light.params = new h3d.Vector(0.5, 0.1, 0.02);
		light.y += 1;
		obj.addChild(light);
		fxParts = new Map();
		addTrailFx();
	}

	function setOutline() {
		if(outlineShader == null) {
			outlineShader = new shaders.Outline();
			outlineShader.size = 0.15;
			outlineShader.distance = 0.001;

			for( m in obj.getMeshes() ) {
				if( m.material.name != null && StringTools.startsWith(m.material.name, "FX") )
					continue;

				var p : h3d.prim.HMDModel = Std.instance(m.primitive, h3d.prim.HMDModel);
				if( p == null )
					continue;

				if( !p.hasBuffer("logicNormal") )
					p.recomputeNormals("logicNormal");

				var multi = Std.instance(m, h3d.scene.MultiMaterial);
				for( m in (multi != null ? multi.materials : [m.material]) ) {
					var p = m.allocPass("outline");
					p.culling = None;
					p.addShader(outlineShader);
				}
			}
		}
		outlineShader.color.setColor(0x322838);
	}

	function get_lastWall() {
		return walls.length == 0 ? null : walls[walls.length - 1];
	}

	function addTrailFx() {
		//////
		return; //fxs emitter is static ? (cf Nico)
		//////

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

	public function createWall() {
		if(!enableWalls) {
			addTrailFx();
			return;
		}

		var n = worldNormal;
		var c = new h3d.prim.Cube(1, wallSize, 1);
		c.addNormals();
		c.addUVs();
		c.translate(0, -wallSize * 0.5, -0.5);

		var wall = new Wall(c, game.s3d);
		wall.prev = lastWall;
		wall.worldNormal = worldNormal.clone();
		wall.dir = dir.clone();


		wall.material.mainPass.culling = None;
		//wall.material.blendMode = Add;
		wall.material.texture = wallTex;
		wall.material.texture.wrap = Repeat;
		wall.scaleX = 0;

		wall.x = x - dir.x * wallSize * 0.5;
		wall.y = y - dir.y * wallSize * 0.5;
		wall.z = z - dir.z * wallSize * 0.5;

		walls.push(wall);
		game.world.walls.push({w : wall, n : n.clone()});

		meshRotate(wall);
		addTrailFx();
	}

	function removeWall(w : Wall) {
		w.remove();
		walls.remove(w);
		game.world.removeWall(w);
	}

	function move(dt : Float) {
		speed = Math.min(speedRef, speed + 0.01 * dt);
		speed += speedBonus;
		x += dir.x * speed * dt;
		y += dir.y * speed * dt;
		z += dir.z * speed * dt;

		if(checkFaceHit()) faceRotate();
	}

	function checkFaceHit() {
		if(game.world.inBounds(x, y, z)) return false;
		do {
			x -= dir.x * speed * 0.05;
			y -= dir.y * speed * 0.05;
			z -= dir.z * speed * 0.05;
		}
		while(!game.world.inBounds(x, y, z));
		return true;
	}

	function faceRotate() {
		var p = getSizedPos();
		x = p.x; y = p.y; z = p.z;

		var wall = lastWall;
		if(wall != null && !isPowerActive(Ghost))
			wall.scaleX = hxd.Math.distance(x - wall.x + dir.x * wallSize*2, y - wall.y + dir.y * wallSize*2, z - wall.z + dir.z * wallSize*2);

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

	function getSizedPos() {
		//replace la position arrondie au multiple de l'epaisseur d'un mur
		var p = new h3d.col.Point();
		p.x = Std.int(x) + Std.int((x % 1) / wallSize) * wallSize;
		p.y = Std.int(y) + Std.int((y % 1) / wallSize) * wallSize;
		p.z = Std.int(z) + Std.int((z % 1) / wallSize) * wallSize;
		return p;
	}

	function changeDir(v : Int) {
		if(v == 0) return;
		var p = getSizedPos();
		x = p.x; y = p.y; z = p.z;

		var wall = lastWall;
		if(wall != null && !isPowerActive(Ghost))
			wall.scaleX = hxd.Math.distance(x - wall.x + dir.x * wallSize * 0.5, y - wall.y + dir.y * wallSize * 0.5, z - wall.z + dir.z * wallSize * 0.5);
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

	function sensorCollide(ray : Float) {
		var d = -1.;
		var wall = lastWall;
		if(wall == null) return d;

		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == wall.prev) continue;
			if(w.n.x != worldNormal.x || w.n.y != worldNormal.y || w.n.z != worldNormal.z) continue;
			d = w.w.getBounds().rayIntersection(sensor, false);
			if(d != -1) {
				if(d > ray) continue;
				return d;
			}
		}

		for(c in game.world.collides) {
			var r = sensor.clone();
			r.transform(c.m);
			d = c.c.rayIntersection(r, false);
			if(d != -1){
				if(d > ray) continue;
				return d;
			}
		}

		return d;
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

	public function hitEnergy() {
		power.progress += 0.2;
	}

	function destroy() {
		dead = true;
		var wall = lastWall;
		if(wall != null && !isPowerActive(Ghost))
			wall.scaleX = hxd.Math.distance(x - wall.x, y - wall.y, z - wall.z);

		obj.visible = false;
		fadeTrailFx();

		//
		//Sounds.play("Crash");
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
		var wall = lastWall;
		if(wall == null) return false;

		var n = worldNormal;
		var cur = getSizedPos();
		var dist = hxd.Math.distance(cur.x - oldPos.x, cur.y - oldPos.y, cur.z - oldPos.z);

		var t = new h3d.col.Point();
		for(w in game.world.walls) {
			if(w.w == wall || w.w == wall.prev) continue;
			if(w.n.x != n.x || w.n.y != n.y || w.n.z != n.z) continue;
			var b = w.w.getBounds();
			var d = 0.;
			while(d < dist) {
				t.x = oldPos.x + dir.x * d;
				t.y = oldPos.y + dir.y * d;
				t.z = oldPos.z + dir.z * d;
				if(b.contains(t)) {
					if(shield != null) {
						useShield(w.w);
						return false;
					}
					x = t.x;
					y = t.y;
					z = t.z;
					return true;
				}
				d += wallSize;
			}
		}
		return game.world.collide(this);
	}

	function useShield(w : h3d.scene.Object) {
		shield.remove();
		shield = null;

		var colBounds = obj.getBounds();
		colBounds.scaleCenter(0.1);
		colBounds.offset( -dir.x * 0.75, -dir.y * 0.75 , -dir.z * 0.75);

		inline function hit() {
			var b = w.getBounds();
			return b.collide(colBounds);
		}

		do move(0.1)
		while(hit());
	}

	public function isPowerActive(k : Data.PowerKind) {
		return power.active && power.kind == k;
	}

	function updatePower(dt : Float) {
		if(speedBonus > 0 && !isPowerActive(SpeedUp)) {
			if(speedBonus > 0) speedBonus *= Math.pow(0.95, dt);
			if(speedBonus < 0.01)  speedBonus = 0;
		}

		if(!power.active) return;
		switch(power.kind) {
			case SpeedUp:
				power.time -= dt / 60;
				if(power.time <= 0)
					power.active = false;
				else speedBonus += (power.value - speedBonus) * 0.25 * dt;

			case Shield:
				power.active = false;
				if(shield != null) return;

				var c = new h3d.prim.Sphere(2, 24, 24);
				c.addUVs();
				c.addNormals();

				shield = new h3d.scene.Mesh(c, obj);
				shield.material.color.setColor(0x2080F0);
				shield.material.blendMode = Alpha;
				shield.material.color.w = 0.5;

			case Rewind:
				var wall = lastWall;
				worldNormal = wall.worldNormal.clone();
				dir = wall.dir.clone();
				meshRotate(obj);

				power.time -= dt / 60;
				if(power.time <= 0) {
					power.active = false;
					canMove = true;
					return;
				}

				canMove = false;
				x -= dir.x * power.value * dt;
				y -= dir.y * power.value * dt;
				z -= dir.z * power.value * dt;

				var old = wall.scaleX;
				wall.scaleX = hxd.Math.distance(x - wall.x, y - wall.y, z - wall.z);
				if(wall.scaleX >= old) {
					x = wall.x;
					y = wall.y;
					z = wall.z;
					if(wall.prev == null) {
						power.active = false;
						canMove = true;
						return;
					}
					else removeWall(wall);
				}
			case Ghost:
				power.time -= dt / 60;
				if(power.time <= 0) {
					power.active = false;
					enableWalls = true;
					createWall();
					lastWall.prev = null;
					return;
				}
				enableWalls = false;
		}
	}

	override public function update(dt : Float) {
		super.update(dt);

		if(canMove && !dead) {
			play("run");
			if(hitTest()) {
				destroy();
				return;
			}
			oldPos = getSizedPos();
		}

		if(!isPowerActive(Ghost)) {
			var wall = lastWall;
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

		if(!dead)
			updatePower(dt);
	}
}