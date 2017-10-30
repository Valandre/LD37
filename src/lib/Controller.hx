package lib;

import hxd.Key in K;

class Controller {

	static var _ = "93f1e6349c3587531f4d5b9b4113f271e2ca803c";

	var pad : hxd.Pad;

	var game:Game;
	var pressedFlags : Array<Bool>;
	var padDown : Array<Bool>;

	public var id = 0;
	public var active = false;

	public var down : { xAxis:Float, yAxis:Float, X:Bool, A : Bool, Y : Bool, B : Bool, start : Bool, back : Bool};
	public var pressed : { xAxis:Float, yAxis:Float, X:Bool, A : Bool, Y : Bool, B : Bool, start : Bool, back : Bool};

	public function new(id, pad) {
		game = Game.inst;
		this.pad = pad;
		this.id = id;

		reset();
	}

	public function reset() {
		padDown = [];
		pressedFlags = [];
		down = { xAxis : 0, yAxis : 0, X : false, A : false, Y : false, B : false, start : false, back : false};
		pressed = { xAxis : 0, yAxis : 0, X : false, A : false, Y : false, B : false, start : false, back : false};
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

		//start
		if( down.start ) {
			if( pressedFlags[13] )
				pressed.start = false;
			else {
				pressed.start = true;
				pressedFlags[13] = true;
			}
		} else {
			pressed.start = false;
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


		//X
		if( down.X ) {
			if( pressedFlags[3] )
				pressed.X = false;
			else {
				pressed.X = true;
				pressedFlags[3] = true;
			}
		} else {
			pressed.X = false;
			pressedFlags[3] = false;
		}

		//A
		if( down.A ) {
			if( pressedFlags[2] )
				pressed.A = false;
			else {
				pressed.A = true;
				pressedFlags[2] = true;
			}
		} else {
			pressed.A = false;
			pressedFlags[2] = false;
		}

		//B
		if( down.B ) {
			if( pressedFlags[5] )
				pressed.B = false;
			else {
				pressed.B = true;
				pressedFlags[5] = true;
			}
		} else {
			pressed.B = false;
			pressedFlags[5] = false;
		}

		//Y
		if( down.Y ) {
			if( pressedFlags[4] )
				pressed.Y = false;
			else {
				pressed.Y = true;
				pressedFlags[4] = true;
			}
		} else {
			pressed.Y = false;
			pressedFlags[4] = false;
		}
	}

	public static var defaultPadConfig = {
		var c = hxd.Pad.CONFIG_SDL;
		{
			A : c.A,
			B : c.B,
			X : c.X,
			Y : c.Y,
			start : c.start,
			back : c.back,
			L : c.LB,
			R : c.RB,
			analogX : c.analogX,
			analogY : c.analogY,
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

		if(K.isDown(K.LEFT) || pad.buttons[padConfig.left] || pad.buttons[padConfig.L] ) down.xAxis = -1;
		else if(K.isDown(K.RIGHT) || pad.buttons[padConfig.right] || pad.buttons[padConfig.R] ) down.xAxis = 1;
		else if(Math.abs(pad.values[padConfig.analogX]) > DEAD ) down.xAxis = pad.values[padConfig.analogX];

		if( down.xAxis != 0 && down.yAxis  != 0 ) {
			var d = Math.sqrt(down.xAxis * down.xAxis + down.yAxis * down.yAxis);
			if( d > 1 ) {
				down.xAxis /= d;
				down.yAxis /= d;
			}
		}

		//buttons
		down.start = (K.isDown(K.CTRL) && K.isPressed("F".code)) || pad.buttons[padConfig.start];
		down.X = pad.buttons[padConfig.X];
		down.A = K.isPressed(K.SPACE) || K.isPressed(K.ENTER) || pad.buttons[padConfig.A];
		down.Y = pad.buttons[padConfig.Y];
		down.B = K.isPressed(K.BACKSPACE) || pad.buttons[padConfig.B];
		down.back = pad.buttons[padConfig.back];

		updateState();
	}

}