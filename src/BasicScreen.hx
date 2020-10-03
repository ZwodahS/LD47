import hxd.Key;

import common.ds.List;
import common.MathUtils as MU;
import common.AlignmentUtils as AU;
import common.HtmlUtils as HU;
import common.Point2f;
import common.animations.*;
import common.ui.TileButton;

class BasicScreen extends common.Screen {
    static var ButtonWidth: Int = 0;

    public var player: Entity;
    public var state = "ready";

    var controlScheme: Int = 1;

    var enemies: List<Entity>;
    var bullets: List<Bullet>;

    public var animator: common.animations.Animator;

    var retryButton: TileButton;

    public function new() {
        super();
        var t = Assets.packedAssets['button_default'].getTile();
        ButtonWidth = Std.int(t.width);

        this.enemies = new List<Entity>();
        this.bullets = new List<Bullet>();

        this.animator = new common.animations.Animator();
        this.state = "preparing";

        this.retryButton = makeButton("Retry");
        this.retryButton.onClick = function() {
            startNewGame();
        }
        this.retryButton.visible = false;
    }

    function makeButton(label: String): TileButton {
        var b = new TileButton(Assets.packedAssets['button_default'].getTile(),
            Assets.packedAssets['button_hover'].getTile(), Assets.packedAssets['button_default'].getTile(),
            Assets.packedAssets['button_default'].getTile());
        b.font = Assets.buttonFont;
        b.text = HU.font(label, 0xFFFFFF);
        b.onOver = function() {
            b.text = HU.font(label, 0x63ab3f);
        }
        b.onOut = function() {
            b.text = HU.font(label, 0xFFFFFF);
        }
        b.x = AU.center(0, Globals.gameWidth, ButtonWidth);
        b.y = 200;
        this.addChild(b);
        return b;
    }

    function addEnemy(position: Point2f) {
        var e = new Entity(this, position, 30);
        var bm = Assets.packedAssets['enemy'].getBitmap();
        bm.color.setColor(0xFF000000 | Constants.EnemyColor);
        bm.x = -16;
        bm.y = -16;
        e.addChild(bm);
        e.size = 16;
        e.side = 1;
        e.isActive = false;
        e.ai = new EnemyAI(this);
        e.weapon = new Weapon(5, .5, .1, 300);
        e.alpha = 0;
        this.enemies.add(e);
        this.animator.runAnim(new AlphaTo(new WrappedObject(e), 1.0, 1.0 / 2), function() {
            e.isActive = true;
        });
    }

    override public function update(dt: Float) {
        this.animator.update(dt);
        movePlayerPosition(dt);
        checkFire(dt);
        if (this.player != null) this.player.update(dt);
        for (b in this.bullets) b.update(dt);
        for (e in this.enemies) e.update(dt);

        testCollision();
        cleanup();
    }

    override public function render(engine: h3d.Engine) {}

    override public function onEvent(event: hxd.Event) {}

    override public function destroy() {}

    function testCollision() {
        for (b in this.bullets) {
            if (b.side == 0) {
                for (e in this.enemies) {
                    var distance = MU.distance(b.x, b.y, e.x, e.y);
                    if (distance < e.size / 2) {
                        b.collide = true;
                        damage(e);
                    }
                }
            } else if (b.side == 1) {
                if (this.player == null) continue;
                var e = this.player;
                var distance = MU.distance(b.x, b.y, e.x, e.y);
                if (distance < e.size / 2) {
                    b.collide = true;
                    damage(e);
                }
            }
        }
    }

    function cleanup() {
        if (this.state != "ready") return;
        if (this.player.hp == 0) {
            playerDead();
        }
        for (e in this.enemies) {
            if (e.hp <= 0) {
                e.delete();
                explode(e);
            }
        }
        for (b in this.bullets) {
            if (b.x < 0 || b.y < 0 || b.x > Globals.gameWidth || b.y > Globals.gameHeight) {
                b.collide = true;
            }
            if (b.collide) b.remove();
        }
        this.enemies.inFilter(function(e: Entity) {
            return e.hp > 0;
        });
        this.bullets.inFilter(function(b: Bullet) {
            return !b.collide;
        });
    }

    function playerDead() {
        explode(this.player);
        this.player.remove();
        this.player = null;
        gameOver();
    }

    function gameOver() {
        this.state = "gameover";
        this.retryButton.visible = true;
    }

    function damage(e: Entity) {
        if (e.invincibleDelay > 0) return;
        e.hp -= 1;
        if (e.hp <= 0) return;
        if (e == this.player) {
            e.invincibleDelay = 2.0;
            this.animator.runAnim(new Blink(new WrappedObject(e), 2, .1));
        } else {}
    }

    function explode(e: Entity) {
        for (i in 0...4) {
            var t = Assets.packedAssets['tile'].getBitmap();
            t.x = e.x - 16;
            t.y = e.y - 16;
            t.color.setColor(0xFF000000 | Constants.EnemyColor);
            var e = new Explode(t, 32, 1.5, 128);
            this.add(t, 10);
            this.animator.run(e);
        }
    }

    function movePlayerPosition(dt: Float) {
        if (this.state != "ready") return;
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
        this.player.face(pos);
    }

    function checkFire(dt: Float) {
        if (this.state != "ready") return;
        if (Key.isDown(Key.MOUSE_LEFT)) {
            var w = hxd.Window.getInstance();
            if (this.player.canFire) {
                fire(this.player, [w.mouseX, w.mouseY]);
            }
        }
    }

    public function fire(entity: Entity, position: Point2f) {
        if (entity.weapon == null) return;
        var startPosition: Point2f = [entity.x, entity.y];
        var bullet = new Bullet(entity.weapon.bulletSpeed, entity == this.player ? 0 : 1);
        bullet.x = startPosition.x;
        bullet.y = startPosition.y;
        this.add(bullet, 10);
        bullet.moveTo(position);
        this.bullets.add(bullet);
    }

    function startNewGame() {
        if (this.player == null) {
            this.player = makePlayer();
        }
        for (b in this.bullets) b.remove();
        this.bullets = new List<Bullet>();
        for (e in this.enemies) e.remove();
        this.enemies = new List<Entity>();
        this.retryButton.visible = false;

        this.state = "ready";
        this.addEnemy([100, 100]);
    }

    function makePlayer() {
        var entity = new Entity(this, [Globals.gameWidth / 2, Globals.gameHeight / 2], 100);
        var bm = Assets.packedAssets['player'].getBitmap();
        bm.x = -16;
        bm.y = -16;
        entity.addChild(bm);
        entity.size = 16;
        entity.side = 0;
        entity.weapon = new Weapon(1, .1, .1, 300);
        entity.hp = 5;
        return entity;
    }

    override public function beginScreenEnter() {
        startNewGame();
    }
}
