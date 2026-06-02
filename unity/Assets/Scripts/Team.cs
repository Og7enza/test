// =============================================================================
//  Team.cs — Équipe (couleur, dieu, buddies, chaudron) + GodBust (la base =
//  buste du dieu qui émerge du sol, gros PV, riposte, s'effondre à 0 PV).
// =============================================================================
using System.Collections.Generic;
using UnityEngine;

namespace DivineRivals {

public class Team {
    public World world; public int index, colorIndex; public Ctrl controller; public int viewport;
    public float aiLevel; public Vector3 spawn, toCenter;
    public Color primary, accent; public string teamName, godName;
    public List<Buddy> buddies = new List<Buddy>();
    public Buddy active;
    public Cauldron cauldron; public GodBust bust;
    public bool canRespawn = true; public float respawnTimer;
    public AI ai;
    public int score;
    public float templeHP;        // PV de la base (0 => valeur par défaut Config.BustHP)

    public int Tier => cauldron != null ? cauldron.Tier : 0;

    public Team(World w, int index, int colorIndex, Ctrl ctrl, Vector3 spawn, int viewport, float aiLevel) {
        world = w; this.index = index; this.colorIndex = colorIndex; controller = ctrl;
        this.viewport = viewport; this.aiLevel = aiLevel; this.spawn = spawn;
        primary = Config.TeamPrimary[colorIndex % 4]; accent = Config.TeamAccent[colorIndex % 4];
        teamName = Config.TeamName[colorIndex % 4]; godName = Config.GodName[colorIndex % 4];
        float d = new Vector2(spawn.x, spawn.z).magnitude; toCenter = d > 0.01f ? new Vector3(-spawn.x / d, 0, -spawn.z / d) : Vector3.forward;
        bust = new GodBust(w, this);
        cauldron = new Cauldron(w, this, spawn + toCenter * 6.5f);
        if (ctrl == Ctrl.AI) ai = new AI(this, w);
    }

    public List<Buddy> Alive() { var l = new List<Buddy>(); foreach (var b in buddies) if (b.alive) l.Add(b); return l; }
    public List<Buddy> Free() { var l = new List<Buddy>(); foreach (var b in buddies) if (b.alive && !b.working) l.Add(b); return l; }
    public Buddy Leader() { if (active != null && active.alive && !active.working) return active; var f = Free(); return f.Count > 0 ? f[0] : null; }
    public void PickNewActive() { var f = Free(); active = f.Count > 0 ? f[0] : null; }
}

// --- Le buste du dieu (base) ------------------------------------------------
public class GodBust : IDamageable {
    public World world; public Team team; public GameObject go; Transform tr, core;
    public float hp, maxHp; public bool destroyed; public float riseT; public bool risen;
    float defTimer; WeaponDef defWeapon; Transform hpFill;

    public Vector3 Pos => new Vector3(team.spawn.x, 4f, team.spawn.z);
    public bool Dead => destroyed;
    public Team Team => team;

    public GodBust(World w, Team t) {
        world = w; team = t; maxHp = t.templeHP > 0 ? t.templeHP : Config.BustHP; hp = maxHp;
        defWeapon = new WeaponDef("godbolt", "Foudre", Config.DefDamage, 1f, Config.DefRange + 5f, 44f, false, t.accent, 1.8f);
        go = P.Group("GodBust", w.root);
        go.transform.position = new Vector3(t.spawn.x, -Config.RiseDepth, t.spawn.z);
        go.transform.rotation = Quaternion.LookRotation(new Vector3(-t.spawn.x, 0, -t.spawn.z).normalized + Vector3.forward * 0.001f, Vector3.up);
        tr = go.transform;
        Build(t.colorIndex);
    }

    void Build(int gi) {
        var stone = P.Mat(new Color(0.9f, 0.88f, 0.8f)); var stone2 = P.Mat(new Color(0.8f, 0.78f, 0.7f));
        var robe = P.Mat(team.primary); var gold = P.Mat(team.accent);
        var skin = P.Mat(gi == 2 ? new Color(0.12f, 0.14f, 0.2f) : (gi == 3 ? new Color(0.82f, 0.6f, 0.18f) : new Color(0.94f, 0.85f, 0.7f)));
        var dark = P.Mat(new Color(0.15f, 0.15f, 0.2f));
        // Piédestal (base à y=0).
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 0.5f, 0), new Vector3(6, 1, 6), stone);
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 1.3f, 0), new Vector3(5, 0.7f, 5), stone2);
        P.Prim(PrimitiveType.Cylinder, tr, new Vector3(0, 1.95f, 0), new Vector3(3.4f, 0.6f, 3.4f), stone);
        // Torse + pectoral.
        P.Prim(PrimitiveType.Cylinder, tr, new Vector3(0, 3.4f, 0), new Vector3(2.4f, 1.3f, 2.4f), robe);
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 2.7f, 1.0f), new Vector3(2.4f, 0.5f, 0.4f), gold);
        // Tête.
        P.Prim(PrimitiveType.Capsule, tr, new Vector3(0, 4.7f, 0), new Vector3(0.7f, 0.5f, 0.7f), skin);
        P.Prim(PrimitiveType.Sphere, tr, new Vector3(0, 5.6f, 0), new Vector3(2.1f, 2.1f, 2.1f), skin);
        // Variation par dieu.
        if (gi == 0 || gi == 1) { // Zeus / Hadès : barbe + couronne
            P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 4.9f, 0.55f), new Vector3(1.2f, 1.0f, 0.5f), P.Mat(gi == 0 ? new Color(0.95f, 0.95f, 0.95f) : new Color(0.18f, 0.15f, 0.25f)));
            if (gi == 0) P.Prim(PrimitiveType.Cylinder, tr, new Vector3(0, 6.5f, 0), new Vector3(2.0f, 0.12f, 2.0f), gold);
            else for (int i = 0; i < 6; i++) { float a = i / 6f * Mathf.PI * 2; P.Prim(PrimitiveType.Cube, tr, new Vector3(Mathf.Cos(a) * 0.9f, 6.6f, Mathf.Sin(a) * 0.9f), new Vector3(0.16f, 0.7f, 0.16f), dark); }
        } else if (gi == 2) { // Anubis : oreilles
            for (int s = -1; s <= 1; s += 2) P.Prim(PrimitiveType.Capsule, tr, new Vector3(s * 0.6f, 6.8f, 0), new Vector3(0.35f, 0.7f, 0.35f), skin);
            P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 5.5f, 0.9f), new Vector3(0.7f, 0.5f, 0.9f), skin); // museau
        } else { // Râ : bec + disque solaire
            P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 5.5f, 1.0f), new Vector3(0.35f, 0.35f, 0.7f), gold);
            P.Prim(PrimitiveType.Sphere, tr, new Vector3(0, 6.4f, -0.4f), new Vector3(2.4f, 2.4f, 0.3f), gold);
        }
        // Cœur divin (point faible / témoin de PV).
        core = P.Prim(PrimitiveType.Sphere, tr, new Vector3(0, 3.0f, 1.3f), Vector3.one * 0.9f, P.Mat(team.accent, true)).transform;
        // Grande barre de PV (c'est l'objectif).
        P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 8.4f, 0), new Vector3(5f, 0.4f, 0.1f), P.Mat(new Color(0.08f, 0.08f, 0.1f)));
        hpFill = P.Prim(PrimitiveType.Cube, tr, new Vector3(0, 8.4f, 0.06f), new Vector3(5f, 0.4f, 0.1f), P.Mat(new Color(0.95f, 0.3f, 0.3f), true)).transform;
    }

    public void Tick(float dt, float t) {
        if (!destroyed) {
            if (hpFill) { float f = Mathf.Clamp01(hp / maxHp); hpFill.localScale = new Vector3(5f * f, 0.4f, 0.1f); hpFill.localPosition = new Vector3(-(1f - f) * 2.5f, 8.4f, 0.06f); }
            if (!risen) {
                riseT = Mathf.Min(1f, riseT + dt / Config.RiseTime);
                float e = 1f - Mathf.Pow(1f - riseT, 3f);
                tr.position = new Vector3(team.spawn.x, -Config.RiseDepth * (1f - e), team.spawn.z);
                if (Random.value < 0.6f) world.fx.Burst(team.spawn + new Vector3(Random.Range(-3f, 3f), 0.3f, Random.Range(-3f, 3f)), new Color(0.6f, 0.5f, 0.4f), 4, 3);
                if (riseT >= 1f) risen = true;
            }
            if (core) { core.Rotate(0, dt * 80f, 0); core.localPosition = new Vector3(0, 3.0f + Mathf.Sin(t * 2f) * 0.1f, 1.3f); }
            if (risen) { defTimer -= dt; if (defTimer <= 0f) { defTimer = Config.DefCooldown; Defend(); } }
        } else {
            tr.position += Vector3.down * dt * 3.2f;
            tr.Rotate(0, 0, dt * 28f);
        }
    }

    void Defend() {
        Buddy best = null; float bd = Config.DefRange * Config.DefRange;
        foreach (var b in world.buddies) {
            if (b.team == team || !b.alive) continue;
            float dd = (b.Pos - new Vector3(team.spawn.x, 0, team.spawn.z)).sqrMagnitude;
            if (dd < bd) { bd = dd; best = b; }
        }
        if (best == null) return;
        Vector3 from = new Vector3(team.spawn.x, 5f, team.spawn.z);
        Vector3 d = best.Pos - from; d.y = 0; if (d.sqrMagnitude > 0.001f) d.Normalize();
        world.SpawnProjectile(from, d, defWeapon, team);
        world.fx.Burst(from, team.accent, 8, 4);
        world.sfx.Shoot();
    }

    public void Damage(float dmg, Team from) {
        if (destroyed || !risen) return;
        hp -= dmg;
        if (hp <= 0f) {
            destroyed = true;
            if (core) core.gameObject.SetActive(false);
            if (hpFill) hpFill.gameObject.SetActive(false);
            world.fx.Burst(new Vector3(team.spawn.x, 4f, team.spawn.z), team.accent, 80, 9);
            world.sfx.Boom(); world.Shake(1.2f);
        }
    }
}

}
