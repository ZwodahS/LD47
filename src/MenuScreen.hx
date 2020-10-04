import common.AlignmentUtils as AU;
import common.HtmlUtils as HU;
import common.ui.TileButton;

class MenuScreen extends common.Screen {
    static var ButtonWidth: Int = 0;

    var c1: h2d.Bitmap;
    var c2: h2d.Bitmap;
    var control: Int = 1;

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
        b.y = 250;
        this.addChild(b);
        b.onClick = function() {
            startGame();
        }

        var font = Assets.fontMontserrat32.toFont();
        var text = new h2d.Text(font);
        text.text = 'LOOP INVADERS';
        text.x = AU.center(0, Globals.gameWidth, text.textWidth);
        text.y = 180;
        this.addChild(text);

        font = Assets.fontMontserrat12.toFont().clone();
        text = new h2d.Text(font);
        text.text = 'CONTROL SCHEME';
        text.x = AU.center(0, Globals.gameWidth, text.textWidth);
        text.y = 320;
        this.addChild(text);

        this.c1 = Assets.packedAssets['control1'].getBitmap();
        c1.y = text.y + text.textHeight + 5;
        c1.x = Globals.gameWidth / 2 - 120;
        c1.color.setColor(0xFF63ab3f);
        this.addChild(c1);
        var interactive = new h2d.Interactive(112, 64, this.c1);
        interactive.cursor = Default;
        interactive.onOver = function(e: hxd.Event) {
            c1.color.setColor(0xFF63ab3f);
        }
        interactive.onOut = function(e: hxd.Event) {
            if (this.control == 2) {
                c1.color.setColor(0xFFFFFFFF);
            }
        }
        interactive.onClick = function(e: hxd.Event) {
            this.control = 1;
            c1.color.setColor(0xFF63ab3f);
            c2.color.setColor(0xFFFFFFFF);
        }

        this.c2 = Assets.packedAssets['control2'].getBitmap();
        c2.y = c1.y;
        c2.x = Globals.gameWidth / 2 + 8;
        this.addChild(c2);
        var interactive = new h2d.Interactive(112, 64, this.c2);
        interactive.cursor = Default;
        interactive.onOver = function(e: hxd.Event) {
            c2.color.setColor(0xFF63ab3f);
        }
        interactive.onOut = function(e: hxd.Event) {
            if (this.control == 1) {
                c2.color.setColor(0xFFFFFFFF);
            }
        }
        interactive.onClick = function(e: hxd.Event) {
            this.control = 2;
            c1.color.setColor(0xFFFFFFFF);
            c2.color.setColor(0xFF63ab3f);
        }
    }

    override public function update(dt: Float) {}

    override public function render(engine: h3d.Engine) {}

    override public function onEvent(event: hxd.Event) {}

    override public function destroy() {}

    function startGame() {
        this.game.switchScreen(new BasicScreen(this.control));
    }
}
