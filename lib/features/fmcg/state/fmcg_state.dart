/// FMCG vendor registry. Same shape as Convenience, but vendors are ONLINE
/// brand-owned storefronts (not physical neighbourhood stores).
library;

class FMCGVendor {
  const FMCGVendor({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.rating,
    required this.eta,
    required this.vendorId,
    required this.iconChar,
  });

  factory FMCGVendor.fromJson(Map<String, dynamic> json) => FMCGVendor(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String,
        category: json['category'] as String,
        rating: (json['rating'] as num).toDouble(),
        eta: json['eta'] as String,
        vendorId: json['vendorId'] as String,
        iconChar: json['iconChar'] as String,
      );

  final String id;
  final String name;
  final String tagline;
  final String category;
  final double rating;
  final String eta;
  final String vendorId;
  final String iconChar;
}

class FMCGItem {
  const FMCGItem({
    required this.sku,
    required this.name,
    required this.priceNgn,
    required this.unit,
    required this.emoji,
  });

  factory FMCGItem.fromJson(Map<String, dynamic> json) => FMCGItem(
        sku: json['sku'] as String,
        name: json['name'] as String,
        priceNgn: (json['priceNgn'] as num).toInt(),
        unit: json['unit'] as String,
        emoji: json['emoji'] as String,
      );

  final String sku;
  final String name;
  final int priceNgn;
  final String unit;
  final String emoji;
}
