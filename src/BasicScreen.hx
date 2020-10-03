import hxd.Key;

import common.ds.List;
import common.MathUtils as MU;
import common.AlignmentUtils as AU;
import common.HtmlUtils as HU;
import common.Point2f;
import common.animations.*;
import common.ui.TileButton;
import common.ProbabilityTable;

class BasicScreen extends common.Screen {
    static var ButtonWidth: Int = 0;

    public var player: Entity;
    public var state = "ready";

    var controlScheme: Int = 1;

    var enemies: List<Entity>;
    var bullets: List<Bullet>;

    public var animator: common.animations.Animator;

    var retryButton: TileButton;
    var playerRect: common.Rectf;

    var enemyLeft: Int = 0;
    var spawnDelay: Float = 0;
    var spawnElapsed: Float = 0;
    var currentRound(default, set): Int = 0;

    function set_currentRound(i: Int): Int {
        this.currentRound = i;
        this.roundLabel.text = 'ROUND ${this.currentRound}';
        this.roundLabel.x = AU.center(0, Globals.gameWidth, this.roundLabel.textWidth);
        this.roundLabel.y = Globals.gameHeight / 2 - 40;
        return this.currentRound;
    }

    var kills(default, set): Int = 0;

    function set_kills(i: Int): Int {
        this.kills = i;
        this.killLabel.text = '${this.kills}';
        this.killLabel.x = AU.center(0, Globals.gameWidth, this.killLabel.textWidth);
        this.killLabel.y = Globals.gameHeight / 2 - 90;
        return this.kills;
    }

    var enemyTable: ProbabilityTable<String>;

    var hearts: Array<Heart>;
    var roundLabel: h2d.Text;
    var scoreLabel: h2d.Text;
    var killLabel: h2d.Text;

    public function new() {
        super();
        var t = Assets.packedAssets['button_default'].getTile();
        ButtonWidth = Std.int(t.width);
        this.playerRect = [
            Globals.gameWidth / 2 - 200, Globals.gameHeight / 2 - 200,
            Globals.gameWidth / 2 + 200, Globals.gameHeight / 2 + 200
        ];

        this.addChild(this.roundLabel = new h2d.Text(Assets.buttonFont));
        this.roundLabel.textColor = 0xAAAAAA;
        this.roundLabel.alpha = 0.25;

        var font = Assets.fontMontserrat32.toFont().clone();
        this.addChild(this.killLabel = new h2d.Text(font));
        this.killLabel.textColor = 0xAAAAAA;
        this.killLabel.alpha = 0.25;

        this.enemies = new List<Entity>();
        this.bullets = new List<Bullet>();

        this.animator = new common.animations.Animator();
        this.state = "preparing";

        this.scoreLabel = new h2d.Text(font);
        this.scoreLabel.y = 150;
        this.addChild(this.scoreLabel);
        this.scoreLabel.textColor = 0xFFFFFF;
        this.scoreLabel.visible = false;
        this.retryButton = makeButton("Retry");
        this.retryButton.onClick = function() {
            startNewGame();
        }
        this.retryButton.visible = false;
        this.retryButton.x = AU.center(0, Globals.gameWidth, ButtonWidth);
        this.retryButton.y = 400;

        this.enemyTable = new ProbabilityTable<String>();
        this.enemyTable.add(120, "cannon");
        this.enemyTable.add(60, "minishooter");
        this.enemyTable.add(60, "machinegun");

        this.hearts = [];
        for (i in 0...5) {
            var h = new Heart();
            this.hearts.push(h);
            h.x = ((Globals.gameWidth - 32) / 2) - (32 * 2) + (i * 32);
            h.y = (Globals.gameHeight - 32) / 2;
            this.addChild(h);
        }
    }

    function setPlayerHealth(h: Int) {
        for (i in 0...h) {
            this.hearts[i].active = true;
        }
        for (i in h...5) {
            this.hearts[i].active = false;
        }
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
        this.addChild(b);
        return b;
    }

    function addEnemyFadeIn(e: Entity, position: Point2f) {
        e.alpha = 0;
        this.enemies.add(e);
        this.animator.runAnim(new AlphaTo(new WrappedObject(e), 1.0, 1.0), function() {
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
        spawnEnemy(dt);

        testCollision();
        cleanup();
        if (this.enemyLeft == 0 && this.enemies.length == 0 && this.player != null) {
            startRound(this.currentRound + 1);
        }
    }

    function spawnEnemy(dt: Float) {
        if (this.enemyLeft <= 0) return;
        this.spawnElapsed += dt;
        if (this.spawnElapsed > spawnDelay) {
            this.spawnElapsed -= spawnDelay;
            addRandomEnemy();
            this.enemyLeft -= 1;
        }
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
                this.kills += 1;
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
        this.player.delete();
        this.player = null;
        gameOver();
    }

    function gameOver() {
        this.state = "gameover";
        this.retryButton.visible = true;
        this.scoreLabel.visible = true;
        this.scoreLabel.text = 'Score: ${this.kills}';
        this.scoreLabel.x = AU.center(0, Globals.gameWidth, this.scoreLabel.textWidth);
    }

    function damage(e: Entity) {
        if (e.invincibleDelay > 0) return;
        e.hp -= 1;
        if (e.hp <= 0) return;
        if (e == this.player) {
            e.invincibleDelay = 2.0;
            this.animator.runAnim(new Blink(new WrappedObject(e), 2, .1));
            this.animator.runAnim(new Shake(new WrappedObject(this), 10, .5));
            this.setPlayerHealth(e.hp);
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
        for (e in this.enemies) e.delete();
        this.enemies = new List<Entity>();
        this.retryButton.visible = false;
        this.startRound(1);
        this.kills = 0;

        this.state = "ready";
    }

    function startRound(round: Int) {
        this.enemyLeft = 5 + round;
        this.spawnDelay = MU.clampF(2.1 - (.1 * round), 0.5, null);
        this.spawnElapsed = 0;
        var font = Assets.fontMontserrat32.toFont();
        var text = new h2d.Text(font);
        text.text = 'ROUND ${round}';
        text.x = AU.center(0, Globals.gameWidth, text.textWidth);
        text.y = 180;
        this.addChild(text);
        this.animator.runAnim(new AlphaTo(new WrappedObject(text), 0, 1.0 / 1.5), function() {
            text.remove();
        });
        this.currentRound = round;
    }

    function makePlayer() {
        var entity = new Entity(this, [Globals.gameWidth / 2, Globals.gameHeight / 2], 100);
        var bm = Assets.packedAssets['player'].getBitmap();
        bm.x = -16;
        bm.y = -16;
        entity.addChild(bm);
        entity.size = 20;
        entity.side = 0;
        entity.weapon = new Weapon(1, .1, .1, 300);
        entity.hp = 5;
        return entity;
    }

    function addRandomEnemy() {
        var e = new Entity(this, [0, 0], 30);
        var enemyType = this.enemyTable.roll();
        var bm = Assets.packedAssets['enemy_${enemyType}'].getBitmap();
        bm.color.setColor(0xFF000000 | Constants.EnemyColor);
        bm.x = -16;
        bm.y = -16;
        e.addChild(bm);
        e.side = 1;

        e.isActive = false;
        if (enemyType == "minishooter") {
            e.weapon = new Weapon(2, 1, .1, 300);
            e.size = 16;
            e.ai = new EnemyAI(this);
        } else if (enemyType == "machinegun") {
            e.weapon = new Weapon(20, 5, .1, 300);
            e.weapon.currentAmmo = 0;
            e.weapon.reload();
            e.size = 24;
            e.ai = new EnemyAI(this);
        } else { // default to cannon
            e.weapon = new Weapon(1, 1, .1, 100);
            e.size = 24;
            e.ai = new EnemyAI(this);
        }
        var targetPosition = randomEnemyPosition();
        e.center = targetPosition;
        if (Random.int(0, 0) == 0) {
            addEnemyFadeIn(e, targetPosition);
        }

        return e;
    }

    function randomEnemyPosition(): Point2f {
        var position: Point2f = [Random.int(50,
            Globals.gameWidth - 50), Random.int(50, Globals.gameHeight - 50)];
        while (this.playerRect.contains(position)) {
            if (Random.int(0, 2) == 0) {
                position.x = Random.int(50, Globals.gameWidth - 50);
            } else {
                position.y = Random.int(50, Globals.gameHeight - 50);
            }
        }
        return position;
    }

    override public function beginScreenEnter() {
        startNewGame();
    }
}
