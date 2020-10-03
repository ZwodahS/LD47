class Game extends common.Game {
    override function init() {
        super.init();
#if debug
        Globals.console = this.console;
#end
        this.s2d.scaleMode = Stretch(Globals.gameWidth, Globals.gameHeight);

        var p = common.Assets.loadAseSpritesheetConfig("packed.json");
        Assets.packedAssets = p.assets;
        Assets.packedTile = p.tile;

        this.switchScreen(new BasicScreen());
    }
}
