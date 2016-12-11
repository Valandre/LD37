package;
import hxd.Key in K;

private class Button extends h2d.Flow {
	var game : Game;
	var tf : h2d.Text;
	public var selected(default, set) = false;

	public function new (name : String, ?parent : h2d.Sprite) {
		super(parent);
		game = Game.inst;

		tf = new h2d.Text(hxd.Res.font.berlin_sans_fb_bold_48.toFont(), this);
		tf.text = name;
		tf.textColor = 0xFFFFFF;
		tf.alpha = 0.5;

		enableInteractive = true;
	}

	function onOver() {
		var v = 0.;
		game.event.waitUntil(function(dt) {
			if(!selected || tf == null) return true;
			tf.alpha = 0.75 + 0.25 * Math.sin(v);
			v += 0.25 * dt;
			return false;
		});

	}

	function onOut() {
		tf.alpha = 0.5;
	}

	public function onclick() {
		interactive.onClick(null);
	}

	function set_selected(b : Bool) {
		if(b) onOver();
		else onOut();
		return selected = b;
	}
}

private class Player extends h2d.Flow {
	var game : Game;
	var tf : h2d.Text;

	var enable = false;
	var bg : h2d.Bitmap;
	var id : Int;

	public function new (id : Int, ?parent : h2d.Flow) {
		super(parent);
		game = Game.inst;

		this.id = id;


		//this.getProperties(bg).isAbsolute = true;
/*
		if(id > 0) {
			tf = new h2d.Text(hxd.Res.font.berlin_sans_fb_bold_32.toFont(), this);
			tf.text = "PRESS START";
			tf.textColor = 0xFFFFFF;
			tf.alpha = 0.5;

			var v = 0.;
			game.event.waitUntil(function(dt) {
				if(enable) return true;
				tf.alpha = 0.75 + 0.25 * Math.sin(v);
				v += 0.25 * dt;
				return false;
			});
		}*/

		enableInteractive = true;
		needReflow = true;
	}

	public function resize(w : Int, h : Int) {
		if(bg != null) bg.remove();
		bg = new h2d.Bitmap(h2d.Tile.fromColor(game.COLORS[id + 1], w, h), this);
		needReflow = true;
	}
}

class ChoosePlayers extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;

	var players = [];
	var contLeft : h2d.Flow;
	var contRight : h2d.Flow;


	var buttons = [];
	var onRemove : Void -> Void;

	public function new(?parent, onRemove : Void -> Void) {
		super(parent);
		game = Game.inst;

		this.onRemove = onRemove;

		bg = new h2d.Bitmap(h2d.Tile.fromColor(0), this);

		root = new h2d.Flow(this);
		root.horizontalAlign = Left;
		root.isVertical = false;
		root.horizontalSpacing = 0;
		root.verticalSpacing = 0;

		init();

	}

	function init() {
		//
		contLeft = new h2d.Flow(root);
		contLeft.horizontalAlign = Middle;
		contLeft.verticalAlign = Middle;
		contLeft.verticalSpacing = 30;
		contLeft.isVertical = true;

		var back = new Button("BACK", contLeft);
		back.interactive.onClick = function(e) {
			onRemove();
			remove();
		}
		buttons.push(back);

		var ready = new Button("READY!", contLeft);
		ready.interactive.onClick = function(e) {
			remove();
			game.restart();
		}
		buttons.push(ready);

		select(selectId);

		//
		contRight = new h2d.Flow(root);
		contRight.horizontalSpacing = 1;
		contRight.verticalSpacing = 1;
		contRight.isVertical = true;
		contRight.debug = true;

		for(i in 0...4) {
			var pl = new Player(i, contRight);
			players.push(pl);
		}

		onResize();
	}

	function select(id : Int) {
		for( b in buttons)
			b.selected = false;
		buttons[id].selected = true;
	}

	public function onResize() {
		bg.scaleX = game.s2d.width * 0.3;
		bg.scaleY = game.s2d.height;

		root.minWidth = root.maxWidth = game.s2d.width;
		root.minHeight = root.maxHeight = game.s2d.height;

		contLeft.minWidth = contLeft.maxWidth = Std.int(game.s2d.width * 0.3);
		contLeft.minHeight = contLeft.maxHeight = game.s2d.height;
		contLeft.needReflow = true;

		contRight.minWidth = contRight.maxWidth = Std.int(game.s2d.width * 0.7);
		contRight.minHeight = contRight.maxHeight = game.s2d.height;
		contRight.needReflow = true;
/*
		for(p in players)
			p.resize(Std.int(game.s2d.width * 0.7) >> 1, game.s2d.height >> 1);
*/
		root.needReflow = true;
	}

	public function update(dt : Float) {
		if(K.isPressed(K.UP)) {
			selectId--;
			if(selectId < 0) selectId = buttons.length - 1;
			select(selectId);
		}
		if(K.isPressed(K.DOWN)) {
			selectId = (selectId + 1) % buttons.length;
			select(selectId);
		}

		if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE)) {
			buttons[selectId].onclick();
		}

	}
}