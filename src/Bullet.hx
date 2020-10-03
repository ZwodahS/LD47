import common.Point2f;

class Bullet extends h2d.Object {
    var targetPosition: Point2f;
    var moveSpeed: Float = 100;

    var moveVec: Point2f;

    public function new(moveSpeed: Float) {
        super();
        var bm = Assets.packedAssets['bullet'].getBitmap();
        bm.color.setColor(0xFF00FF00);
        bm.x = -16;
        bm.y = -16;
        this.addChild(bm);
        this.moveSpeed = moveSpeed;
    }

    public function update(dt: Float) {
        if (this.moveVec == null) return;
        var m = this.moveVec * this.moveSpeed * dt;
        this.x += m.x;
        this.y += m.y;
    }

    public function moveTo(position: Point2f) {
        this.targetPosition = position;
        this.moveVec = (this.targetPosition - [this.x, this.y]).get_unit();
    }
}
