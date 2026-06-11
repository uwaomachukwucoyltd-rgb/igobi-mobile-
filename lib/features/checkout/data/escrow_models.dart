enum EscrowStatus {
  pendingFunding,
  funded,
  partiallyReleased,
  released,
  refunded,
  disputed,
  cancelled,
}

EscrowStatus _statusFromWire(String s) {
  switch (s.toUpperCase()) {
    case 'FUNDED':
      return EscrowStatus.funded;
    case 'PARTIALLY_RELEASED':
      return EscrowStatus.partiallyReleased;
    case 'RELEASED':
      return EscrowStatus.released;
    case 'REFUNDED':
      return EscrowStatus.refunded;
    case 'DISPUTED':
      return EscrowStatus.disputed;
    case 'CANCELLED':
      return EscrowStatus.cancelled;
    case 'PENDING_FUNDING':
    default:
      return EscrowStatus.pendingFunding;
  }
}

class EscrowResponse {
  EscrowResponse({
    required this.id,
    required this.reference,
    required this.status,
    required this.amountMinor,
    required this.heldMinor,
    required this.currency,
    required this.paymentId,
    required this.vendorId,
    required this.description,
    required this.createdAt,
  });

  factory EscrowResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return EscrowResponse(
      id: data['id'] as String,
      reference: data['reference'] as String,
      status: _statusFromWire(data['status'] as String),
      amountMinor: BigInt.parse(data['amountMinor'] as String),
      heldMinor: BigInt.parse(data['heldMinor'] as String),
      currency: data['currency'] as String,
      paymentId: data['paymentId'] as String?,
      vendorId: data['vendorId'] as String,
      description: data['description'] as String?,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  final String id;
  final String reference;
  final EscrowStatus status;
  final BigInt amountMinor;
  final BigInt heldMinor;
  final String currency;
  final String? paymentId;
  final String vendorId;
  final String? description;
  final DateTime createdAt;
}
