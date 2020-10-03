class Main {
    static function main() {
#if hl
        hxd.res.Resource.LIVE_UPDATE = true;
        hxd.Res.initLocal();
#else
        hxd.Res.initEmbed();
#end
        new Game();
    }
}
