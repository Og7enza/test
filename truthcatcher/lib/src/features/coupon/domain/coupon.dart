/// Coupon de réduction (modernise l'ancien modèle `coupon`).
class Coupon {
  const Coupon({required this.code, required this.percentOff});

  final String code;
  final int percentOff;

  double apply(double amount) => amount * (1 - percentOff / 100);
}
