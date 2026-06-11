/// Canonical IGOBI fee categories — mirrors the FeeCategory enum on
/// payment-service. The mobile derives this from the cart's items'
/// `Product.category` strings before calling the quote endpoint.
enum FeeCategory {
  lpg,
  fmcg,
  farm,
  artisan,
  mccoyParts,
  mccoyMechanic,
}

String feeCategoryToWire(FeeCategory c) {
  switch (c) {
    case FeeCategory.lpg:
      return 'LPG';
    case FeeCategory.fmcg:
      return 'FMCG';
    case FeeCategory.farm:
      return 'FARM';
    case FeeCategory.artisan:
      return 'ARTISAN';
    case FeeCategory.mccoyParts:
      return 'MCCOY_PARTS';
    case FeeCategory.mccoyMechanic:
      return 'MCCOY_MECHANIC';
  }
}

/// Map the loose marketplace category labels (used as `Product.category`
/// in vendor-service) onto canonical fee categories. Mirrors the server's
/// `feeCategoryFromProductCategory`. Keeping the mapping on both sides
/// means the mobile can pre-check "this is a mixed-category cart" before
/// the round-trip.
FeeCategory feeCategoryFromProductCategory(String label) {
  final n = label.trim().toLowerCase();
  if (n == 'energy hub' || n == 'lpg' || n == 'fuel') return FeeCategory.lpg;
  if (n == 'farm harvest' || n == 'farm' || n == 'agriculture') return FeeCategory.farm;
  if (n == 'artisan' || n == 'service' || n == 'services') return FeeCategory.artisan;
  if (n == 'mccoy parts' || n == 'parts') return FeeCategory.mccoyParts;
  if (n == 'mccoy mechanic' || n == 'mechanic') return FeeCategory.mccoyMechanic;
  return FeeCategory.fmcg; // default safe fallback
}

enum FeeStakeholder { product, vendor, rider, platform, donation }

FeeStakeholder _stakeholderFromWire(String s) {
  switch (s.toLowerCase()) {
    case 'product':
      return FeeStakeholder.product;
    case 'vendor':
      return FeeStakeholder.vendor;
    case 'rider':
      return FeeStakeholder.rider;
    case 'donation':
      return FeeStakeholder.donation;
    case 'platform':
    default:
      return FeeStakeholder.platform;
  }
}

class QuoteLineItem {
  const QuoteLineItem({
    required this.code,
    required this.label,
    required this.amountMinor,
    required this.stakeholder,
  });

  factory QuoteLineItem.fromJson(Map<String, dynamic> json) {
    return QuoteLineItem(
      code: json['code'] as String,
      label: json['label'] as String,
      amountMinor: BigInt.parse(json['amountMinor'] as String),
      stakeholder: _stakeholderFromWire(json['stakeholder'] as String),
    );
  }

  final String code;
  final String label;
  final BigInt amountMinor;
  final FeeStakeholder stakeholder;

  /// Convenience for UI rendering — whole Naira from kobo.
  int get amountNgn => (amountMinor ~/ BigInt.from(100)).toInt();
}

class CheckoutQuote {
  const CheckoutQuote({
    required this.category,
    required this.subtotalMinor,
    required this.lineItems,
    required this.feesTotalMinor,
    required this.platformRevenueMinor,
    required this.religiousDonationMinor,
    required this.totalChargeMinor,
  });

  factory CheckoutQuote.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return CheckoutQuote(
      category: _parseCategory(data['category'] as String),
      subtotalMinor: BigInt.parse(data['subtotalMinor'] as String),
      lineItems: (data['lineItems'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(QuoteLineItem.fromJson)
          .toList(growable: false),
      feesTotalMinor: BigInt.parse(data['feesTotalMinor'] as String),
      platformRevenueMinor: BigInt.parse(data['platformRevenueMinor'] as String),
      religiousDonationMinor: BigInt.parse(data['religiousDonationMinor'] as String),
      totalChargeMinor: BigInt.parse(data['totalChargeMinor'] as String),
    );
  }

  static FeeCategory _parseCategory(String raw) {
    switch (raw) {
      case 'LPG':
        return FeeCategory.lpg;
      case 'FARM':
        return FeeCategory.farm;
      case 'ARTISAN':
        return FeeCategory.artisan;
      case 'MCCOY_PARTS':
        return FeeCategory.mccoyParts;
      case 'MCCOY_MECHANIC':
        return FeeCategory.mccoyMechanic;
      case 'FMCG':
      default:
        return FeeCategory.fmcg;
    }
  }

  final FeeCategory category;
  final BigInt subtotalMinor;
  final List<QuoteLineItem> lineItems;
  final BigInt feesTotalMinor;
  final BigInt platformRevenueMinor;
  final BigInt religiousDonationMinor;
  final BigInt totalChargeMinor;

  /// Cart-level helpers for the UI.
  int get subtotalNgn => (subtotalMinor ~/ BigInt.from(100)).toInt();
  int get feesTotalNgn => (feesTotalMinor ~/ BigInt.from(100)).toInt();
  int get totalChargeNgn => (totalChargeMinor ~/ BigInt.from(100)).toInt();
  int get religiousDonationNgn =>
      (religiousDonationMinor ~/ BigInt.from(100)).toInt();

  bool get hasDonation => religiousDonationMinor > BigInt.zero;
}
