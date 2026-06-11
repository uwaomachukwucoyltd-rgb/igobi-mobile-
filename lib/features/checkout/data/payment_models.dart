enum PaymentStatus { pending, success, failed, abandoned, refunded }

PaymentStatus _statusFromWire(String s) {
  switch (s.toUpperCase()) {
    case 'SUCCESS':
      return PaymentStatus.success;
    case 'FAILED':
      return PaymentStatus.failed;
    case 'ABANDONED':
      return PaymentStatus.abandoned;
    case 'REFUNDED':
      return PaymentStatus.refunded;
    case 'PENDING':
    default:
      return PaymentStatus.pending;
  }
}

class PaymentResponse {
  PaymentResponse({
    required this.id,
    required this.reference,
    required this.providerReference,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.authorizationUrl,
    required this.description,
    required this.createdAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PaymentResponse(
      id: data['id'] as String,
      reference: data['reference'] as String,
      providerReference: data['providerReference'] as String?,
      status: _statusFromWire(data['status'] as String),
      amountMinor: BigInt.parse(data['amountMinor'] as String),
      currency: data['currency'] as String,
      authorizationUrl: data['authorizationUrl'] as String?,
      description: data['description'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  final String id;
  final String reference;
  final String? providerReference;
  final PaymentStatus status;
  final BigInt amountMinor;
  final String currency;
  final String? authorizationUrl;
  final String? description;
  final DateTime createdAt;
}
