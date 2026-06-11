/// Farm Harvest — direct-to-farm sourcing nodes.
///
/// Each FarmNode is a verified rural cluster (a co-op, aggregator, or hub)
/// tied to a specific LGA. FARM_INVENTORY maps node id → batch-tracked produce
/// listings. All farm-harvest transactions go through escrow (Integrity
/// Protocol), and every order incurs a ₦3,500 flat Local Dispatch fee.
library;

const int localDispatchFeeNgn = 3500;

class FarmNode {
  const FarmNode({
    required this.id,
    required this.name,
    required this.lga,
    required this.state,
    required this.region,
    required this.description,
    required this.rating,
    required this.specialties,
    required this.vendorId,
  });

  factory FarmNode.fromJson(Map<String, dynamic> json) => FarmNode(
        id: json['id'] as String,
        name: json['name'] as String,
        lga: json['lga'] as String,
        state: json['state'] as String,
        region: json['region'] as String,
        description: json['description'] as String,
        rating: (json['rating'] as num).toDouble(),
        specialties:
            (json['specialties'] as List<dynamic>).cast<String>().toList(),
        vendorId: json['vendorId'] as String,
      );

  final String id;
  final String name;
  final String lga;     // Local Government Area
  final String state;
  final String region;  // "South-West", "South-South", "North-Central", etc.
  final String description;
  final double rating;
  final List<String> specialties;
  final String vendorId;
}

class FarmProduct {
  const FarmProduct({
    required this.sku,
    required this.batchId,
    required this.name,
    required this.priceNgn,
    required this.unit,        // "Tuber", "Basket", "Bag", "5L Bottle"
    required this.emoji,
    required this.harvestedAt, // YYYY-MM-DD
  });

  factory FarmProduct.fromJson(Map<String, dynamic> json) => FarmProduct(
        sku: json['sku'] as String,
        batchId: json['batchId'] as String,
        name: json['name'] as String,
        priceNgn: (json['priceNgn'] as num).toInt(),
        unit: json['unit'] as String,
        emoji: json['emoji'] as String,
        harvestedAt: json['harvestedAt'] as String,
      );

  final String sku;
  final String batchId;
  final String name;
  final int priceNgn;
  final String unit;
  final String emoji;
  final String harvestedAt;
}

