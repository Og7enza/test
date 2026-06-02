// =============================================================================
//  Cauldron.cs — Le CHAUDRON de l'équipe (remplace le pad d'empilement).
//   • 3 postes : on y ASSIGNE des buddies -> ils "touillent" (immobiles) et
//     font monter le TIER (= nb de postes occupés, 0..3).
//   • Stocke jusqu'à 8 nuages COLORÉS [blanc, gris, or, noir].
//   • CRAFT : une recette est dispo si Tier >= recette.tier et si le stock paie
//     son coût en nuages colorés.
// =============================================================================
using System.Collections.Generic;
using UnityEngine;

namespace DivineRivals {

public class Cauldron {
    public World world; public Team team; public GameObject go; public Vector3 pos;
    public int[] stock = new int[4];                 // nuages stockés par couleur
    public Buddy[] postBuddy = new Buddy[Config.Posts];
    Transform flame, brew;
    class Stored { public int color; public GameObject vis; }
    List<Stored> stored = new List<Stored>();

    public int Tier { get { int n = 0; foreach (var b in postBuddy) if (b != null) n++; return n; } }
    public int Total { get { int s = 0; for (int i = 0; i < 4; i++) s += stock[i]; return s; } }
    public bool IsFull => Total >= Config.CauldronCap;

    public Cauldron(World w, Team t, Vector3 p) {
        world = w; team = t; pos = p;
        go = P.Group("Cauldron", w.root); go.transform.position = p;
        var stoneM = P.Mat(new Color(0.28f, 0.28f, 0.32f));
        P.Prim(PrimitiveType.Cylinder, go.transform, new Vector3(0, 0.9f, 0), new Vector3(3.0f, 0.9f, 3.0f), stoneM);   // marmite
        P.Prim(PrimitiveType.Cylinder, go.transform, new Vector3(0, 1.5f, 0), new Vector3(3.2f, 0.18f, 3.2f), P.Mat(new Color(0.18f, 0.18f, 0.2f))); // rebord
        brew = P.Prim(PrimitiveType.Cylinder, go.transform, new Vector3(0, 1.55f, 0), new Vector3(2.6f, 0.12f, 2.6f), P.Mat(team.accent, true)).transform; // bouillon
        flame = P.Prim(PrimitiveType.Sphere, go.transform, new Vector3(0, 0.2f, 0), new Vector3(0.1f, 0.1f, 0.1f), P.Mat(new Color(1f, 0.5f, 0.1f), true)).transform; // flammes (tier)
        // Marqueurs des 3 postes.
        for (int i = 0; i < Config.Posts; i++) {
            var wp = PostPos(i);
            P.Prim(PrimitiveType.Cylinder, go.transform, go.transform.InverseTransformPoint(wp) + Vector3.up * 0.05f, new Vector3(1.2f, 0.04f, 1.2f), P.Mat(team.primary));
        }
    }

    public Vector3 PostPos(int i) {
        float a = (i / (float)Config.Posts) * Mathf.PI * 2f + Mathf.PI / 2f;
        return pos + new Vector3(Mathf.Cos(a) * 2.6f, 0, Mathf.Sin(a) * 2.6f);
    }

    public int FirstFreePost() { for (int i = 0; i < Config.Posts; i++) if (postBuddy[i] == null) return i; return -1; }

    // --- Assignation -----------------------------------------------------------
    public bool Assign(Buddy b, int post) {
        if (b == null || !b.alive || b.working || post < 0 || post >= Config.Posts || postBuddy[post] != null) return false;
        postBuddy[post] = b; b.working = true; b.post = post; b.workPos = PostPos(post);
        if (team.active == b) team.PickNewActive();     // on lâche le contrôle de ce buddy
        return true;
    }
    public bool RemovePost(int post) {
        if (post < 0 || post >= Config.Posts || postBuddy[post] == null) return false;
        var b = postBuddy[post]; postBuddy[post] = null; b.working = false; b.post = -1;
        if (team.controller == Ctrl.Human && team.active == null) team.active = b;
        return true;
    }
    public void FreeBuddy(Buddy b) { for (int i = 0; i < Config.Posts; i++) if (postBuddy[i] == b) { postBuddy[i] = null; b.working = false; b.post = -1; } }

    // --- Nuages ----------------------------------------------------------------
    public bool AddCloud(int color) {
        if (IsFull || color < 0 || color > 3) return false;
        stock[color]++;
        int n = stored.Count;
        var vis = P.Prim(PrimitiveType.Sphere, go.transform, new Vector3((n % 2) * 0.8f - 0.4f, 1.8f + (n / 2) * 0.7f, ((n / 2) % 2) * 0.8f - 0.4f), Vector3.one * 0.7f, P.Mat(Config.CloudCol[color], true));
        stored.Add(new Stored { color = color, vis = vis });
        return true;
    }

    void Consume(int[] cost) {
        for (int c = 0; c < 4; c++) {
            int need = cost[c];
            for (int k = stored.Count - 1; k >= 0 && need > 0; k--) {
                if (stored[k].color == c) { Object.Destroy(stored[k].vis); stored.RemoveAt(k); need--; }
            }
            stock[c] -= cost[c];
            if (stock[c] < 0) stock[c] = 0;
        }
    }

    // --- Craft -----------------------------------------------------------------
    public CraftRes Craft(Recipe r) {
        if (Tier < r.tier) return CraftRes.Fail("Tier " + r.tier + " requis (assigne des buddies)");
        if (!Data.CanAfford(r, stock)) return CraftRes.Fail("Pas assez de nuages");
        // Pré-vérifs : on ne consomme pas les nuages si le résultat ne peut aboutir.
        if (r.kind == CraftKind.Teammate && team.Alive().Count >= Config.MaxBuddies) return CraftRes.Fail("Équipe pleine (4 max)");
        if (r.kind != CraftKind.Teammate && team.Leader() == null && team.Free().Count == 0) return CraftRes.Fail("Aucun buddy libre à équiper");
        Consume(r.cost);
        string label = world.ApplyCraft(team, r);
        world.fx.Burst(pos + Vector3.up * 2f, team.accent, 28, 5);
        world.sfx.Craft();
        return label == null ? CraftRes.Fail("Équipe pleine (4 max)") : CraftRes.Ok(label);
    }

    public void Tick(float t) {
        if (brew) brew.localScale = new Vector3(2.6f, 0.12f + Mathf.Sin(t * 3f) * 0.04f, 2.6f);
        float s = 0.15f + Tier * 0.55f + Mathf.Sin(t * 10f) * 0.1f * Tier;   // flammes ∝ Tier
        if (flame) flame.localScale = new Vector3(s, s * 1.6f, s);
    }
}

public struct CraftRes {
    public bool ok; public string msg;
    public static CraftRes Ok(string m) => new CraftRes { ok = true, msg = m };
    public static CraftRes Fail(string m) => new CraftRes { ok = false, msg = m };
}

}
