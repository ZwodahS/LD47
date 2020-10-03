import hxd.Key;

import common.Point2f;
import common.animations.WrappedObject;
import common.animations.Shake;

class BasicScreen extends common.Screen {
    var player: Entity;
    var controlScheme: Int = 1;

    var enemies: List<Entity>;
    var bullets: List<Bullet>;

    public var animator: common.animations.Animator;

    public function new() {
        super();
        this.enemies = new List<Entity>();
        this.bullets = new List<Bullet>();

        var entity = new Entity(this, [Globals.gameWidth / 2, Globals.gameHeight / 2], 100);
        var bm = Assets.packedAssets['player'].getBitmap();
        bm.x = -16;
        bm.y = -16;
        entity.addChild(bm);
        this.player = entity;

        this.player.weapon = new Weapon(1, .1, .1, 200);
        this.animator = new common.animations.Animator();
    }

    override public function update(dt: Float) {
        this.animator.update(dt);
        movePlayerPosition(dt);
        checkFire(dt);
        var w = hxd.Window.getInstance();
        var pos: Point2f = [w.mouseX, w.mouseY];
        var diff = pos - [this.player.x, this.player.y];
        this.player.rotation = Math.atan2(diff.y, diff.x);
        for (b in this.bullets) b.update(dt);
        this.player.update(dt);
        for (e in this.enemies) e.update(dt);
    }

    override public function render(engine: h3d.Engine) {}

    override public function onEvent(event: hxd.Event) {}

    override public function destroy() {}

    function movePlayerPosition(dt: Float) {
        if (controlScheme == 1) {
            var aDown = Key.isDown(Key.A);
            var dDown = Key.isDown(Key.D);
            var wDown = Key.isDown(Key.W);
            var sDown = Key.isDown(Key.S);
            var targetPosition = this.player.position;
            if (aDown && dDown) {
                if (wDown && !sDown) {
                    targetPosition = 1.5;
                } else if (sDown && !wDown) {
                    targetPosition = .5;
                }
            } else if (wDown && sDown) {
                if (aDown && !dDown) {
                    targetPosition = 1.0;
                } else if (dDown && aDown) {
                    targetPosition = 0;
                }
            } else if (aDown && wDown) {
                targetPosition = 1.25;
            } else if (aDown && sDown) {
                targetPosition = .75;
            } else if (dDown && wDown) {
                targetPosition = 1.75;
            } else if (dDown && sDown) {
                targetPosition = .25;
            } else if (aDown) {
                targetPosition = 1.0;
            } else if (dDown) {
                targetPosition = 2;
            } else if (sDown) {
                targetPosition = .5;
            } else if (wDown) {
                targetPosition = 1.5;
            }
            this.player.moveTowards(targetPosition, .5 * dt);
        } else {
            var aDown = Key.isDown(Key.A);
            var dDown = Key.isDown(Key.D);
            if (aDown && !dDown) {
                this.player.position -= dt * .5;
            } else if (dDown && !aDown) {
                this.player.position += dt * .5;
            }
        }
    }

    function checkFire(dt: Float) {
        if (Key.isDown(Key.MOUSE_LEFT)) {
            var w = hxd.Window.getInstance();
            if (this.player.canFire) {
                fire(this.player, [w.mouseX, w.mouseY]);
                this.animator.runAnim(new Shake(new WrappedObject(this), 10, .1));
            }
        }
    }

    function fire(entity: Entity, position: Point2f) {
        if (entity.weapon == null) return;
        var startPosition: Point2f = [entity.x, entity.y];
        var bullet = new Bullet(entity.weapon.bulletSpeed);
        bullet.x = startPosition.x;
        bullet.y = startPosition.y;
        this.add(bullet, 10);
        bullet.moveTo(position);
        this.bullets.add(bullet);
    }
}
