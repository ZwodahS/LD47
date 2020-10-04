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

        Assets.fontMontserrat32 = hxd.Res.load('montserrat_regular_32.fnt').to(hxd.res.BitmapFont);
        Assets.buttonFont = Assets.fontMontserrat32.toFont().clone();
        Assets.buttonFont.resizeTo(16);

        Assets.fontMontserrat12 = hxd.Res.load('montserrat_regular_12.fnt').to(hxd.res.BitmapFont);

        Assets.explosionSound = hxd.Res.explosion1;
        Assets.shootSound = hxd.Res.shoot1;
        Assets.damagedSound = hxd.Res.damaged;

        this.switchScreen(new MenuScreen());
    }
}
