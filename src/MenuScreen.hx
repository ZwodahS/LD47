import common.AlignmentUtils as AU;
import common.HtmlUtils as HU;
import common.ui.TileButton;

class MenuScreen extends common.Screen {
    static var ButtonWidth: Int = 0;

    public function new() {
        super();
        var t = Assets.packedAssets['button_default'].getTile();
        ButtonWidth = Std.int(t.width);
        var b = new TileButton(Assets.packedAssets['button_default'].getTile(),
            Assets.packedAssets['button_hover'].getTile(), Assets.packedAssets['button_default'].getTile(),
            Assets.packedAssets['button_default'].getTile());
        b.font = Assets.buttonFont;
        b.text = 'New Game';
        b.onOver = function() {
            b.text = HU.font('New Game', 0x63ab3f);
        }
        b.onOut = function() {
            b.text = HU.font('New Game', 0xFFFFFF);
        }
        b.x = AU.center(0, Globals.gameWidth, ButtonWidth);
        b.y = 200;
        this.addChild(b);
        b.onClick = function() {
            this.game.switchScreen(new BasicScreen());
        }
    }

    override public function update(dt: Float) {}

    override public function render(engine: h3d.Engine) {}

    override public function onEvent(event: hxd.Event) {}

    override public function destroy() {}
}
