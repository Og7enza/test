import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_coupon_service.dart';

final couponServiceProvider =
    Provider<CouponService>((ref) => const CouponService());
