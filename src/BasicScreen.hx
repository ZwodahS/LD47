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
    var quitButton: TileButton;
    var playerRect: common.Rectf;

    var enemyLeft: Int = 0;
    var spawnDelay: Float = 0;
    var spawnElapsed: Float = 0;
    var currentRound(default, set): Int = 0;

    function set_currentRound(i: Int): Int {
        this.currentRound = i;
        this.roundLabel.text = 'ROUND ${this.currentRound}';
        this.roundLabel.textColor = 0xFFFFFF;
        if (this.currentRound >= 10) {
            this.roundLabel.text = 'HELL';
            this.roundLabel.textColor = Constants.EnemyColor;
        }
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
    var bulletIcons: Array<h2d.Bitmap>;
    var roundLabel: h2d.Text;
    var scoreLabel: h2d.Text;
    var reloadingLabel: h2d.Text;
    var killLabel: h2d.Text;

    var hellmode: Bool = false;

    public function new(control: Int = 1, hellmode: Bool = false) {
        super();
        this.controlScheme = control;
        this.hellmode = hellmode;
        var t = Assets.packedAssets['button_default'].getTile();
        ButtonWidth = Std.int(t.width);
        this.playerRect = [
            Globals.gameWidth / 2 - 200, Globals.gameHeight / 2 - 200,
            Globals.gameWidth / 2 + 200, Globals.gameHeight / 2 + 200
        ];

        this.addChild(this.roundLabel = new h2d.Text(Assets.buttonFont));
        this.roundLabel.textColor = 0xAAAAAA;
        this.roundLabel.alpha = 0.4;

        var font = Assets.fontMontserrat32.toFont().clone();
        this.addChild(this.killLabel = new h2d.Text(font));
        this.killLabel.textColor = 0xAAAAAA;
        this.killLabel.alpha = 0.4;

        this.addChild(this.reloadingLabel = new h2d.Text(Assets.fontMontserrat12.toFont().clone()));
        this.reloadingLabel.textColor = 0xAAAAAA;
        this.reloadingLabel.alpha = 0.4;
        this.reloadingLabel.text = 'RELOADING';
        this.reloadingLabel.x = AU.center(0, Globals.gameWidth, this.reloadingLabel.textWidth);
        this.reloadingLabel.y = Globals.gameHeight / 2 + 15;

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
        this.retryButton.x = AU.center(0, Globals.gameWidth, ButtonWidth) - (ButtonWidth - 20);
        this.retryButton.y = 400;

        this.quitButton = makeButton("Quit");
        this.quitButton.onClick = function() {
            backToMenu();
        }
        this.quitButton.visible = false;
        this.quitButton.x = AU.center(0, Globals.gameWidth, ButtonWidth) + (ButtonWidth - 20);
        this.quitButton.y = 400;

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

        this.bulletIcons = [];
        var totalWidth = 30 * 4 + 29 * 2;
        var startX = AU.center(0, Globals.gameWidth, totalWidth);
        for (i in 0...30) {
            var b = Assets.packedAssets['bullet_icon'].getBitmap();
            b.x = startX + (i * 6);
            b.y = Globals.gameHeight / 2 + 20;
            b.color.setColor(0xFFAAAAAA);
            b.alpha = .4;
            this.addChild(b);
            this.bulletIcons.push(b);
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

    override public function update(dt: Float) {
        this.animator.update(dt);
        movePlayerPosition(dt);
        checkFire(dt);
        if (this.player != null) this.player.update(dt);
        for (b in this.bullets) b.update(dt);
        for (e in this.enemies) e.update(dt);
        updateBulletUI();
        spawnEnemy(dt);

        testCollision();
        cleanup();
        if (this.enemyLeft == 0 && this.enemies.length == 0 && this.player != null) {
            startRound(this.currentRound + 1);
        }
    }

    function updateBulletUI() {
        if (this.player == null) return;
        var ammoAmount = this.player.weapon.currentAmmo;
        if (this.player.weapon.reloading > 0) {
            ammoAmount = 0;
            this.reloadingLabel.visible = true;
        } else {
            this.reloadingLabel.visible = false;
        }
        for (i in 0...ammoAmount) {
            this.bulletIcons[i].visible = true;
        }
        for (i in ammoAmount...this.bulletIcons.length) {
            this.bulletIcons[i].visible = false;
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
            if (b.x < -300 || b.y < -300 || b.x > Globals.gameWidth + 300 || b.y > Globals.gameHeight + 300) {
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
        this.quitButton.visible = true;
        this.scoreLabel.visible = true;
        this.scoreLabel.text = 'Score: ${this.kills}';
        this.scoreLabel.x = AU.center(0, Globals.gameWidth, this.scoreLabel.textWidth);
    }

    function damage(e: Entity) {
        if (e.invincibleDelay > 0) return;
        e.hp -= 1;
        if (e == this.player) {
            this.setPlayerHealth(e.hp);
            if (e.hp != 0 && Assets.damagedSound != null) Assets.damagedSound.play(.25);
        }
        if (e.hp <= 0) return;
        if (e == this.player) {
            e.invincibleDelay = 2.0;
            this.animator.runAnim(new Blink(new WrappedObject(e), 2, .1));
            this.animator.runAnim(new Shake(new WrappedObject(this), 10, .5));
        } else {}
    }

    function explode(e: Entity) {
        for (i in 0...2) {
            var t = Assets.packedAssets['tile'].getBitmap();
            t.x = e.x - 16;
            t.y = e.y - 16;
            t.color.setColor(0xFF000000 | Constants.EnemyColor);
            var e = new Explode(t, 32, 6, 128);
            this.add(t, 10);
            this.animator.run(e);
        }
        if (Assets.explosionSound != null) Assets.explosionSound.play(.25);
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
            var wDown = Key.isDown(Key.W);
            var sDown = Key.isDown(Key.S);
            if ((aDown && !dDown) || (wDown && !sDown)) {
                this.player.position -= dt * .5;
            } else if ((dDown && !aDown) || (sDown && !wDown)) {
                this.player.position += dt * .5;
            }
        }
        var s2d = this.game.s2d;
        var pos = [s2d.mouseX, s2d.mouseY];
        this.player.face(pos);
    }

    function checkFire(dt: Float) {
        if (this.state != "ready") return;
        if (Key.isDown(Key.MOUSE_LEFT) || Key.isDown(Key.SPACE)) {
            var s2d = this.game.s2d;
            var pos: Point2f = [s2d.mouseX, s2d.mouseY];
            if (this.player.canFire) {
                fire(this.player, pos);
            }
        }
    }

    public function fire(entity: Entity, position: Point2f) {
        if (entity.weapon == null) return;
        if (entity == this.player) {
            if (Assets.shootSound != null) Assets.shootSound.play(.25);
        }
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
        this.quitButton.visible = false;
        this.scoreLabel.visible = false;
        if (this.hellmode) {
            this.startRound(10);
        } else {
            this.startRound(1);
        }
        this.kills = 0;
        this.setPlayerHealth(5);

        this.state = "ready";
    }

    function startRound(round: Int) {
        this.currentRound = round;
        if (this.currentRound < 5) {
            this.enemyLeft = 5;
        } else if (this.currentRound < 10) {
            this.enemyLeft = 10;
        } else if (this.currentRound >= 10) {
            this.enemyLeft = 10000;
        }
        this.spawnDelay = MU.clampF(2.6 - (.1 * round), 0.5, null);
        this.spawnElapsed = 0;
        var font = Assets.fontMontserrat32.toFont();
        var text = new h2d.Text(font);
        text.text = 'ROUND ${round}';
        if (this.currentRound >= 10) {
            text.text = 'HELL MODE';
        }
        text.x = AU.center(0, Globals.gameWidth, text.textWidth);
        text.y = 180;
        this.addChild(text);
        this.animator.runAnim(new AlphaTo(new WrappedObject(text), 0, 1.0 / 1.5), function() {
            text.remove();
        });
    }

    function makePlayer() {
        var entity = new Entity(this, [Globals.gameWidth / 2, Globals.gameHeight / 2], 100);
        var bm = Assets.packedAssets['player'].getBitmap();
        bm.x = -16;
        bm.y = -16;
        entity.addChild(bm);
        entity.size = 20;
        entity.side = 0;
        entity.weapon = new Weapon(30, 1, .1, 300);
        entity.hp = 5;
        return entity;
    }

    function addRandomEnemy() {
        var radius = 30;
        if (this.currentRound <= 3) {
            radius = 30;
        } else {
            radius = Random.int(20, 30 + this.currentRound * 10);
        }
        var e = new Entity(this, [0, 0], radius);
        var enemyType = this.enemyTable.roll();
        if (this.currentRound == 1) {
            enemyType = 'cannon';
        } else if (this.currentRound == 2) {
            if (this.enemyLeft == 2) {
                enemyType = 'machinegun';
            } else if (this.enemyLeft == 3) {
                enemyType = 'minishooter';
            } else {
                enemyType = 'cannon';
            }
        }

        var bm = Assets.packedAssets['enemy_${enemyType}'].getBitmap();
        bm.color.setColor(0xFF000000 | Constants.EnemyColor);
        bm.x = -16;
        bm.y = -16;
        e.addChild(bm);
        e.side = 1;

        e.isActive = false;
        if (enemyType == "minishooter") {
            e.weapon = new Weapon(2, 1, .1, 300);
            e.size = 20;
            e.ai = new EnemyAI(this, e);
        } else if (enemyType == "machinegun") {
            e.weapon = new Weapon(20, 5, .1, 300);
            e.weapon.currentAmmo = 0;
            e.weapon.reload();
            e.size = 28;
            e.ai = new EnemyAI(this, e);
        } else { // default to cannon
            e.weapon = new Weapon(1, 1, .1, 100);
            e.size = 28;
            e.ai = new EnemyAI(this, e);
        }
        var targetPosition = randomEnemyPosition();
        e.center = targetPosition;
        var r = Random.int(0, 1);
        if (r == 0 || this.currentRound <= 4) { // don't move in until after 4
            addEnemyFadeIn(e, targetPosition);
        } else {
            addEnemyMoveIn(e, targetPosition);
        }

        return e;
    }

    function addEnemyFadeIn(e: Entity, position: Point2f) {
        e.alpha = 0;
        this.enemies.add(e);
        this.animator.runAnim(new AlphaTo(new WrappedObject(e), 1.0, 1.0), function() {
            e.isActive = true;
        });
    }

    function addEnemyMoveIn(e: Entity, position: Point2f) {
        if (Random.int(0, 1) == 0) {
            if (position.x < Globals.gameWidth / 2) {
                e.center = [-e.radius / 2, position.y];
            } else {
                e.center = [Globals.gameWidth + e.radius / 2, position.y];
            }
        } else {
            if (position.y < Globals.gameHeight / 2) {
                e.center = [position.x, -e.radius / 2];
            } else {
                e.center = [position.x, Globals.gameHeight + e.radius / 2];
            }
        }
        this.enemies.add(e);
        e.isActive = true;
        this.animator.runAnim(new MoveToLocationByDuration(e.ai, position, 6));
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

    function backToMenu() {
        this.game.switchScreen(new MenuScreen());
    }
}
