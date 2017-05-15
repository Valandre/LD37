package ui;
import hxd.Key in K;
import Sounds;

class ChooseArena extends ui.Form
{
	var btBack: NavigateButton;
	var btNext: NavigateButton;

	var container: h2d.Sprite;

	public function new(?parent) {
		super(parent);
		game.setAmbient(1);
	}

	override function init() {
		super.init();

		setInfos(Texts.ui.choose_character);

		container = new h2d.Sprite(this);
		showArenas();


		btBack = new NavigateButton(Texts.navigate.back, this);
		btBack.onClick = function() {
			new ui.ChoosePlayers();
			remove();
		}

		btNext = new NavigateButton(Texts.navigate.next, this);
		btNext.onClick = function() {
			remove();
			game.state.arenaId = selectId;
			game.restart();
		}

		onResize();
	}

	public function showArenas() {
		for(a in Data.arenas.all)
			var bt = addButton(a.name, ArenaSelect, container);

		orderButtons(18, true);
	}

	override public function onResize() {
		super.onResize();

		var sc = game.s2d.height / 1080;
		container.setScale(sc);

		var contSize = container.getSize();
		container.x = (game.s2d.width - contSize.width) * 0.5 - contSize.x;
		container.y = (game.s2d.height - contSize.height) * 0.2 - contSize.y;

		btBack.x = 50;
		btBack.y = game.s2d.height - btBack.getSize().height - 50;

		btNext.x = game.s2d.width - btBack.getSize().width - 50;
		btNext.y = game.s2d.height - btBack.getSize().height - 50;
	}

	override function update(dt : Float) {
		super.update(dt);

		var c = game.controllers[0];
		c.active = true;
		if(c.pressed.B) btBack.onClick();
		if(c.pressed.A) btNext.onClick();
	}
}