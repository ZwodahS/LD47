class EnemyAI implements common.animations.Positionable {
    var world: BasicScreen;

    var direction: Int;

    public var x(get, set): Float;

    public function get_x(): Float {
        return this.entity.center.x;
    }

    public function set_x(x: Float): Float {
        this.entity.center = [x, this.entity.center.y];
        return this.entity.center.x;
    }

    public var y(get, set): Float;

    public function get_y(): Float {
        return this.entity.center.y;
    }

    public function set_y(y: Float): Float {
        this.entity.center = [this.entity.center.x, y];
        return this.entity.center.y;
    }

    var entity: Entity;

    public function new(world: BasicScreen, entity: Entity) {
        this.world = world;
        this.direction = Random.int(0, 1) == 0 ? -1 : 1;
        this.entity = entity;
    }

    public function update(dt: Float) {
        if (!this.entity.isActive) return;
        if (this.world.state != "ready") return;
        this.entity.position += this.direction * dt * .2;
        this.entity.face([this.world.player.x, this.world.player.y]);
        if (this.entity.canFire) {
            this.world.fire(this.entity, [this.world.player.x, this.world.player.y]);
        }
    }
}
