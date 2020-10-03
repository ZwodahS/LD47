class EnemyAI {
    var world: BasicScreen;

    public function new(world: BasicScreen) {
        this.world = world;
    }

    public function update(dt: Float, entity: Entity) {
        entity.position += dt * .2;
        entity.face([this.world.player.x, this.world.player.y]);
        if (entity.canFire) {
            this.world.fire(entity, [this.world.player.x, this.world.player.y]);
        }
    }
}
