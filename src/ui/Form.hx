package ui;
import hxd.Key in K;
import Sounds;

private class Button extends h2d.Flow {
	var game : Game;
	public var selected(default, set) = false;
	public var tiles = [];
	public var bt : h2d.Bitmap;
	var str : String;

	public function new (name : String, ?parent : h2d.Sprite) {
		super(parent);
		game = Game.inst;

		str = name;

		switch(name) {
			case "NEWGAME":
				tiles.push(hxd.Res.UI.Bt_Start0.toTile());
				tiles.push(hxd.Res.UI.Bt_Start1.toTile());
			case "START":
				tiles.push(hxd.Res.UI.Bt_Start0.toTile());
				tiles.push(hxd.Res.UI.Bt_Start1.toTile());
			case "SOUND":
				tiles.push(hxd.Res.UI.Bt_SoundOn0.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOn1.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOff0.toTile());
				tiles.push(hxd.Res.UI.Bt_SoundOff1.toTile());
			case "CREDITS":
				tiles.push(hxd.Res.UI.Bt_Credits0.toTile());
				tiles.push(hxd.Res.UI.Bt_Credits1.toTile());
			case "EXIT":
				tiles.push(hxd.Res.UI.Bt_Exit0.toTile());
				tiles.push(hxd.Res.UI.Bt_Exit1.toTile());
			case "BACK":
				tiles.push(hxd.Res.UI.Bt_Back0.toTile());
				tiles.push(hxd.Res.UI.Bt_Back1.toTile());
			case "NEXT":
				tiles.push(hxd.Res.UI.Bt_Ready0.toTile());
				tiles.push(hxd.Res.UI.Bt_Ready1.toTile());
		}

		bt = new h2d.Bitmap(tiles[0], this);
		bt.blendMode = Alpha;
		enableInteractive = true;
	}

	function onOver() {
		bt.tile = tiles[1];
	}

	function onOut() {
		bt.tile = tiles[0];
	}

	public function onclick() {
		interactive.onClick(null);
	}

	public function setAlpha(v : Float) {
		bt.alpha = v;
	}

	function set_selected(b : Bool) {
		if(b) onOver();
		else onOut();
		return selected = b;
	}
}

class Form extends h2d.Sprite
{
	var bg : h2d.Bitmap;
	var bmpSlide : h2d.Bitmap;
	var game : Game;
	var root : h2d.Flow;
	var selectId = 0;

	var buttonsOld : Array<Button> = [];
	var buttons : Array<MenuButton> = [];
	var title : h2d.Bitmap;
	var cont : h2d.Flow;
	var lock = false;

	var infos : h2d.Sprite;

	public function new(?parent) {
		game = Game.inst;
		if(parent == null) parent = game.s2d;
		super(parent);
		game.windows.push(this);

		bg = new h2d.Bitmap(hxd.Res.UI.corner.toTile(), this);

		title = new h2d.Bitmap(hxd.Res.UI.Title.toTile(), this);
		title.blendMode = Alpha;
		title.filter = true;
		title.x = 50;
		title.y = 50;
		title.visible = false;

		root = new h2d.Flow(this);
		root.horizontalAlign = Middle;
		root.verticalAlign = Middle;
		root.verticalSpacing = 5;
		root.isVertical = false;

		game.setAmbient(0);
		init();

		select(selectId);
		onResize();
		slideIn();
	}

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
		tf.filter = true;
		tf.x -= tf.textWidth * 0.5;
		tf.y -= tf.textHeight * 0.5;
	}

	function init() {
		cont = new h2d.Flow(root);
		cont.horizontalAlign = Middle;
		cont.verticalAlign = Middle;
		cont.verticalSpacing = 30;
		cont.isVertical = true;
		cont.paddingLeft = 170;
		cont.paddingTop = 300;
	}

	override public function onRemove() {
		super.onRemove();
		game.windows.remove(this);
	}

	public function addButton(name : String, scaleOffset = 0, ?parent : h2d.Sprite) {
		var bt = new MenuButton(name, scaleOffset, parent);
		buttons.push(bt);
		return bt;
	}

	public function addButtonOld(name : String, ?parent : h2d.Flow) {
		var bt = new Button(name, parent);
		buttonsOld.push(bt);
		return bt;
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
		for( b in buttons)
			b.selected = false;
		buttons[id].selected = true;
	}

	public function onResize() {
		var sc = game.s2d.height / 1080;

		bg.filter = sc != 1;
		bg.setScale(sc);
		root.minWidth = root.maxWidth = Std.int(bg.scaleX);
		root.minHeight = root.maxHeight = game.s2d.height;
		root.needReflow = true;

		title.setScale(sc);

		cont.paddingLeft = Std.int(170 * sc);
		cont.paddingTop = Std.int(300 * sc);
	}

	public function update(dt : Float) {
		if(lock) return;
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
/*
		if(K.isPressed(K.ENTER) || K.isPressed(K.SPACE) || (game.keys != null && game.keys.pressed.A)) {
			Sounds.play("Select");
			buttonsOld[selectId].onclick();
		}*/
	}
}