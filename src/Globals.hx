/**
    Globals is used to store all the global variables in the game.
    This is usually for stuffs that are loaded on start, or configured on start.

    Ideally, these should "NEVER" be changed after they are loaded.
    Global variable are evil, but sometimes necessary.

    For Constants, see Constants.hx
    For functions, see Utils.hx
**/
class Globals {
    public static var console: h2d.Console;
    public static var assets: common.Assets;

    public static var gameWidth: Int = 800;
    public static var gameHeight: Int = 600;
}
