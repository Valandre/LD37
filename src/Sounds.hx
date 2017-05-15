package;


import flash.events.Event;

typedef S = flash.media.Sound;
typedef C = flash.media.SoundChannel;
typedef T = flash.media.SoundTransform;


@:keep @:sound("res/sfx/bensound-happyrock.mp3")
class Loop extends S {
}

@:keep @:sound("res/sfx/321.mp3")
class Count extends S {
}
@:keep @:sound("res/sfx/go.mp3")
class Go extends S {
}
@:keep @:sound("res/sfx/menu1.mp3")
class Over extends S {
}
@:keep @:sound("res/sfx/menu2.mp3")
class Select extends S {
}
@:keep @:sound("res/sfx/winner.mp3")
class Winner extends S {
}
@:keep @:sound("res/sfx/xplode.wav")
class Crash extends S {
}

class Sounds {

	static var sounds:Map<String, S> = new Map();
	static var musicChannel:C;

	public static function play( name : String ) {
		var s : S = sounds.get(name);
		if( s == null ) {
			var cl = Type.resolveClass(name.charAt(0).toUpperCase() + name.substr(1));
			if( cl == null ) throw "No sound " + name;
			s = Type.createInstance(cl, []);
			sounds.set(name, s);
		}

		if(!Game.PREFS.music) return;

		switch(name) {
			case "Loop":
				if(Game.PREFS.music) {
					var t = new T();
					t.volume = 0.5;
					musicChannel = s.play(0, 99999, t);
				}

			case "Count":
				s.play(0, 0);
			case "Go":
				s.play(0, 0);
			case "Over":
				s.play(0, 0);
			case "Select":
				s.play(0, 0);
			case "Winner":
				s.play(0, 0);
			case "Crash":
				var t = new T();
				t.volume = 0.8;
				s.play(0, 0, t);

				/*
				var t = new T();
				t.volume = 0.6;
				s.play(0, 0, t);*/

		}
	}

	public static function stop(name:String) {
		var s : S = sounds.get(name);

		if( s == null )
			return;

		switch(name) {
			case "Loop":
				musicChannel.stop();
		}
	}
}