
enum SubscriptionTier {
  starter('starter'),
  basic('basic'),
  smart('smart'),
  ultimate('ultimate');

  final String id;
  const SubscriptionTier(this.id);

  static SubscriptionTier fromId(String id) {
    final lowerId = id.toLowerCase();
    if (lowerId.contains('ultimate') || lowerId.contains('premium')) return SubscriptionTier.ultimate;
    if (lowerId.contains('smart') || lowerId.contains('plus')) return SubscriptionTier.smart;
    if (lowerId.contains('basic')) return SubscriptionTier.basic;
    return SubscriptionTier.starter;
  }
}

class SubscriptionFeature {
  final String name;
  final bool included;

  const SubscriptionFeature({
    required this.name,
    this.included = true,
  });

  factory SubscriptionFeature.fromJson(Map<String, dynamic> json) {
    return SubscriptionFeature(
      name: json['name'] as String,
      included: json['included'] as bool? ?? true,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String? badge;
  final String? tagline;
  final double monthlyPrice;
  final double? yearlyPrice;
  final String? yearlyDiscountBadge;
  final List<SubscriptionFeature> features;
  final String ctaText;

  SubscriptionTier get tier => SubscriptionTier.fromId(id);

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.badge,
    this.tagline,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.yearlyDiscountBadge,
    required this.features,
    this.ctaText = 'Get Started',
  });

  bool get isFree => monthlyPrice == 0;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    double monthly = 0;
    double? yearly;
    String? yearlyDiscount;

    if (json['pricing'] != null) {
      if (json['pricing']['monthly'] != null) {
        monthly = (json['pricing']['monthly']['amount'] as num).toDouble();
      }
      if (json['pricing']['yearly'] != null) {
        yearly = (json['pricing']['yearly']['amount'] as num).toDouble();
        if (json['pricing']['yearly']['discount_percentage'] != null) {
          yearlyDiscount = 'Save ${json['pricing']['yearly']['discount_percentage']}%';
        }
      }
    }

    List<SubscriptionFeature> featureList = [];
    if (json['features'] != null) {
      featureList = (json['features'] as List)
          .map((f) => SubscriptionFeature.fromJson(f as Map<String, dynamic>))
          .toList();
    }

    String cta = 'Choose Premium';
    final nameLower = (json['name'] as String?)?.toLowerCase() ?? '';
    if (nameLower.contains('starter') || nameLower.contains('free')) {
      cta = 'Choose Starter';
    } else if (nameLower.contains('basic')) {
      cta = 'Choose Basic';
    } else if (nameLower.contains('smart') || nameLower.contains('plus')) {
      cta = 'Choose Plus';
    }

    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      badge: json['badge'] as String?,
      tagline: json['tagline'] as String?,
      monthlyPrice: monthly,
      yearlyPrice: yearly,
      yearlyDiscountBadge: yearlyDiscount,
      features: featureList,
      ctaText: cta,
    );
  }
}
