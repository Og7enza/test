// =============================================================================
//  Core.cs — Réglages globaux, helpers de génération procédurale (matériaux /
//  primitives), audio synthétisé minimal, et BOOTSTRAP automatique.
//
//  Tout le jeu est construit au RUNTIME (aucun prefab/scène à câbler) : il
//  suffit d'une scène vide dans les Build Settings, le jeu se lance seul grâce
//  à [RuntimeInitializeOnLoadMethod].
// =============================================================================
using UnityEngine;

namespace DivineRivals {

public static class Config {
    public const int   TargetFPS      = 30;
    public const float ArenaHalf      = 30f;

    // Nuages
    public const float WaveInterval   = 6f;
    public const int   PerWave        = 4;
    public const int   MaxClouds      = 40;
    public const float CloudFall      = 9f;
    public const float CloudSpawnY    = 22f;
    public const float PickupReach    = 2.0f;
    public const int   NearCauldron   = 1;   // nuages déposés près de chaque chaudron / vague

    // Buddies
    public const float BuddyRadius    = 0.75f;
    public const float BuddySpeed     = 7.2f;
    public const float BuddyHP        = 100f;
    public const int   StartBuddies   = 2;   // NOUVEAU : on démarre avec 2
    public const int   MaxBuddies     = 4;   // assignés + libres
    public const float RespawnDelay   = 6f;
    public const float AimRange       = 26f;

    // Chaudron
    public const int   CauldronCap    = 8;   // nuages stockés max
    public const float UseRadius      = 3.6f;
    public const int   Posts          = 3;   // postes d'assignation (Tier 0..3)

    // Base = buste du dieu
    public const float BustHP         = 1200f;
    public const float BustRadius     = 3.8f;
    public const float RiseTime       = 2.6f;
    public const float RiseDepth      = 7.5f;
    public const float DefRange       = 17f;
    public const float DefCooldown    = 1.5f;
    public const float DefDamage      = 16f;

    // Couleurs de nuages : 0 blanc, 1 gris, 2 or, 3 noir.
    public static readonly Color[] CloudCol = {
        new Color(1f, 1f, 1f),
        new Color(0.72f, 0.76f, 0.82f),
        new Color(1f, 0.84f, 0.32f),
        new Color(0.16f, 0.16f, 0.22f),
    };
    public static readonly string[] CloudName = { "Blanc", "Gris", "Or", "Noir" };
    // Probabilités d'apparition (cumulées) : blanc fréquent … noir extrêmement rare.
    public static readonly float[] CloudWeight = { 0.70f, 0.22f, 0.06f, 0.02f };

    // Couleurs d'équipe + dieu associé.
    public static readonly Color[] TeamPrimary = {
        new Color(0.23f, 0.63f, 1f), new Color(0.75f, 0.22f, 0.17f),
        new Color(0.18f, 0.80f, 0.44f), new Color(0.96f, 0.82f, 0.25f),
    };
    public static readonly Color[] TeamAccent = {
        new Color(1f, 0.82f, 0.29f), new Color(1f, 0.55f, 0.26f),
        new Color(0.95f, 0.77f, 0.06f), new Color(0.90f, 0.45f, 0.13f),
    };
    public static readonly string[] TeamName = { "Olympe", "Hadès", "Anubis", "Râ" };
    public static readonly string[] GodName  = { "Zeus", "Hadès", "Anubis", "Râ" };
    // Clés (minuscules sans accent) pour les noms de fichiers d'assets.
    public static readonly string[] TeamKey = { "olympe", "hades", "anubis", "ra" };
    public static readonly string[] GodKey  = { "zeus", "hades", "anubis", "ra" };
    public static readonly Vector3 CamOffset = new Vector3(0, 50, 32);
}

// --- Helpers de génération procédurale --------------------------------------
public static class P {
    static Shader _litShader;
    static Shader Lit() {
        if (_litShader == null)
            _litShader = Shader.Find("Universal Render Pipeline/Lit")
                      ?? Shader.Find("Standard")
                      ?? Shader.Find("Legacy Shaders/Diffuse")
                      ?? Shader.Find("Unlit/Color");
        return _litShader;
    }

    public static Material Mat(Color c, bool emissive = false) {
        var m = new Material(Lit());
        m.color = c;
        if (m.HasProperty("_BaseColor")) m.SetColor("_BaseColor", c);
        if (emissive) {
            m.EnableKeyword("_EMISSION");
            if (m.HasProperty("_EmissionColor")) m.SetColor("_EmissionColor", c * 1.6f);
        }
        return m;
    }

    // Crée une primitive (sans collider physique : la logique gère tout à la main).
    public static GameObject Prim(PrimitiveType t, Transform parent, Vector3 pos, Vector3 scale, Material mat) {
        var g = GameObject.CreatePrimitive(t);
        var col = g.GetComponent<Collider>();
        if (col) Object.Destroy(col);
        if (parent) g.transform.SetParent(parent, false);
        g.transform.localPosition = pos;
        g.transform.localScale = scale;
        if (mat) g.GetComponent<Renderer>().sharedMaterial = mat;
        return g;
    }

    public static GameObject Group(string name, Transform parent = null) {
        var g = new GameObject(name);
        if (parent) g.transform.SetParent(parent, false);
        return g;
    }

    // Charge une texture depuis Resources/art/ (null si absente).
    public static Texture2D Tex(string name) { return Resources.Load<Texture2D>("art/" + name); }

    // Quad "sprite" cartoon orienté face à la caméra iso (angle FIXE : marche
    // pour l'écran partagé). Renvoie le GameObject (ou un quad neutre si tex null).
    public static GameObject Billboard(Transform parent, Texture2D tex, float h) {
        var q = GameObject.CreatePrimitive(PrimitiveType.Quad);
        var col = q.GetComponent<Collider>(); if (col) Object.Destroy(col);
        q.transform.SetParent(parent, false);
        float aspect = (tex != null && tex.height > 0) ? tex.width / (float)tex.height : 1f;
        q.transform.localScale = new Vector3(h * aspect, h, 1f);
        q.transform.localPosition = new Vector3(0, h * 0.5f, 0);
        q.transform.localRotation = Quaternion.LookRotation(Config.CamOffset.normalized, Vector3.up);
        var sh = Shader.Find("Sprites/Default") ?? Shader.Find("Unlit/Transparent");
        var m = new Material(sh); m.mainTexture = tex;
        q.GetComponent<Renderer>().sharedMaterial = m;
        return q;
    }
}

// --- Audio synthétisé minimal (aucun fichier requis) ------------------------
public class Sfx {
    AudioSource src;
    public Sfx(GameObject host) {
        src = host.AddComponent<AudioSource>();
        src.playOnAwake = false; src.spatialBlend = 0f;
    }
    AudioClip Tone(float f0, float f1, float dur, bool noise = false) {
        int sr = 22050, n = Mathf.Max(1, (int)(sr * dur));
        var clip = AudioClip.Create("t", n, 1, sr, false);
        var data = new float[n];
        float ph = 0f;
        for (int i = 0; i < n; i++) {
            float t = i / (float)n;
            float f = Mathf.Lerp(f0, f1, t);
            ph += f / sr * 2f * Mathf.PI;
            float v = noise ? (Random.value * 2f - 1f) : Mathf.Sin(ph);
            data[i] = v * (1f - t) * 0.5f;          // enveloppe descendante
        }
        clip.SetData(data, 0);
        return clip;
    }
    public void Play(AudioClip c, float vol = 0.7f) { if (c) src.PlayOneShot(c, vol); }
    AudioClip _pick, _craft, _shoot, _boom, _hurt;
    public void Pickup()    { if (_pick == null) _pick = Tone(320, 720, 0.14f); Play(_pick, 0.4f); }
    public void Craft()     { if (_craft == null) _craft = Tone(520, 1046, 0.3f); Play(_craft, 0.5f); }
    public void Shoot()     { if (_shoot == null) _shoot = Tone(700, 1100, 0.07f); Play(_shoot, 0.25f); }
    public void Boom()      { if (_boom == null) _boom = Tone(200, 40, 0.4f, true); Play(_boom, 0.6f); }
    public void Hurt()      { if (_hurt == null) _hurt = Tone(300, 120, 0.12f); Play(_hurt, 0.3f); }
}

// --- Bootstrap automatique --------------------------------------------------
public static class Boot {
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    static void Launch() {
        var go = new GameObject("DivineRivals");
        Object.DontDestroyOnLoad(go);
        go.AddComponent<Game>();
    }
}

}
