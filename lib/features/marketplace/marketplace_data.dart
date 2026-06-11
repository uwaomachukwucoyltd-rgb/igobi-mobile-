// Marketplace UI constants + domain models. The static `featuredVendors` and
// `trendingProducts` lists that used to live here are gone — vendors and
// products are now served by `vendor-service`. See state/marketplace_providers.dart.
//
// The Vendor and Product classes still live here so the screens and widgets
// that already import them keep compiling without churn; they now construct
// from API JSON via fromJson.

import 'package:flutter/material.dart';

class Category {
  const Category(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Eight canonical IGOBI marketplace categories. Grid renders 4 × 2.
/// Most categories push to their own workflow screens (not product filters).
/// These are UI-only constants — they're not stored server-side and don't
/// need to round-trip.
const List<Category> categories = [
  Category('Energy Hub',       Icons.local_gas_station_rounded,       Color(0xFFF97316)), // orange — direct-sync fuel
  Category('Community Market', Icons.diversity_3_rounded,             Color(0xFFD4A24C)), // gold — buyer-initiated errands
  Category('FMCG',             Icons.inventory_2_rounded,             Color(0xFF6366F1)), // indigo — online brand vendors
  Category('Convenience',      Icons.local_convenience_store_outlined, Color(0xFF0EA5E9)),// cyan — physical store nodes
  Category('Farm Harvest',     Icons.agriculture_rounded,             Color(0xFF65A30D)), // lime — direct-to-farm
  Category('Artisan',          Icons.handyman_rounded,                Color(0xFFD97706)), // amber — service dispatch
  Category('McCoy Parts',      Icons.precision_manufacturing_rounded, Color(0xFF334155)), // slate — industrial / OEM
  Category('McCoy Mechanic',   Icons.car_repair_rounded,              Color(0xFFE11D48)), // rose — diagnostic broadcast
];

class Vendor {
  const Vendor({
    required this.id,
    required this.name,
    required this.tagline,
    required this.trustScore,
    required this.location,
    required this.category,
    required this.verified,
    this.emoji,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String,
        trustScore: (json['trustScore'] as num).toDouble(),
        location: json['location'] as String,
        category: json['category'] as String,
        verified: (json['verified'] as bool?) ?? false,
        emoji: json['emoji'] as String?,
      );

  final String id;
  final String name;
  final String tagline;
  final double trustScore;
  final String location;
  final String category;
  final bool verified;
  final String? emoji;
}

enum ProductType { physical, service }

ProductType _productTypeFromWire(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'SERVICE':
      return ProductType.service;
    case 'PHYSICAL':
    default:
      return ProductType.physical;
  }
}

String productTypeToWire(ProductType type) =>
    type == ProductType.service ? 'SERVICE' : 'PHYSICAL';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.vendorId,
    required this.category,
    required this.productType,
    required this.priceNgn,
    required this.unit,
    required this.emoji,
  });

  /// The API returns `priceMinor` as a decimal string (BigInt in kobo). The
  /// mobile UI works in whole-Naira ints, so we divide by 100 here. Any
  /// downstream Naira-only assumption (e.g. cart total → payment amountMinor)
  /// continues to multiply by 100 when crossing the wire.
  factory Product.fromJson(Map<String, dynamic> json) {
    final priceMinorStr = json['priceMinor'] as String;
    final priceMinor = BigInt.parse(priceMinorStr);
    final priceNgn = (priceMinor ~/ BigInt.from(100)).toInt();
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      vendorId: json['vendorId'] as String,
      category: json['category'] as String,
      productType: _productTypeFromWire(json['productType'] as String?),
      priceNgn: priceNgn,
      unit: json['unit'] as String,
      emoji: (json['emoji'] as String?) ?? '🛍️',
    );
  }

  final String id;
  final String name;
  final String vendorId;
  final String category;
  /// PHYSICAL → pay vendor directly (no escrow). SERVICE → escrow flow.
  /// Drives the branching in cart_sheet._placeOrder.
  final ProductType productType;
  final int priceNgn;
  final String unit;
  final String emoji;
}
