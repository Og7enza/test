// Textes de démonstration (placeholders) pour les pages Aide / Confidentialité /
// CGU. À remplacer par les textes définitifs avant mise en production.

const String kHelpText = '''
Aide — TruthCatcher

1. Certifier une photo
Touchez « Certifier », prenez une photo (ou importez-en une pour la démo).
L'app calcule une empreinte SHA-256, l'horodate, la géolocalise, puis incruste
un matricule unique directement sur l'image.

2. Le matricule
C'est l'identifiant public et infalsifiable de votre preuve. Il est tamponné
sur la photo : toute personne qui voit l'image peut le saisir dans l'onglet
« Recherche » pour retrouver et vérifier la preuve d'origine.

3. NFT
Chaque preuve peut être mintée en NFT (simulé en démo) pour une traçabilité
renforcée.

4. Besoin d'aide ?
Contact : support@truthcatcher.app (démo).
''';

const String kPrivacyText = '''
Politique de confidentialité (démo)

Cette version de démonstration ne transmet aucune donnée à un serveur : tout
est traité localement sur l'appareil et simulé.

Données utilisées localement :
- Photos que vous capturez ou importez.
- Position GPS au moment de la capture (pour la preuve).
- Horodatage de la capture.

En production, ces données serviraient à établir la preuve et seraient
protégées conformément au RGPD. Vous pourriez à tout moment supprimer votre
compte et vos données depuis l'écran Profil.
''';

const String kTermsText = '''
Conditions générales d'utilisation (démo)

Ceci est une application de démonstration. Les paiements, le mint NFT et
l'authentification sont simulés : aucun débit réel, aucune transaction
blockchain, aucun compte réel.

1. Usage
TruthCatcher fournit un outil de certification de photos. La valeur probante
réelle dépend de l'implémentation finale (signature serveur, ancrage
blockchain).

2. Responsabilité
En démonstration, aucune garantie n'est fournie quant à la validité juridique
des preuves générées.

3. Contact
legal@truthcatcher.app (démo).
''';
