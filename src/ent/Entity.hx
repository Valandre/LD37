package ent;

enum EntityKind {
	Player;
	IA;
}

typedef PlayOptions = {
	@:optional var speed : Float;
	@:optional var loop : Bool;
	@:optional var smooth : Float;
	@:optional var onEnd : Void -> Void;
}

enum AnimationCommand {
	ASingle( a : h3d.anim.Animation );
	AComplex( start : Null<h3d.anim.Animation>, loop : h3d.anim.Animation, end : Null<h3d.anim.Animation> );
	AFX( a : AnimationCommand, fxMesh : hxd.res.Model, fxAnim : h3d.anim.Animation );
}

class Entity
{
	var game : Game;
	public var kind : EntityKind;
	public var x(default, set) : Float;
	public var y(default, set) : Float;
	public var z(default, set) : Float;

	var scale(default, set) : Float;
	var model : hxd.res.Model;
	var obj : h3d.scene.Object;
	var color : Int = 0xFFFFFF;
	var speedRef = 0.4;
	var speed = 0.;
	public var dir : h3d.col.Point;
	public var worldNormal = new h3d.col.Point(0, 0, 1);

	var currentAnim(default,set) : { opts : PlayOptions, name : String };
	var currentAnimEnd : h3d.anim.Animation;
	var cachedAnims = new Map<String,AnimationCommand>();
	var currFx : h3d.scene.Object;
	var fxParts : Map<String,h3d.parts.GpuParticles>;
	var fxs = [];

	var wall : h3d.scene.Mesh;
	var lastwall : h3d.scene.Mesh;
	var light : h3d.scene.PointLight;
	public var canMove = false;
	var w = 1;
	var wallSize = 0.4;
	var wallTex : h3d.mat.Texture;
	public var dead = false;

	public var id = 0;

	public var controller : Controller;

	public function new(kind, x = 0., y = 0., z = 0., scale = 1., ?id) {
		game = Game.inst;
		game.entities.push(this);

		if(id == null)
			this.id = game.players.length + 1;
		else this.id = id;
		//if(kind == IA) this.id = 0;
		color = game.COLORS[id];

		init();
		this.kind = kind;
		this.x = x + Std.random(5) - 2;
		this.y = y + Std.random(5) - 2;
		this.z = z;
		this.scale = scale;

		wallTex = hxd.Res.load("wall0" + this.id + ".png").toTexture();
		speed = speedRef;
	}

	public function remove() {
		if(obj != null)
			obj.remove();
		game.entities.remove(this);
		game.players.remove(this);

		if(fxParts != null)
			for(k in fxParts.keys()) {
				var fx = fxParts.get(k);
				if(fx != null)
					fx.remove();
				fxParts.remove(k);
			}
		fxParts = null;

		while(fxs.length > 0)
			fxs.pop().remove();
	}

	function init() {

		var res = hxd.Res.load("Elf/Model.FBX").toModel();
		if( res == null ) return;
		model = res;
		obj = game.modelCache.loadModel(res);
		obj.inheritCulled = true;
		game.s3d.addChild(obj);

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
		//light.params = new h3d.Vector(0.8, 0.5, 0.1);
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
					//g.displayedParts = 0;
					var sc = 0.;
					fx.setScale(0);
					game.event.waitUntil(function(dt) {
						if(fx == null) return true;
						//g.displayedParts = hxd.Math.imin(g.nparts, g.displayedParts + 10);
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

	public function addFx(name : String, ?alias : String, ?addToFxs = true ) {
		if(fxParts == null) return null;
		var f : hxd.fs.FileEntry = try hxd.Res.load("Fx/" + name + ".json").entry catch( e : Dynamic ) return null;
		var p = new h3d.parts.GpuParticles();
		p.name = alias != null ? alias : name;
		try p.load(haxe.Json.parse(f.getText()), f.path) catch( e : Dynamic ) {
			trace(f.path + ":" + e);
			p.remove();
			return null;
		}
		var prev = fxParts.get(p.name);
		if( prev != null )
			prev.remove();
		if(addToFxs) fxParts.set(p.name, p);
		return p;
	}

	public function removeFx(name : String) {
		if(fxParts == null) return;
		var fx = fxParts.get(name);
		if(fx != null) {
			fx.remove();
			fxParts.remove(name);
		}
	}

	public function createWall() {
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

	public function play( anim : String, ?opts : PlayOptions ) {
		anim = resolveAnimKey(anim);
		if( currentAnim != null && currentAnim.name == anim ) return;
		if( opts == null ) opts = { };
		if( opts.speed == null ) opts.speed = 1;
		if( opts.smooth == null ) opts.smooth = 0.2;
		if( opts.loop == null ) opts.loop = true;
		currentAnim = { opts : opts, name : anim };
	}

	function resolveAnimKey(anim) {
		return anim;
	}

	function set_currentAnim(c) {
		currentAnim = c;
		if( c == null || obj == null )
			return c;
		var anim = c.name;
		var a = cachedAnims.get(anim);
		if( a == null ) {
			a = getAnim(anim);
			if( a == null ) throw "Can't find anim " + anim +" for " + kind;
			cachedAnims.set(anim, a);
		}

		playImpl(a);
		return c;
	}

	function getAnimPath() {
		return model.entry.directory;
	}

	function getAnim(name:String) : AnimationCommand {
		var loader = hxd.Res.loader;
		inline function load(path) return game.modelCache.loadAnimation(loader.load(path+".FBX").toModel());
		var path = getAnimPath() + "/Anim_" + name;

		var hasAnim = loader.exists(path + ".FBX");
		var hasLoop = hxd.Res.loader.exists(path + "_loop.FBX");

		if( !hasAnim && !hasLoop )
			return null;

		var hasEnd = hxd.Res.loader.exists(path + "_end.FBX");
		if( hasAnim && !hasLoop && !hasEnd ) {
			var fxPath = "Fx/";
			fxPath += "Fx_" + name;
			var hasFX = hxd.Res.loader.exists(fxPath + ".FBX");
			if( hasFX ) {
				var res = hxd.Res.load(fxPath + ".FBX").toModel();
				return AFX(ASingle(load(path)), res, load(fxPath));
			}
			return ASingle(load(path));
		}

		if( hasLoop && !hasAnim && !hasEnd )
			return ASingle(load(path + "_loop"));

		return AComplex(hasAnim?load(path):null, load(path + "_loop"), hasEnd?load(path + "_end"):null);
	}

	function playImpl( a : AnimationCommand ) {
		if(currFx != null) {
			currFx.remove();
			currFx = null;
		}

		if( currentAnimEnd != null ) {
			waitAnimEnd(function() playImpl(a));
			return;
		}

		if( obj == null ) return;


		inline function playAnimation(a, loop) {
			obj.playAnimation(a);
			if( loop ) @:privateAccess obj.currentAnimation.frameCount--;
		}

		var opts = currentAnim.opts;
		var onEnd = opts.onEnd;
		var prev = obj.currentAnimation;
		switch( a ) {
		case ASingle(a):
			playAnimation(a,opts.loop);
			obj.currentAnimation.onAnimEnd = function() {
				if( onEnd != null ) onEnd();
			};

		case AFX(anim, fxModel, fxAnim):
			playImpl(anim);

			currFx = game.modelCache.loadModel(fxModel);
			obj.addChild(currFx);
			currFx.playAnimation(fxAnim);
			currFx.currentAnimation.loop = false;
			currFx.currentAnimation.onAnimEnd = currFx.remove;
			return;

		case AComplex(start, loop, end):
			if( start == null ) {
				playAnimation(loop, opts.loop);
				obj.currentAnimation.onAnimEnd = function() {
					if( onEnd != null ) onEnd();
				};
			} else {
				playAnimation(start, false);
				obj.currentAnimation.onAnimEnd = function() {
					playAnimation(loop, opts.loop);
					obj.currentAnimation.speed = opts.speed;
					obj.currentAnimation.onAnimEnd = function() {
						if( onEnd != null ) onEnd();
					};
				}
			}
			currentAnimEnd = end;
		}
		obj.currentAnimation.speed = opts.speed;

		if( prev != null && opts.smooth != 0 ) {
			var cur = obj.currentAnimation;
			var sm = new h3d.anim.SmoothTarget(cur, opts.smooth);
			obj.switchToAnimation(sm);
			sm.onAnimEnd = function() obj.switchToAnimation(cur);
		}
	}

	function waitAnimEnd( f ) {
		if( currentAnimEnd == null ) {
			f();
			return;
		}
		var cur = obj.currentAnimation;
		if( cur == null ) throw "No current anim";
		obj.playAnimation(currentAnimEnd);
		obj.currentAnimation.speed = cur.speed;
		obj.currentAnimation.onAnimEnd = f;
		obj.currentAnimation.loop = false;
		obj.switchToAnimation(new h3d.anim.SmoothTarget(obj.currentAnimation, 0.5));
		currentAnimEnd = null;
	}

	function getModel() : hxd.res.Model {
		return null;
	}

	function set_x(v : Float) {
		if(obj != null)
			obj.x = v;
		return x = v;
	}

	function set_y(v : Float) {
		if(obj != null)
			obj.y = v;
		return y = v;
	}

	function set_z(v : Float) {
		if(obj != null)
			obj.z = v;
		return z = v;
	}

	function set_scale(v : Float) {
		if(obj != null)
			obj.setScale(v);
		return scale = v;
	}

	function destroy() {
		dead = true;
		if(wall != null)
			wall.scaleX = hxd.Math.distance(x + dir.x * 0.5 - wall.x, y + dir.y * 0.5 - wall.y, z + dir.z * 0.5 - wall.z);

		obj.visible = false;
		fadeTrailFx();

		//
		Sounds.play("Crash");

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
				//remove();
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

		//remove();
	}

	function hitTest() {
		var n = worldNormal;
		var colBounds = obj.getBounds();
		colBounds.scaleCenter(0.2);
		colBounds.offset( -dir.x * 0.5, -dir.y * 0.5, -dir.z * 0.5);
		for(w in game.world.walls) {
			if(w.w == wall) continue;
			if(w.w == lastwall) continue;
			if(w.n.x != n.x || w.n.y != n.y || w.n.z != n.z) continue;
			if(w.w.getBounds().collide(colBounds)) {
				destroy();
				return true;
			}
		}

		if(game.world.isCollide(this)) {
			destroy();
			return true;
		}
		return false;
	}

	public function update(dt : Float) {
		if(wall != null)
			wall.scaleX = hxd.Math.distance(x - wall.x, y - wall.y, z - wall.z);
		hitTest();

		if(canMove && wall == null) {
			createWall();
			if(fxParts != null) {
				var fx = fxParts.get("TrailStart");
				if(fx != null)
					fx.visible = canMove;
			}
		}
	}
}