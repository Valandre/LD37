package ent;
//import Sounds;

enum EntityKind {
	Player;
	IA;
	Energy;
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
	public var kind : EntityKind;
	public var x(default, set) : Float;
	public var y(default, set) : Float;
	public var z(default, set) : Float;
	public var worldNormal = new h3d.col.Point(0, 0, 1);

	var game : Game;
	var scale(default, set) : Float;
	var model : hxd.res.Model;
	var obj : h3d.scene.Object;

	var currentAnim(default,set) : { opts : PlayOptions, name : String };
	var currentAnimEnd : h3d.anim.Animation;
	var cachedAnims = new Map<String,AnimationCommand>();
	var currFx : h3d.scene.Object;
	var fxParts : Map<String,h3d.parts.GpuParticles>;
	var fxs = [];

	public function new(kind, x = 0., y = 0., z = 0., scale = 1.) {
		game = Game.inst;
		game.entities.push(this);
		this.kind = kind;

		init();
		if(obj != null) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.scale = scale;
		}
	}

	public function remove() {
		if(obj != null)
			obj.remove();
		game.entities.remove(this);

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

	function getModel() : hxd.res.Model {
		return null;
	}

	function init() {
		var res = getModel();
		if( res == null ) return;
		model = res;
		obj = game.modelCache.loadModel(res);
		obj.inheritCulled = true;
		game.s3d.addChild(obj);
	}

	public function getBounds() {
		return obj == null ? null : obj.getBounds();
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

	public function update(dt : Float) {
	}
}