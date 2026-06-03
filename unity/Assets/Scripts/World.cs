// =============================================================================
//  World.cs — Cœur de la simulation : arène, vagues de nuages colorés,
//  projectiles, combat, application des crafts, conditions de victoire
//  (détruire le buste ennemi). Contient aussi Cloud, Projectile et Fx.
// =============================================================================
using System.Collections.Generic;
using UnityEngine;

namespace DivineRivals {

public class TeamCfg {
    public int colorIndex; public Ctrl ctrl; public int viewport; public float aiLevel;
    public int initialBuddies = Config.StartBuddies; public bool canRespawn = true; public float templeHP;
}

public struct Obstacle { public Vector3 pos; public float r; }

public class World {
    public Transform root; public Sfx sfx; public Fx fx;
    public List<Team> teams = new List<Team>();
    public List<Buddy> buddies = new List<Buddy>();
    public List<Cloud> clouds = new List<Cloud>();
    public List<Projectile> shots = new List<Projectile>();
    public List<Obstacle> obstacles = new List<Obstacle>();
    public float time, waveTimer = Config.WaveInterval;
    public bool over; public string result; public Team winner;
    public System.Action<float> onShake;     // secousse caméra (impacts/explosions)
    public void Shake(float a) { onShake?.Invoke(a); }

    public World(Transform root, Sfx sfx) { this.root = root; this.sfx = sfx; fx = new Fx(root); }

    public void Init(List<TeamCfg> cfgs) {
        BuildArena();
        var spawns = SpawnLayout(cfgs.Count);
        for (int i = 0; i < cfgs.Count; i++) {
            var c = cfgs[i];
            var team = new Team(this, i, c.colorIndex, c.ctrl, spawns[i], c.viewport, c.aiLevel);
            team.canRespawn = c.canRespawn; team.templeHP = c.templeHP;
            teams.Add(team);
            obstacles.Add(new Obstacle { pos = spawns[i], r = Config.BustRadius });
            obstacles.Add(new Obstacle { pos = team.cauldron.pos, r = 2.2f });
            for (int k = 0; k < c.initialBuddies; k++) {
                var off = team.toCenter * 2f + new Vector3(Mathf.Cos(k * 2f), 0, Mathf.Sin(k * 2f)) * 1.4f;
                var b = SpawnBuddy(team, team.cauldron.pos - off, "fists");
                if (b != null && c.ctrl == Ctrl.Human && team.active == null) team.active = b;
            }
        }
    }

    List<Vector3> SpawnLayout(int n) {
        float h = Config.ArenaHalf - 9f;
        if (n <= 2) return new List<Vector3> { new Vector3(0, 0, -h), new Vector3(0, 0, h) };
        return new List<Vector3> { new Vector3(-h, 0, -h), new Vector3(h, 0, -h), new Vector3(-h, 0, h), new Vector3(h, 0, h) };
    }

    void BuildArena() {
        var ground = P.Prim(PrimitiveType.Plane, root, Vector3.zero, Vector3.one * (Config.ArenaHalf * 2f / 10f), P.Mat(new Color(0.42f, 0.65f, 0.42f)));
        ground.name = "Ground";
        var gt = P.Tex("ground");
        if (gt != null) {
            gt.wrapMode = TextureWrapMode.Repeat;
            var gm = ground.GetComponent<Renderer>().sharedMaterial;
            gm.mainTexture = gt;
            if (gm.HasProperty("_BaseMap")) gm.SetTexture("_BaseMap", gt);
            gm.color = Color.white; if (gm.HasProperty("_BaseColor")) gm.SetColor("_BaseColor", Color.white);
            gm.mainTextureScale = new Vector2(8, 8);
        }
        var wallM = P.Mat(new Color(0.55f, 0.5f, 0.42f));
        float h = Config.ArenaHalf, t = 1.2f;
        P.Prim(PrimitiveType.Cube, root, new Vector3(0, 1.1f, -h), new Vector3(h * 2, 2.2f, t), wallM);
        P.Prim(PrimitiveType.Cube, root, new Vector3(0, 1.1f, h), new Vector3(h * 2, 2.2f, t), wallM);
        P.Prim(PrimitiveType.Cube, root, new Vector3(-h, 1.1f, 0), new Vector3(t, 2.2f, h * 2), wallM);
        P.Prim(PrimitiveType.Cube, root, new Vector3(h, 1.1f, 0), new Vector3(t, 2.2f, h * 2), wallM);
        // Quelques décors-obstacles (colonnes).
        var rnd = new System.Random(12345);
        for (int i = 0; i < 8; i++) {
            float x = (float)(rnd.NextDouble() * 2 - 1) * (h - 8), z = (float)(rnd.NextDouble() * 2 - 1) * (h - 8);
            if (new Vector2(x, z).magnitude < 7f) continue;
            P.Prim(PrimitiveType.Cylinder, root, new Vector3(x, 1.6f, z), new Vector3(1.2f, 1.6f, 1.2f), P.Mat(new Color(0.9f, 0.88f, 0.8f)));
            obstacles.Add(new Obstacle { pos = new Vector3(x, 0, z), r = 0.9f });
        }
    }

    // --- Buddies --------------------------------------------------------------
    public Buddy SpawnBuddy(Team team, Vector3 pos, string weaponId) {
        if (team.Alive().Count >= Config.MaxBuddies) return null;
        var b = new Buddy(this, team, pos, weaponId);
        b.aimError = team.controller == Ctrl.AI ? (1f - team.aiLevel) * 0.22f : 0f;
        team.buddies.Add(b); buddies.Add(b);
        fx.Burst(pos + Vector3.up, team.accent, 12, 4);
        return b;
    }
    public void RemoveBuddy(Buddy b) {
        buddies.Remove(b); b.team.buddies.Remove(b);
        b.team.cauldron.FreeBuddy(b);
        if (b.team.active == b) b.team.PickNewActive();
        b.Destroy();
    }

    // --- Nuages ---------------------------------------------------------------
    public Cloud SpawnCloud(Vector3 at, int color = -1, float y = Config.CloudSpawnY) {
        if (clouds.Count >= Config.MaxClouds) { var old = clouds.Find(c => c.landed); if (old != null) { clouds.Remove(old); old.Destroy(); } }
        if (color < 0) color = RollColor();
        var c2 = new Cloud(this, new Vector3(at.x, y, at.z), color);
        clouds.Add(c2); return c2;
    }
    int RollColor() {
        float r = Random.value, acc = 0f;
        for (int i = 0; i < 4; i++) { acc += Config.CloudWeight[i]; if (r <= acc) return i; }
        return 0;
    }
    public Cloud NearestFreeCloud(Vector3 p) {
        Cloud best = null; float bd = float.MaxValue;
        foreach (var c in clouds) { if (!c.landed) continue; float d = (c.Pos - p).sqrMagnitude; if (d < bd) { bd = d; best = c; } }
        return best;
    }

    // --- Projectiles / combat -------------------------------------------------
    public void SpawnProjectile(Vector3 pos, Vector3 dir, WeaponDef w, Team team) {
        shots.Add(new Projectile(this, pos, dir, w, team));
    }
    public void MeleeAttack(Buddy a, WeaponDef w, Vector3 dir) {
        foreach (var b in buddies) {
            if (b.team == a.team || !b.alive) continue;
            Vector3 o = b.Pos - a.Pos; o.y = 0; float d = o.magnitude;
            if (d > w.range || d < 0.01f) continue;
            if (Vector3.Dot(o / d, dir) < 0.3f) continue;
            b.Damage(w.damage, a.team); b.Knockback(dir, b.vehicle != null ? 0.8f : 4f);
            fx.Burst(b.Pos + Vector3.up, w.color, 6, 4); Shake(0.1f);
        }
        foreach (var t in teams) {
            if (t == a.team || t.bust.destroyed) continue;
            if ((new Vector3(t.spawn.x, 0, t.spawn.z) - a.Pos).magnitude < w.range + Config.BustRadius) t.bust.Damage(w.damage, a.team);
        }
    }
    void TickProjectiles(float dt) {
        for (int i = shots.Count - 1; i >= 0; i--) {
            var p = shots[i]; p.life -= dt;
            p.pos += p.vel * dt; p.go.transform.position = p.pos;
            bool hit = false;
            foreach (var b in buddies) {
                if (b.team == p.team || !b.alive) continue;
                if ((b.Pos - p.pos).sqrMagnitude < 1.3f * 1.3f) { ApplyHit(p, b); hit = true; break; }
            }
            if (!hit) {
                foreach (var t in teams) {
                    if (t == p.team || t.bust.destroyed || !t.bust.risen) continue;
                    if ((new Vector3(t.spawn.x, 0, t.spawn.z) - new Vector3(p.pos.x, 0, p.pos.z)).magnitude < Config.BustRadius) {
                        t.bust.Damage(p.weapon.damage, p.team); fx.Burst(p.pos, p.weapon.color, 6, 3); hit = true; break;
                    }
                }
            }
            if (hit || p.life <= 0f || Mathf.Abs(p.pos.x) > Config.ArenaHalf || Mathf.Abs(p.pos.z) > Config.ArenaHalf) {
                p.Destroy(); shots.RemoveAt(i);
            }
        }
    }
    void ApplyHit(Projectile p, Buddy b) {
        b.Damage(p.weapon.damage, p.team);
        b.Knockback(p.vel, b.vehicle != null ? 1f : 5f);
        fx.Burst(p.pos, p.weapon.color, 6, 4); sfx.Hurt(); Shake(0.12f);
        if (p.weapon.aoe > 0f) {
            fx.Burst(p.pos, new Color(1f, 0.6f, 0.2f), 18, 6); Shake(0.4f);
            foreach (var o in buddies) if (o != b && o.team != p.team && o.alive && (o.Pos - p.pos).sqrMagnitude < p.weapon.aoe * p.weapon.aoe)
                o.Damage(p.weapon.damage * 0.6f, p.team);
        }
    }

    // --- Requêtes -------------------------------------------------------------
    public Buddy NearestEnemyBuddy(Team team, Vector3 pos) {
        Buddy best = null; float bd = float.MaxValue;
        foreach (var b in buddies) { if (b.team == team || !b.alive) continue; float d = (b.Pos - pos).sqrMagnitude; if (d < bd) { bd = d; best = b; } }
        return best;
    }
    public GodBust EnemyBustFor(Team team) { foreach (var t in teams) if (t != team && !t.bust.destroyed) return t.bust; return null; }

    // Ramasse le nuage au sol le plus proche (si à portée). Renvoie true si pris.
    public bool TryPickup(Buddy b) {
        if (!b.CanCarry()) return false;
        var c = NearestFreeCloud(b.Pos);
        if (c == null || (c.Pos - b.Pos).sqrMagnitude > Config.PickupReach * Config.PickupReach) return false;
        int col = c.color; clouds.Remove(c); c.Destroy(); b.PickupCloud(col); sfx.Pickup(); return true;
    }
    // Verse le nuage porté dans le chaudron de l'équipe (si à portée).
    public bool TryDeposit(Buddy b) {
        if (b.carryColor < 0) return false;
        var cau = b.team.cauldron;
        Vector3 a = new Vector3(b.Pos.x, 0, b.Pos.z), p = new Vector3(cau.pos.x, 0, cau.pos.z);
        if ((a - p).sqrMagnitude > Config.UseRadius * Config.UseRadius) return false;
        if (!cau.AddCloud(b.carryColor)) return false;
        b.DropCarryVisual(); return true;
    }

    // --- Craft : applique le résultat. Renvoie un libellé, ou null si échec. ---
    public string ApplyCraft(Team team, Recipe r) {
        if (r.kind == CraftKind.Teammate) {
            if (team.Alive().Count >= Config.MaxBuddies) return null;
            var def = Data.Teammates[r.resultId];
            var nb = SpawnBuddy(team, team.cauldron.pos - team.toCenter * 2.5f, def.weapon);
            if (nb == null) return null;
            nb.maxHp = def.hp; nb.hp = def.hp; nb.speed = def.speed;
            if (team.controller == Ctrl.Human && team.active == null) team.active = nb;
            return def.name;
        }
        var who = team.Leader(); if (who == null) { var f = team.Free(); who = f.Count > 0 ? f[0] : null; }
        if (who == null) return null;
        if (r.kind == CraftKind.Weapon) { who.SetWeapon(r.resultId); return Data.Weapon(r.resultId).name; }
        if (r.kind == CraftKind.Vehicle) { who.EnterVehicle(Data.Vehicles[r.resultId]); return Data.Vehicles[r.resultId].name; }
        return null;
    }

    // --- Tick ------------------------------------------------------------------
    public void Tick(float dt) {
        if (over) return;
        time += dt;
        waveTimer -= dt;
        if (waveTimer <= 0f) {
            waveTimer = Config.WaveInterval;
            for (int k = 0; k < Config.PerWave; k++)
                SpawnCloud(new Vector3(Random.Range(-1f, 1f) * (Config.ArenaHalf - 6f), 0, Random.Range(-1f, 1f) * (Config.ArenaHalf - 6f)));
            foreach (var t in teams)
                for (int k = 0; k < Config.NearCauldron; k++) {
                    float a = Random.value * 6.28f, rad = 1.5f + Random.value * 2f;
                    SpawnCloud(t.cauldron.pos + new Vector3(Mathf.Cos(a) * rad, 0, Mathf.Sin(a) * rad));
                }
        }
        foreach (var c in clouds) c.Tick(dt, time);
        foreach (var t in teams) {
            t.bust.Tick(dt, time);
            t.cauldron.Tick(time);
            if (t.ai != null) t.ai.Tick(dt);
            Respawn(t, dt);
        }
        // Buddies : humains non-actifs libres tiennent leur position et ripostent.
        foreach (var b in buddies) {
            if (!b.alive || b.working) { b.Tick(dt, time); continue; }
            bool humanActive = b.team.controller == Ctrl.Human && b == b.team.active;
            if (b.team.controller == Ctrl.Human && !humanActive) { b.joy = Vector2.zero; b.wantFire = true; }
            b.Tick(dt, time);
        }
        TickProjectiles(dt);
        CheckEnd();
    }

    void Respawn(Team t, float dt) {
        if (t.bust.destroyed || !t.canRespawn) return;
        if (t.Alive().Count > 0) { t.respawnTimer = 0f; return; }
        t.respawnTimer += dt;
        if (t.respawnTimer >= Config.RespawnDelay) {
            t.respawnTimer = 0f;
            var b = SpawnBuddy(t, t.spawn + t.toCenter * 3f, "fists");
            if (b != null && t.controller == Ctrl.Human) t.active = b;
        }
    }

    void CheckEnd() {
        var standing = teams.FindAll(t => !t.bust.destroyed);
        var human = teams.Find(t => t.controller == Ctrl.Human);
        if (human != null && human.bust.destroyed && teams.Count == 2) { over = true; result = "lose"; winner = teams.Find(t => t != human); return; }
        if (standing.Count <= 1 && teams.Count > 1) { over = true; winner = standing.Count == 1 ? standing[0] : null; result = (human != null && winner == human) ? "win" : (human != null ? "lose" : "over"); }
    }
}

// --- Nuage coloré -----------------------------------------------------------
public class Cloud {
    public GameObject go; Transform tr; public int color; public bool landed;
    public Vector3 Pos => tr.position;
    public Cloud(World w, Vector3 p, int color) {
        this.color = color; go = P.Group("Cloud", w.root); tr = go.transform; tr.position = p;
        var m = P.Mat(Config.CloudCol[color], true);
        P.Prim(PrimitiveType.Sphere, tr, Vector3.zero, Vector3.one * 1.4f, m);
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(0.6f, 0.1f, 0), Vector3.one * 1.0f, m);
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(-0.6f, 0.05f, 0.1f), Vector3.one * 1.0f, m);
        landed = p.y <= 0.9f;
    }
    public void Tick(float dt, float t) {
        var p = tr.position;
        if (!landed) { p.y -= Config.CloudFall * dt; if (p.y <= 0.8f) { p.y = 0.8f; landed = true; } }
        else p.y = 0.8f + Mathf.Sin(t * 2f + tr.position.x) * 0.08f;
        tr.position = p; tr.Rotate(0, dt * 30f, 0);
    }
    public void Destroy() { if (go) Object.Destroy(go); }
}

// --- Projectile -------------------------------------------------------------
public class Projectile {
    public GameObject go; public Vector3 pos, vel; public WeaponDef weapon; public Team team; public float life;
    public Projectile(World w, Vector3 p, Vector3 dir, WeaponDef wd, Team t) {
        pos = p; weapon = wd; team = t; vel = dir * wd.projSpeed;
        life = wd.range / Mathf.Max(1f, wd.projSpeed) + 0.1f;
        go = P.Prim(PrimitiveType.Sphere, w.root, p, Vector3.one * 0.35f, P.Mat(wd.color, true));
    }
    public void Destroy() { if (go) Object.Destroy(go); }
}

// --- Effets de particules (un seul ParticleSystem mutualisé) ----------------
public class Fx {
    ParticleSystem ps;
    public Fx(Transform root) {
        var g = P.Group("FX", root);
        ps = g.AddComponent<ParticleSystem>();
        var main = ps.main; main.loop = false; main.playOnAwake = false;
        main.startLifetime = 0.6f; main.startSpeed = 0f; main.gravityModifier = 0.5f;
        main.maxParticles = 2000; main.startSize = 0.5f;
        var em = ps.emission; em.enabled = false;
        var sh = ps.shape; sh.enabled = false;
        var r = ps.GetComponent<ParticleSystemRenderer>();
        var ptex = P.Tex("particle");
        if (ptex != null) { var pm = new Material(Shader.Find("Sprites/Default") ?? Shader.Find("Unlit/Transparent")); pm.mainTexture = ptex; r.material = pm; }
        else r.material = P.Mat(Color.white, true);
        ps.Play();
    }
    public void Burst(Vector3 pos, Color col, int count, float speed) {
        var ep = new ParticleSystem.EmitParams();
        for (int i = 0; i < count; i++) {
            Vector3 v = Random.onUnitSphere; v.y = Mathf.Abs(v.y) * 0.7f + 0.2f;
            ep.position = pos; ep.velocity = v * speed * (0.4f + Random.value);
            ep.startColor = col; ep.startSize = 0.4f + Random.value * 0.5f;
            ps.Emit(ep, 1);
        }
    }
}

}
