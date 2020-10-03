class Weapon {
    public var currentAmmo: Int;
    public var maxAmmo: Int;
    public var reloadTime: Float;
    public var shootDelay: Float;
    public var bulletSpeed: Float = 150;

    public function new(ammoCount: Int, reloadTime: Float, shootDelay: Float, bulletSpeed: Float) {
        this.currentAmmo = ammoCount;
        this.maxAmmo = ammoCount;
        this.reloadTime = reloadTime;
        this.shootDelay = shootDelay;
        this.bulletSpeed = bulletSpeed;
    }

    public function fire(): Bool {
        if (this.currentAmmo == 0) return false;
        if (this.delay > 0) return false;
        this.currentAmmo -= 1;
        this.delay = this.shootDelay;
        if (this.currentAmmo <= 0) reload();
        return true;
    }

    public var delay: Float = 0;
    public var reloading: Float = 0;

    public function update(dt: Float) {
        if (this.delay > 0) this.delay -= dt;
        if (this.reloading > 0) {
            this.reloading -= dt;
            if (this.reloading < 0) {
                this.reloading = 0;
                this.currentAmmo = this.maxAmmo;
            }
        }
    }

    public function reload() {
        this.reloading = this.reloadTime;
    }
}
