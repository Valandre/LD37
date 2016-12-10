typedef SfxContext = Map<String, Array<hxd.res.Sound>>;

class Sfx {

	var allSounds : Map<String,SfxContext>;
	var globalContext : SfxContext;

	public function new() {
		allSounds = new Map();
		globalContext = new SfxContext();
	}

	function getSfxPrefix( e : ent.Entity ) {
		return Std.string(e.kind).toLowerCase();
	}

	function listSounds( path : String ) {
		var loader = hxd.Res.loader;
		var sounds = [];
		var i = 1;
		while( true ) {
			var path = path + (i < 10 ? "0" : "") + (i++) + ".wav";
			if( !loader.exists(path) ) break;
			sounds.push(loader.load(path).toSound());
		}
		if( sounds.length == 0 && loader.exists(path+".wav") )
			sounds.push(loader.load(path+".wav").toSound());
		return sounds;
	}

	function getSounds( name : String, ?e : ent.Entity ) {
		if( e != null ) {
			var sounds = listSounds("sfx/anims/" + getSfxPrefix(e) + "_" + name);
			if( sounds.length > 0 )
				return sounds;
			var sounds = listSounds("sfx/anims/" + name);
			if( sounds.length > 0 )
				return sounds;
		}
		return listSounds("sfx/" + name);
	}

	public function ui( r : hxd.res.Sound ) {
		var level = Game.getSfxLevel();
		if( level > 0 )
			r.play(false,level);
	}

	public function play( name : String, ?e : ent.Entity ) {
		var level = Game.getSfxLevel();
		if( level == 0 ) return;

		var context;
		if( e == null )
			context = globalContext;
		else {
			context = @:privateAccess e.sfxCache;
			if( context == null ) {
				var prefix = getSfxPrefix(e);
				context = allSounds.get(prefix);
				if( context == null ) {
					context = new SfxContext();
					allSounds.set(prefix, context);
				}
				@:privateAccess e.sfxCache = context;
			}
		}
		var sounds = context.get(name);
		if( sounds == null ) {
			sounds = getSounds(name, e);
			context.set(name, sounds);
		}
		var sound = sounds[Std.random(sounds.length)];
		/*
		if( e != null && e.logSfx != null ) {
			var text = getSfxPrefix(e) + "_" + name;
			e.logSfx.text = text;
			haxe.Timer.delay(function() if( e.logSfx.text == text ) e.logSfx.text = "", 2000);
		}*/
		var forcePlay = name == "command" || name == "spawn";
		if( sound != null && (e == null || forcePlay) )
			sound.play(false,level);
	}

}