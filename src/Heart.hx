class Heart extends h2d.Object {
    var empty: h2d.Bitmap;
    var filled: h2d.Bitmap;

    public var active(default, set): Bool;

    public function set_active(b: Bool): Bool {
        this.active = b;
        this.empty.visible = !this.active;
        this.filled.visible = this.active;
        return this.active;
    }

    public function new() {
        super();
        this.addChild(this.empty = Assets.packedAssets["heart_empty"].getBitmap());
        this.addChild(this.filled = Assets.packedAssets["heart_filled"].getBitmap());
        this.empty.color.setColor(0xFFAAAAAA);
        this.empty.alpha = 0.25;
        this.filled.color.setColor(0xFFAAAAAA);
        this.filled.alpha = 0.25;
    }
}
