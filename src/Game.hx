class Game extends common.Game {
    override function init() {
        super.init();
#if debug
        Globals.console = this.console;
#end
        this.s2d.scaleMode = Stretch(Globals.gameWidth, Globals.gameHeight);
        Globals.assets = common.Assets.parseAssets("assets.json");
        this.switchScreen(new examples.AnimationScene());
    }
}
