class Coupon {
  final String coupon;
  final String id;
  final String description;
  final int maxLimit;
  final int usedLimit;

  Coupon({
    required this.coupon,
    required this.id,
    required this.description,
    required this.maxLimit,
    required this.usedLimit,
  });

  factory Coupon.fromJson(Map json) {
    return Coupon(
      coupon: json['coupon'],
      id: json['_id'],
      description: json['description'],
      maxLimit: json['maxLimit'],
      usedLimit: json['usedLimit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coupon': coupon,
      '_id': id,
      'description': description,
      'maxLimit': maxLimit,
      'usedLimit': usedLimit,
    };
  }
}
