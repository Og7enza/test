# Présentation — deck, étude de gain de token & pitch

Trois livrables complémentaires, dans l'esprit du dépôt (hors-ligne, sans dépendance) :

| Fichier | Rôle |
| --- | --- |
| [`index.html`](index.html) | **Deck présentable** : plein écran, navigation clavier (← →), tactile, hors-ligne. Structure Présentation → Étude de gain de token → Pitch. |
| [`DECK.md`](DECK.md) | Version texte du deck (slide par slide), éditable. |
| [`ETUDE_GAIN_TOKEN.md`](ETUDE_GAIN_TOKEN.md) | L'étude chiffrée complète : méthode, hypothèses, calcul, sensibilité, limites. |

## Ouvrir le deck

Double-cliquez `index.html` (aucun serveur requis), ou depuis la racine du dépôt :

```bash
npm start   # puis http://localhost:8080/presentation/
```

Commandes du deck : **← / →** naviguer · **F** plein écran · **swipe** sur mobile ·
pastilles en bas pour sauter à une diapo.

## Résultat clé de l'étude

> Sur un livrable équivalent (3 produits, 3 plateformes, 8 131 lignes de code), la
> méthode adoptée économise **≈ 2,0 M tokens (~66 %)** et **48 générations média**.
> Détail et hypothèses ajustables dans [`ETUDE_GAIN_TOKEN.md`](ETUDE_GAIN_TOKEN.md).
