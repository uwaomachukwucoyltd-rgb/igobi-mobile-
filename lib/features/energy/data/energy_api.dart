import '../../../core/api/api_client.dart';

/// A fuel product as returned by the vendor-service energy catalog.
class EnergyProduct {

  factory EnergyProduct.fromJson(Map<String, dynamic> json) {
    return EnergyProduct(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      casual: (json['casual'] ?? '').toString(),
      pricePerUnitNgn: (json['pricePerUnitNgn'] as num?)?.round() ?? 0,
      unitLabel: (json['unitLabel'] ?? 'L').toString(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
  const EnergyProduct({
    required this.id,
    required this.code,
    required this.displayName,
    required this.casual,
    required this.pricePerUnitNgn,
    required this.unitLabel,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String displayName;
  final String casual;
  final int pricePerUnitNgn;
  final String unitLabel;
  final int sortOrder;
}

/// A confirmed energy order returned by POST /energy/orders.
class EnergyOrder {

  factory EnergyOrder.fromJson(Map<String, dynamic> json) {
    return EnergyOrder(
      id: (json['id'] ?? '').toString(),
      fuelCode: (json['fuelCode'] ?? '').toString(),
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] ?? 'L').toString(),
      vehicle: (json['vehicle'] ?? '').toString(),
      totalNgn: (json['totalNgn'] as num?)?.round() ?? 0,
    );
  }
  const EnergyOrder({
    required this.id,
    required this.fuelCode,
    required this.qty,
    required this.unit,
    required this.vehicle,
    required this.totalNgn,
  });

  final String id;
  final String fuelCode;
  final int qty;
  final String unit;
  final String vehicle;
  final int totalNgn;
}

class EnergyApi {
  EnergyApi(this._client);

  final ApiClient _client;

  Future<List<EnergyProduct>> listProducts() async {
    final json = await _client.getJson('/api/v1/energy/products');
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    final products =
        data.map(EnergyProduct.fromJson).toList(growable: true);
    products.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return products;
  }

  Future<EnergyOrder> createOrder({
    required String fuelCode,
    required int qty,
    required String unit,
    required String vehicle,
    required int totalNgn,
  }) async {
    final json = await _client.postJson('/api/v1/energy/orders', {
      'fuelCode': fuelCode,
      'qty': qty,
      'unit': unit,
      'vehicle': vehicle,
      'totalNgn': totalNgn,
    });
    final data = json['data'] as Map<String, dynamic>;
    return EnergyOrder.fromJson(data);
  }
}
