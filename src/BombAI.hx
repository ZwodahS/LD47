class BombAI extends EnemyAI {
    var delay: Float = 0;

    public function new(world: BasicScreen) {
        super(world);
        this.delay = 5;
    }

    var shootDelay: Float = 0;

    override public function update(dt: Float, entity: Entity) {
        entity.position += dt * .2;
        // entity.face([this.world.player.x, this.world.player.y]);
        this.delay -= dt;
        if (delay > 0) return;
        if (shootDelay <= 0) {
            shootDelay += .2;
            this.world.fire(entity, [this.world.player.x, this.world.player.y]);
        } else {
            shootDelay -= dt;
        }
    }
}
