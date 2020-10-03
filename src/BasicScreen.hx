import hxd.Key;

import common.Point2f;

class BasicScreen extends common.Screen {
    var player: Entity;
    var controlScheme: Int = 1;

    public function new() {
        super();

        var entity = new Entity(this, [Globals.gameWidth / 2, Globals.gameHeight / 2], 100);
        var bm = Assets.packedAssets['player'].getBitmap();
        bm.x = -16;
        bm.y = -16;
        entity.addChild(bm);
        this.player = entity;
    }

    override public function update(dt: Float) {
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

        var w = hxd.Window.getInstance();
        var pos: Point2f = [w.mouseX, w.mouseY];
        var diff = pos - [this.player.x, this.player.y];
        this.player.rotation = Math.atan2(diff.y, diff.x);
    }

    override public function render(engine: h3d.Engine) {}

    override public function onEvent(event: hxd.Event) {}

    override public function destroy() {}
}
