import common.MathUtils as MU;
import common.Point2f;

class Entity extends h2d.Object {
    var center: Point2f;
    var radius: Float;

    var circle: h2d.Graphics;

    public var ai: EnemyAI;

    public var position(default, set): Float; // between 0 and 2 PI (without the PI)

    public var canFire(get, never): Bool;
    public var hp: Int = 1;

    public function get_canFire(): Bool {
        if (this.weapon == null) return false;
        return (this.weapon.fire());
    }

    public var weapon: Weapon;

    public var size: Float;
    public var side: Int;
    public var isActive: Bool;

    public function new(parent: h2d.Object, center: Point2f, radius: Float) {
        super(parent);
        this.center = center;
        this.radius = radius;
        this.position = 0;
        this.circle = new h2d.Graphics(parent);
        updateCircle();
    }

    public function set_position(f: Float): Float {
        if (f < 0 || f > 2) f = f % 2.0;
        if (f < 0) f += 2;
        this.position = f;
        var p: Point2f = [
            (Math.cos(f * Math.PI) * this.radius) + center.x,
            (Math.sin(f * Math.PI) * this.radius) + center.y,
        ];
        this.x = p.x;
        this.y = p.y;
        return this.position;
    }

    public function moveTowards(p: Float, speed: Float) {
        if (this.position == p) return;
        // "normalise" the target position so that my current position is at "0"
        var normalised = p - this.position;

        // figure out the direction of the moving (clockwise or anti) based on the normalise pt
        var direction = 0;
        if (normalised < 0) {
            // if the normalise value is less than 0 (to the left side of the number line
            // we find the corresponding value on the right side
            // This equation is technically (0 - normalised < normalised + 2 - 0)
            // the - 0 is the current position
            if (0 - normalised < normalised + 2) {
                direction = -1;
            } else {
                direction = 1;
            }
        } else {
            // for normalised value more than 0, we need to find the value on the left side
            // this equation is technically (2 - normalised < normalised - 0)
            if (2 - normalised < normalised) {
                direction = -1;
            } else {
                direction = 1;
            }
        }
        // clamp the move amount to the normalised value, technically if you "abs" it, it is actually just the
        // distance from current position
        var moveAmount = MU.clampF(speed, 0, Math.abs(normalised));
        this.position += direction * moveAmount;
    }

    function updateCircle() {
        if (this.circle == null) return;
        this.circle.clear();
        this.circle.beginFill(0x000000, 0);
        this.circle.lineStyle(2, 0xAAAAAA, 0.25);
        this.circle.drawCircle(this.center.x, this.center.y, this.radius);
        this.circle.endFill();
    }

    public function update(dt: Float) {
        if (this.weapon != null) this.weapon.update(dt);
        if (this.ai != null) this.ai.update(dt, this);
    }

    public function delete() {
        this.circle.remove();
        this.remove();
    }

    public function face(position: Point2f) {
        var diff = position - [this.x, this.y];
        this.rotation = Math.atan2(diff.y, diff.x);
    }
}
