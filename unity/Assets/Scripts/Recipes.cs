// =============================================================================
//  Recipes.cs — Armes / véhicules / coéquipiers + recettes du CHAUDRON.
//  Une recette = un COÛT en nuages colorés [blanc, gris, or, noir] + un TIER
//  minimum (nombre de buddies assignés au chaudron). Noms mythologiques.
//
//  (Optimisation assumée vs cahier des charges : le craft dépend de la COULEUR
//  des nuages et du TIER — plus lisible/mobile que l'agencement 2x2x2, et tout
//  aussi riche. On pourra réintroduire des motifs positionnels plus tard.)
// =============================================================================
using System.Collections.Generic;
using UnityEngine;

namespace DivineRivals {

public enum CraftKind { Weapon, Vehicle, Teammate }

public class WeaponDef {
    public string id, name;
    public float damage, fireRate, range, projSpeed, aoe;
    public bool melee;
    public Color color;
    public WeaponDef(string id, string name, float dmg, float fr, float range, float ps, bool melee, Color col, float aoe = 0f) {
        this.id = id; this.name = name; damage = dmg; fireRate = fr; this.range = range;
        projSpeed = ps; this.melee = melee; color = col; this.aoe = aoe;
    }
}

public class VehicleDef {
    public string id, name, weapon; public float hp, speed; public bool fly;
    public VehicleDef(string id, string name, float hp, float speed, bool fly, string weapon) {
        this.id = id; this.name = name; this.hp = hp; this.speed = speed; this.fly = fly; this.weapon = weapon;
    }
}

public class TeammateDef {
    public string id, name, weapon; public float hp, speed;
    public TeammateDef(string id, string name, float hp, float speed, string weapon) {
        this.id = id; this.name = name; this.hp = hp; this.speed = speed; this.weapon = weapon;
    }
}

public class Recipe {
    public string id, name, resultId;
    public CraftKind kind;
    public int tier;
    public int[] cost;       // [blanc, gris, or, noir]
    public Recipe(string id, string name, int tier, CraftKind kind, string result, int[] cost) {
        this.id = id; this.name = name; this.tier = tier; this.kind = kind; resultId = result; this.cost = cost;
    }
    public int Total { get { int s = 0; foreach (var c in cost) s += c; return s; } }
}

public static class Data {
    static Color C(float r, float g, float b) => new Color(r, g, b);

    public static readonly Dictionary<string, WeaponDef> Weapons = new Dictionary<string, WeaponDef> {
        { "fists",         new WeaponDef("fists", "Poings", 8, 1.6f, 2.2f, 0, true, Color.white) },
        { "bow",           new WeaponDef("bow", "Arc d'Apollon", 16, 2.0f, 18, 32, false, C(1f,0.88f,0.5f)) },
        { "dagger",        new WeaponDef("dagger", "Dagues d'Hermès", 14, 4.0f, 3.2f, 0, true, C(0.8f,0.85f,1f)) },
        { "lance",         new WeaponDef("lance", "Lance de Bronze", 30, 1.2f, 4.0f, 0, true, C(0.82f,0.9f,1f)) },
        { "bolt",          new WeaponDef("bolt", "Éclair Mineur", 26, 2.4f, 20, 40, false, C(0.4f,0.88f,1f)) },
        { "heavyMG",       new WeaponDef("heavyMG", "Baliste d'Héphaïstos", 11, 11f, 22, 52, false, C(1f,0.95f,0.6f)) },
        { "longbow",       new WeaponDef("longbow", "Arc Long d'Artémis", 40, 1.1f, 34, 60, false, C(1f,0.82f,0.38f)) },
        { "divineThunder", new WeaponDef("divineThunder", "Foudre Divine", 34, 2.0f, 24, 46, false, C(0.6f,0.9f,1f), 2.2f) },
        { "harpyLauncher", new WeaponDef("harpyLauncher", "Lance-Harpies", 22, 1.4f, 26, 30, false, C(0.9f,0.78f,1f)) },
        { "electricBow",   new WeaponDef("electricBow", "Œil de Râ", 30, 3.2f, 28, 64, false, C(0.48f,0.94f,1f)) },
        { "anubisFlail",   new WeaponDef("anubisFlail", "Fléau d'Anubis", 55, 1.6f, 5.0f, 0, true, C(0.6f,0.85f,0.6f)) },
        { "wrathOfZeus",   new WeaponDef("wrathOfZeus", "Colère de Zeus", 70, 1.0f, 30, 50, false, C(1f,1f,1f), 4.0f) },
    };

    public static readonly Dictionary<string, VehicleDef> Vehicles = new Dictionary<string, VehicleDef> {
        { "pegasus",     new VehicleDef("pegasus", "Pégase", 90, 13f, true, "bolt") },
        { "warChariot",  new VehicleDef("warChariot", "Char d'Arès", 220, 8f, false, "heavyMG") },
        { "royalEagle",  new VehicleDef("royalEagle", "Aigle de Zeus", 120, 11f, true, "heavyMG") },
        { "giantTurtle", new VehicleDef("giantTurtle", "Tortue d'Atlas", 360, 4.5f, false, "divineThunder") },
    };

    public static readonly Dictionary<string, TeammateDef> Teammates = new Dictionary<string, TeammateDef> {
        { "archer",      new TeammateDef("archer", "Recrue d'Olympe", 90, 7.4f, "bow") },
        { "spearman",    new TeammateDef("spearman", "Hoplite", 120, 6.8f, "lance") },
        { "thunderling", new TeammateDef("thunderling", "Mage de Thot", 110, 7.0f, "divineThunder") },
        { "champion",    new TeammateDef("champion", "Champion d'Hadès", 160, 7.2f, "divineThunder") },
    };

    // [blanc, gris, or, noir]
    public static readonly List<Recipe> Recipes = new List<Recipe> {
        // --- TIER 0 : armes de base + nouveau buddy -----------------------------
        new Recipe("r_bow",     "Arc d'Apollon",      0, CraftKind.Weapon,   "bow",           new[]{2,0,0,0}),
        new Recipe("r_dagger",  "Dagues d'Hermès",    0, CraftKind.Weapon,   "dagger",        new[]{3,0,0,0}),
        new Recipe("r_lance",   "Lance de Bronze",    0, CraftKind.Weapon,   "lance",         new[]{2,1,0,0}),
        new Recipe("r_recruit", "Recrue d'Olympe",    0, CraftKind.Teammate, "archer",        new[]{4,0,0,0}),
        // --- TIER 1 : armes intermédiaires + 1er véhicule -----------------------
        new Recipe("r_bolt",    "Éclair Mineur",      1, CraftKind.Weapon,   "bolt",          new[]{2,2,0,0}),
        new Recipe("r_mg",      "Baliste d'Héphaïstos",1,CraftKind.Weapon,   "heavyMG",       new[]{3,2,0,0}),
        new Recipe("r_long",    "Arc Long d'Artémis", 1, CraftKind.Weapon,   "longbow",       new[]{4,1,0,0}),
        new Recipe("r_hoplite", "Hoplite",            1, CraftKind.Teammate, "spearman",      new[]{3,1,0,0}),
        new Recipe("r_pegasus", "Pégase",             1, CraftKind.Vehicle,  "pegasus",       new[]{4,3,0,0}),
        // --- TIER 2 : armes puissantes + véhicules avancés ----------------------
        new Recipe("r_thunder", "Foudre Divine",      2, CraftKind.Weapon,   "divineThunder", new[]{0,3,2,0}),
        new Recipe("r_harpy",   "Lance-Harpies",      2, CraftKind.Weapon,   "harpyLauncher", new[]{2,2,2,0}),
        new Recipe("r_mage",    "Mage de Thot",       2, CraftKind.Teammate, "thunderling",   new[]{0,2,2,0}),
        new Recipe("r_chariot", "Char d'Arès",        2, CraftKind.Vehicle,  "warChariot",    new[]{0,4,2,0}),
        new Recipe("r_eagle",   "Aigle de Zeus",      2, CraftKind.Vehicle,  "royalEagle",    new[]{0,2,3,0}),
        // --- TIER 3 : ultimes + tous véhicules ----------------------------------
        new Recipe("r_wrath",   "Colère de Zeus",     3, CraftKind.Weapon,   "wrathOfZeus",   new[]{0,0,3,2}),
        new Recipe("r_flail",   "Fléau d'Anubis",     3, CraftKind.Weapon,   "anubisFlail",   new[]{0,0,1,3}),
        new Recipe("r_eye",     "Œil de Râ",          3, CraftKind.Weapon,   "electricBow",   new[]{0,0,4,1}),
        new Recipe("r_turtle",  "Tortue d'Atlas",     3, CraftKind.Vehicle,  "giantTurtle",   new[]{0,3,0,2}),
        new Recipe("r_champion","Champion d'Hadès",   3, CraftKind.Teammate, "champion",      new[]{0,1,1,2}),
    };

    public static WeaponDef Weapon(string id) => Weapons.TryGetValue(id, out var w) ? w : Weapons["fists"];

    // Peut-on payer la recette avec le stock courant [blanc,gris,or,noir] ?
    public static bool CanAfford(Recipe r, int[] stock) {
        for (int i = 0; i < 4; i++) if (stock[i] < r.cost[i]) return false;
        return true;
    }
}

}
