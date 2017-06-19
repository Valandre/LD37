package ui;
import hxd.Key in K;
import Sounds;

class Form extends h2d.Sprite
{
	var game : Game;
	/*
	var bg : h2d.Bitmap;
	var bmpSlide : h2d.Bitmap;
	var root : h2d.Flow;
	var selectId = 0;

	var buttons : Array<MenuButton> = [];
	var title : h2d.Bitmap;

	var infos : h2d.Sprite;
	*/

	public function new(?parent) {
		game = Game.inst;
		if(parent == null) parent = game.s2d;
		super(parent);
		game.windows.push(this);

		init();

		/*
		bg = new h2d.Bitmap(hxd.Res.UI.v2.corner.toTile(), this);

		title = new h2d.Bitmap(hxd.Res.UI.Title.toTile(), this);
		title.blendMode = Alpha;
		title.smooth = true;
		title.x = 50;
		title.y = 50;
		title.visible = false;*/
/*
		root = new h2d.Flow(this);
		root.horizontalAlign = Middle;
		root.verticalAlign = Middle;
		root.verticalSpacing = 5;
		root.isVertical = false;

		game.setAmbient(0);
		init();

		select(selectId);
		onResize();
		slideIn();*/
	}
/*
	function setInfos(str : String) {
		if(infos != null)
			infos.remove();

		infos = new h2d.Sprite(bg);
		infos.rotation = -Math.PI * 0.25;
		infos.x = bg.tile.width * 0.345;
		infos.y = bg.tile.height * 0.345;

		var tf = game.text(str, Corner, infos);
		tf.text = str;
		tf.textColor = Const.COLOR_CORNER;
		tf.smooth = true;
		tf.x -= tf.textWidth * 0.5;
		tf.y -= tf.textHeight * 0.5;
	}*/

	function init() {
	}

	override public function onRemove() {
		super.onRemove();
		game.windows.remove(this);
	}
/*
	public function addButton(name : String, kind : MenuButton.ButtonKind, ?parent : h2d.Sprite) {
		var bt = new MenuButton(name, kind, parent);
		buttons.push(bt);
		return bt;
	}*/
/*
	function orderButtons(spacing : Int, ?reverseY = false ) {
		for(i in 0...buttons.length) {
			var b = buttons[i];
			var w = Std.int(b.getSize().width) >> 1;
			b.x = (w + spacing) * i;
			b.y = ((w >> 1) + spacing * 0.5) * ((i % 2) == 0 ? -1 : 1) * (reverseY ? -1 : 1);
		}
	}

	function slideOut(?onEnd : Void -> Void) {
		if( onEnd != null) onEnd();
		return;
	}

	function slideIn(?onEnd : Void -> Void) {
		if( onEnd != null) onEnd();
		return;
	}

	function select(id : Int) {
		if(buttons.length == 0) return;
		for( b in buttons)
			b.selected = false;
		buttons[id].selected = true;
	}
*/

	public function onResize() {
		/*
		var sc = game.s2d.height / 1080;

		bg.smooth = sc != 1;
		bg.setScale(sc);
		root.minWidth = root.maxWidth = Std.int(bg.scaleX);
		root.minHeight = root.maxHeight = game.s2d.height;
		root.needReflow = true;


		title.setScale(sc);*/

	}

	public function update(dt : Float) {
		/*
		if(K.isPressed(K.LEFT) || (game.keys != null && game.keys.pressed.xAxis < 0)) {
			Sounds.play("Over");
			selectId--;
			if(selectId < 0) selectId = buttons.length - 1;
			select(selectId);
		}
		if(K.isPressed(K.RIGHT) || (game.keys != null && game.keys.pressed.xAxis > 0)) {
			Sounds.play("Over");
			selectId = (selectId + 1) % buttons.length;
			select(selectId);
		}

		if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE) || (game.keys != null && game.keys.pressed.A)) {
			if(buttons.length == 0) return;
			Sounds.play("Select");
			buttons[selectId].onClick();
		}*/
	}
}