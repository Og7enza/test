// =============================================================================
//  Buddy.cs — Personnage. Déplacement (joystick / tap), combat à visée auto,
//  transport d'un nuage coloré, et ÉTAT "au travail" au chaudron (immobile,
//  ne combat pas, fait monter le Tier).
// =============================================================================
using UnityEngine;

namespace DivineRivals {

public enum Ctrl { Human, AI }

public interface IDamageable {
    Vector3 Pos { get; }
    bool Dead { get; }
    Team Team { get; }
    void Damage(float dmg, Team from);
}

public class Buddy : IDamageable {
    public World world; public Team team; public GameObject go; Transform tr;
    public float hp, maxHp = Config.BuddyHP, speed = Config.BuddySpeed;
    public bool alive = true;
    public float facing; Vector3 vel;
    public WeaponDef weapon; public string weaponId; float fireCD; public bool wantFire;
    public IDamageable target;
    public bool hasMove; public Vector3 move; public Vector2 joy;
    public int carryColor = -1; GameObject carryVis;
    public bool working; public int post = -1; public Vector3 workPos;
    public VehicleDef vehicle; public bool flying; public float aimError;
    public Team lastFrom;
    Transform bodyT; float bob, flash;
    Transform hpFill; Renderer hpFillRend;

    public Vector3 Pos => tr.position;
    public bool Dead => !alive;
    public Team Team => team;

    public Buddy(World w, Team t, Vector3 pos, string weaponId = "fists") {
        world = w; team = t; hp = maxHp;
        go = P.Group("Buddy", w.root); tr = go.transform; tr.position = pos;
        var body = P.Prim(PrimitiveType.Capsule, tr, new Vector3(0, 0.9f, 0), new Vector3(0.9f, 0.9f, 0.9f), P.Mat(t.primary));
        bodyT = body.transform;
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(0, 1.7f, 0), new Vector3(0.7f, 0.7f, 0.7f), P.Mat(new Color(0.96f, 0.8f, 0.6f)));
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(0, 1.92f, 0), new Vector3(0.8f, 0.5f, 0.8f), P.Mat(t.accent));            // casque
        P.Prim(PrimitiveType.Cylinder, tr, new Vector3(0, 0.04f, 0), new Vector3(1.5f, 0.02f, 1.5f), P.Mat(t.primary, true)); // anneau d'équipe
        var eyeM = P.Mat(new Color(0.1f, 0.1f, 0.15f));
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(-0.18f, 1.75f, 0.32f), Vector3.one * 0.16f, eyeM);
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(0.18f, 1.75f, 0.32f), Vector3.one * 0.16f, eyeM);
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 2.6f, 0), new Vector3(1.2f, 0.16f, 0.06f), P.Mat(new Color(0.08f, 0.08f, 0.1f)));           // barre de vie (fond)
        var fill = P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 2.6f, 0.05f), new Vector3(1.2f, 0.16f, 0.06f), P.Mat(new Color(0.3f, 0.9f, 0.4f), true));
        hpFill = fill.transform; hpFillRend = fill.GetComponent<Renderer>();
        SetWeapon(weaponId);
    }

    public void SetWeapon(string id) { weaponId = id; weapon = Data.Weapon(id); }

    public void EnterVehicle(VehicleDef v) {
        vehicle = v; maxHp = v.hp; hp = v.hp; speed = v.speed; flying = v.fly; SetWeapon(v.weapon);
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 1.3f, 0), new Vector3(2.2f, 1.0f, 2.6f), P.Mat(team.accent));
    }

    public bool CanCarry() => carryColor < 0 && !working && vehicle == null;
    public void PickupCloud(int color) {
        carryColor = color;
        carryVis = P.Prim(PrimitiveType.Sphere, world.root, Pos + Vector3.up * 2.5f, Vector3.one * 1.0f, P.Mat(Config.CloudCol[color], true));
    }
    public void DropCarryVisual() { if (carryVis) Object.Destroy(carryVis); carryVis = null; carryColor = -1; }

    public void SetMove(Vector3 p) { move = p; hasMove = true; joy = Vector2.zero; }

    public void Tick(float dt, float t) {
        if (!alive) return;
        if (fireCD > 0) fireCD -= dt;

        if (working) {                                  // touille le chaudron
            tr.position = Vector3.Lerp(tr.position, workPos, dt * 6f);
            bob += dt * 9f;
            bodyT.localPosition = new Vector3(0, 0.9f + Mathf.Abs(Mathf.Sin(bob)) * 0.12f, 0);
            tr.Rotate(0, dt * 60f, 0);
            UpdateBars(dt);
            return;
        }

        // 1) Direction désirée.
        Vector3 dir = Vector3.zero; bool moving = false;
        if (joy.sqrMagnitude > 0.04f) { dir = new Vector3(joy.x, 0, joy.y); moving = true; }
        else if (hasMove) {
            dir = move - tr.position; dir.y = 0; float d = dir.magnitude;
            if (d < 0.45f) hasMove = false; else { dir /= d; moving = true; }
        }
        // 2) Évitement simple des bustes/chaudrons.
        if (moving && !flying) {
            foreach (var o in world.obstacles) {
                Vector3 aw = tr.position - o.pos; aw.y = 0; float dist = aw.magnitude;
                float safe = o.r + Config.BuddyRadius + 1.2f;
                if (dist < safe && dist > 0.01f) dir += aw / dist * ((safe - dist) / safe) * 1.6f;
            }
            dir.y = 0; if (dir.sqrMagnitude > 0.001f) dir.Normalize();
        }
        // 3) Intégration.
        Vector3 desired = dir * speed;
        vel = Vector3.Lerp(vel, moving ? desired : Vector3.zero, dt * 8f);
        Vector3 p = tr.position + vel * dt;
        float lim = Config.ArenaHalf - 1.4f;
        p.x = Mathf.Clamp(p.x, -lim, lim); p.z = Mathf.Clamp(p.z, -lim, lim);
        p.y = Mathf.Lerp(p.y, flying ? 3.4f : 0f, dt * 4f);
        tr.position = p;
        // 4) Orientation.
        float spd = new Vector2(vel.x, vel.z).magnitude;
        if (spd > 0.3f && target == null) facing = Mathf.Atan2(vel.x, vel.z);
        tr.rotation = Quaternion.Slerp(tr.rotation, Quaternion.Euler(0, facing * Mathf.Rad2Deg, 0), dt * 12f);
        // 5) Combat (visée auto).
        AcquireTarget();
        if (wantFire && (weapon.melee || InRange())) Fire();
        // 6) Nuage porté.
        if (carryVis) carryVis.transform.position = tr.position + Vector3.up * 2.5f;
        UpdateBars(dt);
    }

    public void Knockback(Vector3 dir, float force) { dir.y = 0; if (dir.sqrMagnitude > 0.001f) { dir.Normalize(); vel += dir * force; } flash = 0.12f; }

    void UpdateBars(float dt) {
        if (flash > 0f) flash -= dt;
        float k = flash > 0f ? 1.16f : 1f;
        if (bodyT) { bodyT.localScale = Vector3.one * 0.9f * k; if (!working) bodyT.localPosition = new Vector3(0, 0.9f, 0); }
        float f = Mathf.Clamp01(hp / maxHp);
        if (hpFill) {
            hpFill.localScale = new Vector3(1.2f * f, 0.16f, 0.06f);
            hpFill.localPosition = new Vector3(-(1f - f) * 0.6f, 2.6f, 0.05f);
            if (hpFillRend) hpFillRend.sharedMaterial.color = f > 0.5f ? new Color(0.3f, 0.9f, 0.4f) : (f > 0.25f ? new Color(0.95f, 0.8f, 0.2f) : new Color(0.9f, 0.3f, 0.3f));
        }
    }

    bool InRange() {
        if (target == null) return weapon.range > 12f;
        return (target.Pos - Pos).sqrMagnitude <= (weapon.range + 1f) * (weapon.range + 1f);
    }

    void AcquireTarget() {
        float range = weapon.range > 6f ? Config.AimRange : weapon.range + 1f;
        IDamageable best = null; float bd = range * range;
        foreach (var b in world.buddies) {
            if (b.team == team || !b.alive) continue;
            float dd = (b.Pos - Pos).sqrMagnitude;
            if (dd < bd) { bd = dd; best = b; }
        }
        if (best == null) {
            var bust = world.EnemyBustFor(team);
            if (bust != null && (bust.Pos - Pos).sqrMagnitude < range * range * 4f) best = bust;
        }
        target = best;
    }

    void Fire() {
        if (fireCD > 0) return;
        var w = weapon;
        Vector3 d = new Vector3(Mathf.Sin(facing), 0, Mathf.Cos(facing));
        if (target != null && !target.Dead) {
            d = target.Pos - tr.position; d.y = 0; if (d.sqrMagnitude > 0.001f) d.Normalize();
            facing = Mathf.Atan2(d.x, d.z);
        }
        fireCD = 1f / w.fireRate;
        if (w.melee) { world.MeleeAttack(this, w, d); world.sfx.Shoot(); }
        else {
            float a = Mathf.Atan2(d.x, d.z) + (Random.value - 0.5f) * aimError;
            var dd = new Vector3(Mathf.Sin(a), 0, Mathf.Cos(a));
            world.SpawnProjectile(tr.position + Vector3.up * 1.3f + dd, dd, w, team);
            world.sfx.Shoot();
        }
    }

    public void Damage(float dmg, Team from) {
        if (!alive) return;
        hp -= dmg; flash = 0.12f; if (from != null) lastFrom = from;
        if (hp <= 0) Die();
    }

    void Die() {
        alive = false;
        world.fx.Burst(Pos + Vector3.up, vehicle != null ? team.accent : team.primary, vehicle != null ? 30 : 16, 7);
        world.sfx.Boom(); world.Shake(vehicle != null ? 0.6f : 0.3f);
        if (carryColor >= 0) world.SpawnCloud(Pos, carryColor, 1.2f);
        world.RemoveBuddy(this);
    }

    public void Destroy() { if (carryVis) Object.Destroy(carryVis); if (go) Object.Destroy(go); }
}

}
