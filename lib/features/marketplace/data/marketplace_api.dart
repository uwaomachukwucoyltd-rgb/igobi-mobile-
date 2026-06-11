import '../../../core/api/api_client.dart';
import '../marketplace_data.dart';

class MarketplaceApi {
  MarketplaceApi(this._client);

  final ApiClient _client;

  Future<List<Vendor>> listVendors({
    String? category,
    bool verifiedOnly = false,
    int limit = 50,
  }) async {
    final params = <String>[
      'limit=$limit',
      if (category != null) 'category=${Uri.encodeQueryComponent(category)}',
      if (verifiedOnly) 'verifiedOnly=true',
    ];
    final path = '/api/v1/vendors?${params.join('&')}';
    final json = await _client.getJson(path);
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Vendor.fromJson).toList(growable: false);
  }

  Future<Vendor> getVendor(String idOrSlug) async {
    final json = await _client.getJson('/api/v1/vendors/$idOrSlug');
    final data = json['data'] as Map<String, dynamic>;
    return Vendor.fromJson(data);
  }

  Future<List<Product>> listProducts({
    String? vendorId,
    String? category,
    bool inStockOnly = true,
    int limit = 50,
  }) async {
    final params = <String>[
      'limit=$limit',
      if (inStockOnly) 'inStockOnly=true',
      if (vendorId != null) 'vendorId=${Uri.encodeQueryComponent(vendorId)}',
      if (category != null) 'category=${Uri.encodeQueryComponent(category)}',
    ];
    final path = '/api/v1/products?${params.join('&')}';
    final json = await _client.getJson(path);
    final data = (json['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    return data.map(Product.fromJson).toList(growable: false);
  }
}
