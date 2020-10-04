class EnemyAI {
    var world: BasicScreen;

    var direction: Int;

    public function new(world: BasicScreen) {
        this.world = world;
        this.direction = Random.int(0, 1) == 0 ? -1 : 1;
    }

    public function update(dt: Float, entity: Entity) {
        if (!entity.isActive) return;
        if (this.world.state != "ready") return;
        entity.position += this.direction * dt * .2;
        entity.face([this.world.player.x, this.world.player.y]);
        if (entity.canFire) {
            this.world.fire(entity, [this.world.player.x, this.world.player.y]);
        }
    }
}
