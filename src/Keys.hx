import hxd.Key in K;

class Keys {

	static var _ = "93f1e6349c3587531f4d5b9b4113f271e2ca803c";

	public var next : Bool;
	public var prev : Bool;

	static var pad : hxd.Pad;

	var game:Game;
	var pressedFlags : Array<Bool>;
	var padDown : Array<Bool>;

	public var usePad = false;

	public var down : { xAxis:Float, yAxis:Float, xAxis2:Float, yAxis2:Float, attack:Bool, jump : Bool, guard : Bool, dash : Bool, menu : Bool, back : Bool};
	public var pressed : { xAxis:Float, yAxis:Float, xAxis2:Float, yAxis2:Float, attack:Bool, jump : Bool, guard : Bool, dash : Bool, menu : Bool, back : Bool};

	public function new() {
		game = Game.inst;
		if( pad == null ) {
			pad = hxd.Pad.createDummy();
			hxd.Pad.wait(function(p) pad = p);
		}
		reset();
		usePad = true;
	}

	public function reset() {
		next = false;
		prev = false;
		padDown = [];
		pressedFlags = [];
		down = { xAxis : 0, yAxis : 0, xAxis2:0, yAxis2:0, attack : false, jump : false, guard : false, dash : false, menu : false, back : false};
		pressed = { xAxis : 0, yAxis : 0, xAxis2:0, yAxis2:0, attack : false, jump : false, guard : false, dash : false, menu : false, back : false};
	}

	function updateState() {
		//X Axis
		if( down.xAxis != 0 ) {
			if( pressedFlags[0] )
				pressed.xAxis = 0;
			else {
				pressed.xAxis = down.xAxis;
				pressedFlags[0] = true;
			}
		} else {
			pressed.xAxis = 0;
			pressedFlags[0] = false;
		}

		//Y Axis
		if( down.yAxis != 0 ) {
			if( pressedFlags[1] )
				pressed.yAxis = 0;
			else {
				pressed.yAxis = down.yAxis;
				pressedFlags[1] = true;
			}
		} else {
			pressed.yAxis = 0;
			pressedFlags[1] = false;
		}

		/*
		//X Axis2
		if( down.xAxis2 != 0 ) {
			if( pressedFlags[0] )
				pressed.xAxis2 = 0;
			else {
				pressed.xAxis2 = down.xAxis;
				pressedFlags[0] = true;
			}
		} else {
			pressed.xAxis2 = 0;
			pressedFlags[0] = false;
		}

		//Y Axis2
		if( down.yAxis2 != 0 ) {
			if( pressedFlags[1] )
				pressed.yAxis2 = 0;
			else {
				pressed.yAxis2 = down.yAxis;
				pressedFlags[1] = true;
			}
		} else {
			pressed.yAxis2 = 0;
			pressedFlags[1] = false;
		}*/

		//menu
		if( down.menu ) {
			if( pressedFlags[13] )
				pressed.menu = false;
			else {
				pressed.menu = true;
				pressedFlags[13] = true;
			}
		} else {
			pressed.menu = false;
			pressedFlags[13] = false;
		}

		//back
		if( down.back ) {
			if( pressedFlags[12] )
				pressed.back = false;
			else {
				pressed.back = true;
				pressedFlags[12] = true;
			}
		} else {
			pressed.back = false;
			pressedFlags[12] = false;
		}


		//attack
		if( down.attack ) {
			if( pressedFlags[3] )
				pressed.attack = false;
			else {
				pressed.attack = true;
				pressedFlags[3] = true;
			}
		} else {
			pressed.attack = false;
			pressedFlags[3] = false;
		}

		//jump
		if( down.jump ) {
			if( pressedFlags[2] )
				pressed.jump = false;
			else {
				pressed.jump = true;
				pressedFlags[2] = true;
			}
		} else {
			pressed.jump = false;
			pressedFlags[2] = false;
		}

		//dash
		if( down.dash ) {
			if( pressedFlags[5] )
				pressed.dash = false;
			else {
				pressed.dash = true;
				pressedFlags[5] = true;
			}
		} else {
			pressed.dash = false;
			pressedFlags[5] = false;
		}

		//guard
		if( down.guard ) {
			if( pressedFlags[4] )
				pressed.guard = false;
			else {
				pressed.guard = true;
				pressedFlags[4] = true;
			}
		} else {
			pressed.guard = false;
			pressedFlags[4] = false;
		}
	}

	public static var defaultPadConfig = {
		var c = hxd.Pad.CONFIG_XBOX;
		{
			jump : c.A,
			dash : c.B,
			attack : c.X,
			guard : c.Y,
			menu : c.start,
			back : c.back,
			L : c.LB,
			R : c.RB,
			analogX : c.analogX,
			analogY : c.analogY,
			analogX2 : c.ranalogX,
			analogY2 : c.ranalogY,
			analogYInv : true,
			left : c.dpadLeft,
			right : c.dpadRight,
			up : c.dpadUp,
			down : c.dpadDown,
		};
	}
	public static var padConfig = loadPadConfig();

	static function loadPadConfig() {
		var cfg = defaultPadConfig;
		try {
			cfg = haxe.Json.parse(hxd.File.getBytes("gamePadConfig.txt").toString());
		} catch( e : Dynamic ) {
		}
		return cfg;
	}

	public function update(dt:Float) {

		//move
		down.xAxis = 0; down.yAxis = 0;
		var DEAD = 0.4;
		if(K.isDown(K.UP) || pad.buttons[padConfig.up] ) down.yAxis = -1;
		else if(K.isDown(K.DOWN) || pad.buttons[padConfig.down] ) down.yAxis = 1;
		else if(Math.abs(pad.values[padConfig.analogY]) > DEAD ) down.yAxis = pad.values[padConfig.analogY] * (padConfig.analogYInv ? -1 : 1);
		if(K.isDown(K.LEFT) || pad.buttons[padConfig.left] ) down.xAxis = -1;
		else if(K.isDown(K.RIGHT) || pad.buttons[padConfig.right] ) down.xAxis = 1;
		else if(Math.abs(pad.values[padConfig.analogX]) > DEAD ) down.xAxis = pad.values[padConfig.analogX];
		if( down.xAxis != 0 && down.yAxis  != 0 ) {
			var d = Math.sqrt(down.xAxis * down.xAxis + down.yAxis * down.yAxis);
			if( d > 1 ) {
				down.xAxis /= d;
				down.yAxis /= d;
			}
		}

		//move2
		down.xAxis2 = 0; down.yAxis2 = 0;
		if(Math.abs(pad.values[padConfig.analogY2]) > DEAD ) down.yAxis2 = pad.values[padConfig.analogY2] * (padConfig.analogYInv ? -1 : 1);
		if(Math.abs(pad.values[padConfig.analogX2]) > DEAD ) down.xAxis2 = pad.values[padConfig.analogX2];
		if( down.xAxis2 != 0 && down.yAxis2  != 0 ) {
			var d = Math.sqrt(down.xAxis2 * down.xAxis2 + down.yAxis2 * down.yAxis2);
			if( d > 1 ) {
				down.xAxis2 /= d;
				down.yAxis2 /= d;
			}
		}

		//buttons
		down.menu = (K.isDown(K.CTRL) && K.isPressed("F".code)) || pad.buttons[padConfig.menu];
		down.attack = K.isPressed("C".code) || pad.buttons[padConfig.attack];
		down.jump = K.isPressed(K.SPACE) || pad.buttons[padConfig.jump];
		down.guard = K.isPressed("V".code) || pad.buttons[padConfig.guard];
		down.dash = K.isPressed("X".code) || pad.buttons[padConfig.dash];
		down.back = pad.buttons[padConfig.back];

		updateState();
	}

}