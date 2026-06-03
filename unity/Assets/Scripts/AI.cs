// =============================================================================
//  AI.cs — Directeur d'équipe IA : un collecteur alimente le chaudron, l'IA
//  assigne des buddies aux postes (monte le Tier), fabrique des recettes
//  abordables, et les combattants attaquent l'ennemi / le buste adverse.
// =============================================================================
using UnityEngine;

namespace DivineRivals {

public class AI {
    Team team; World world; float think; Buddy gatherer;

    public AI(Team t, World w) { team = t; world = w; think = Random.value * 0.6f; }

    public void Tick(float dt) {
        think -= dt;
        if (think <= 0f) { think = 0.6f; Decide(); }
        Drive(dt);
    }

    Buddy FirstFree() { foreach (var b in team.Alive()) if (!b.working) return b; return null; }

    void Decide() {
        var alive = team.Alive();
        if (alive.Count == 0) return;
        if (gatherer == null || !gatherer.alive || gatherer.working) gatherer = FirstFree();

        // Monter le Tier si on a des buddies en rab (sans tomber sous 1 combattant).
        int free = team.Free().Count;
        if ((free >= 3 && team.Tier < 1) || (free >= 4 && team.Tier < 2)) {
            var b = FirstFree();
            int post = team.cauldron.FirstFreePost();
            if (b != null && b != gatherer && post >= 0) team.cauldron.Assign(b, post);
        }
        TryCraft();
    }

    void TryCraft() {
        Recipe best = null;
        foreach (var r in Data.Recipes) {
            if (r.tier > team.Tier || !Data.CanAfford(r, team.cauldron.stock)) continue;
            // Tant qu'on a moins de 3 buddies, on privilégie un coéquipier.
            if (team.Alive().Count < 3 && r.kind == CraftKind.Teammate) { best = r; break; }
            if (best == null || r.tier > best.tier) best = r;
        }
        if (best != null) team.cauldron.Craft(best);
    }

    // Meilleure cible : proche ET blessée en priorité (focus-fire pour achever).
    Buddy BestTarget(Buddy b) {
        Buddy best = null; float bestScore = -1f; const float range = Config.AimRange;
        foreach (var o in world.buddies) {
            if (o.team == team || !o.alive) continue;
            float d = (o.Pos - b.Pos).magnitude;
            if (d > range) continue;
            float score = (1f - d / range) + (1f - o.hp / o.maxHp) * 0.8f;
            if (score > bestScore) { bestScore = score; best = o; }
        }
        return best;
    }

    void Drive(float dt) {
        Vector3 home = new Vector3(team.spawn.x, 0, team.spawn.z);
        var threat = world.NearestEnemyBuddy(team, home);
        bool baseThreatened = threat != null && (threat.Pos - home).sqrMagnitude < 16f * 16f;
        foreach (var b in team.Alive()) {
            if (b.working) continue;
            if (b == gatherer) {                              // collecteur : remplit le chaudron
                if (b.carryColor < 0) {
                    var c = world.NearestFreeCloud(b.Pos);
                    if (c != null) { b.SetMove(c.Pos); if ((c.Pos - b.Pos).sqrMagnitude < Config.PickupReach * Config.PickupReach) world.TryPickup(b); }
                    else b.SetMove(team.cauldron.pos);
                } else {
                    b.SetMove(team.cauldron.pos);
                    if ((team.cauldron.pos - b.Pos).sqrMagnitude < Config.UseRadius * Config.UseRadius) world.TryDeposit(b);
                }
                var ng = world.NearestEnemyBuddy(team, b.Pos);
                b.wantFire = ng != null && (ng.Pos - b.Pos).sqrMagnitude < 49f;   // se défend si menacé
            } else {                                          // combattant
                IDamageable tgt = baseThreatened ? (IDamageable)threat : ((IDamageable)BestTarget(b) ?? world.EnemyBustFor(team));
                if (tgt != null) {
                    Vector3 tp = tgt.Pos; Vector3 dir = b.Pos - tp; dir.y = 0; float d = dir.magnitude;
                    float stand = Mathf.Max(2.2f, b.weapon.range * (0.55f + (1f - team.aiLevel) * 0.25f));
                    b.SetMove(tp + (d > 0.01f ? dir / d : Vector3.forward) * stand);
                }
                b.wantFire = true;
            }
        }
    }
}

}
