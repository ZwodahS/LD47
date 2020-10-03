class Factory {
    static var _instance: Factory;

    public static function init() {
        Factory._instance = new Factory();
    }

    function new() {}

    public static function get() {
        return _instance;
    }
}
