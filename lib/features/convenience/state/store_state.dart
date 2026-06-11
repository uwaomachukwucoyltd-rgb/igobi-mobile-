/// Convenience Store node architecture.
///
/// Each StoreNode is a physical retail location with its own inventory ledger.
/// STORE_INVENTORY maps store id → product list, enforcing that a buyer in a
/// given store only sees that store's stock (no cross-store fulfillment).
library;

class StoreNode {
  const StoreNode({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.rating,
    required this.eta,
    required this.vendorId,
    required this.specialties,
  });

  factory StoreNode.fromJson(Map<String, dynamic> json) => StoreNode(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        description: json['description'] as String,
        rating: (json['rating'] as num).toDouble(),
        eta: json['eta'] as String,
        vendorId: json['vendorId'] as String,
        specialties:
            (json['specialties'] as List<dynamic>).cast<String>().toList(),
      );

  final String id;
  final String name;
  final String location;
  final String description;
  final double rating;
  final String eta;
  final String vendorId;
  final List<String> specialties;
}

class StoreProduct {
  const StoreProduct({
    required this.sku,
    required this.name,
    required this.priceNgn,
    required this.unit,
    required this.emoji,
    required this.inStock,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
        sku: json['sku'] as String,
        name: json['name'] as String,
        priceNgn: (json['priceNgn'] as num).toInt(),
        unit: json['unit'] as String,
        emoji: json['emoji'] as String,
        inStock: (json['inStock'] as num).toInt(),
      );

  final String sku;
  final String name;
  final int priceNgn;
  final String unit; // "Pack", "Bundle", "Unit", "Bottle"
  final String emoji;
  final int inStock;
}
