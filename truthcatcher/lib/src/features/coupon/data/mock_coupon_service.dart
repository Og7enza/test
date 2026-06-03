import '../domain/coupon.dart';

/// Vérification de coupon simulée. Codes de démo : `DEMO10`, `TRUTH50`.
class CouponService {
  const CouponService();

  Future<Coupon?> verify(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    switch (code.trim().toUpperCase()) {
      case 'DEMO10':
        return const Coupon(code: 'DEMO10', percentOff: 10);
      case 'TRUTH50':
        return const Coupon(code: 'TRUTH50', percentOff: 50);
      default:
        return null;
    }
  }
}
