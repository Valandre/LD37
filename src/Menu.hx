package;
import hxd.Key in K;

private class Button extends h2d.Flow {
	var game : Game;
	public var tf : h2d.Text;
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

class Menu extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;

	var buttons = [];
	var choose : ChoosePlayers;

	public function new(?parent) {
		super(parent);
		game = Game.inst;

		bg = new h2d.Bitmap(h2d.Tile.fromColor(0), this);

		root = new h2d.Flow(this);
		root.horizontalAlign = Middle;
		root.verticalAlign = Middle;
		root.verticalSpacing = 5;
		root.isVertical = true;

		init();

		//hxd.Pad.wait(function(p) trace(p));
	}

	function init() {
		var cont = new h2d.Flow(root);
		cont.horizontalAlign = Middle;
		cont.verticalAlign = Middle;
		cont.verticalSpacing = 30;
		cont.isVertical = true;

		var start = new Button("START", cont);
		start.interactive.onClick = function(e) {
			choose = new ChoosePlayers(game.s2d, function() {
				choose = null;
			});
		}
		buttons.push(start);

		var exit = new Button("EXIT", cont);
		exit.interactive.onClick = function(e) hxd.System.exit();
		buttons.push(exit);

		select(selectId);
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

		root.minWidth = root.maxWidth = Std.int(bg.scaleX);
		root.minHeight = root.maxHeight = game.s2d.height;
		root.needReflow = true;

		if(choose != null)
			choose.onResize();
	}

	public function update(dt : Float) {
		if(choose != null)
			choose.update(dt);
		else {
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
}