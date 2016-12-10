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
	var speedRef = 0.3;
	var speed = 0.;
	public var dir = new h3d.col.Point(1, 0, 0);

	var currentAnim(default,set) : { opts : PlayOptions, name : String };
	var currentAnimEnd : h3d.anim.Animation;
	var cachedAnims = new Map<String,AnimationCommand>();
	var sfxCache : Sfx.SfxContext;

	public function new(kind, x = 0., y = 0., z = 0., scale = 1.) {
		game = Game.inst;
		game.entities.push(this);
		init();
		this.kind = kind;
		this.x = x;
		this.y = y;
		this.z = z;
		this.scale = scale;
		speed = speedRef;
	}

	public function remove() {
		if(obj != null)
			obj.remove();
		game.entities.remove(this);
	}

	function init() {
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
		if( hasAnim && !hasLoop && !hasEnd )
			return ASingle(load(path));

		if( hasLoop && !hasAnim && !hasEnd )
			return ASingle(load(path + "_loop"));

		return AComplex(hasAnim?load(path):null, load(path + "_loop"), hasEnd?load(path + "_end"):null);
	}

	function playImpl( a : AnimationCommand ) {

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
			sfx(currentAnim.name);
			playAnimation(a,opts.loop);
			obj.currentAnimation.onAnimEnd = function() {
				if( opts.loop ) sfx(currentAnim.name);
				if( onEnd != null ) onEnd();
			};

		case AComplex(start, loop, end):
			if( start == null ) {
				sfx(currentAnim.name);
				playAnimation(loop, opts.loop);
				obj.currentAnimation.onAnimEnd = function() {
					if( opts.loop ) sfx(currentAnim.name);
					if( onEnd != null ) onEnd();
				};
			} else {
				sfx(currentAnim.name+"_start");
				playAnimation(start, false);
				obj.currentAnimation.onAnimEnd = function() {
					sfx(currentAnim.name);
					playAnimation(loop, opts.loop);
					obj.currentAnimation.onEvent = onAnimEvent;
					obj.currentAnimation.speed = opts.speed;
					obj.currentAnimation.onAnimEnd = function() {
						if( opts.loop ) sfx(currentAnim.name);
						if( onEnd != null ) onEnd();
					};
				}
			}
			currentAnimEnd = end;
		}
		obj.currentAnimation.onEvent = onAnimEvent;
		obj.currentAnimation.speed = opts.speed;

		if( prev != null && opts.smooth != 0 ) {
			var cur = obj.currentAnimation;
			var sm = new h3d.anim.SmoothTarget(cur, opts.smooth);
			obj.switchToAnimation(sm);
			sm.onAnimEnd = function() obj.switchToAnimation(cur);
		}
	}

	function waitAnimEnd( f : Void -> Void ) {
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


	function sfx( name : String ) {
		game.sfx.play(name, this);
	}

	function onAnimEvent( e : String ) {
		if( e == "sfx" )
			sfx(currentAnim.name+"_event");
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

	public function update(dt : Float) {
	}
}