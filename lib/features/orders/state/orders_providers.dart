import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../checkout/data/escrow_models.dart';
import '../../checkout/data/payment_models.dart';
import '../../checkout/state/checkout_providers.dart';

/// Unified "order" entry the Orders screen renders. An order is either a
/// PHYSICAL payment (no escrow) or a SERVICE escrow (whose payment is the
/// funding leg). They share enough surface to display in a single list.
class OrderEntry {
  const OrderEntry({
    required this.id,
    required this.title,
    required this.reference,
    required this.amountMinor,
    required this.currency,
    required this.createdAt,
    required this.isService,
    required this.statusLabel,
    required this.escrow,
    required this.payment,
  });

  final String id;
  final String title;
  final String reference;
  final BigInt amountMinor;
  final String currency;
  final DateTime createdAt;
  final bool isService;
  final String statusLabel;
  final EscrowResponse? escrow;
  final PaymentResponse? payment;

  int get amountNgn => (amountMinor ~/ BigInt.from(100)).toInt();
}

String _escrowStatusLabel(EscrowStatus s) {
  switch (s) {
    case EscrowStatus.pendingFunding:
      return 'Awaiting payment';
    case EscrowStatus.funded:
      return 'Funds in escrow';
    case EscrowStatus.partiallyReleased:
      return 'Partially released';
    case EscrowStatus.released:
      return 'Completed';
    case EscrowStatus.refunded:
      return 'Refunded';
    case EscrowStatus.disputed:
      return 'In dispute';
    case EscrowStatus.cancelled:
      return 'Cancelled';
  }
}

String _paymentStatusLabel(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.pending:
      return 'Payment pending';
    case PaymentStatus.success:
      return 'Paid · sent to vendor';
    case PaymentStatus.failed:
      return 'Payment failed';
    case PaymentStatus.abandoned:
      return 'Cancelled';
    case PaymentStatus.refunded:
      return 'Refunded';
  }
}

final ordersFeedProvider = FutureProvider<List<OrderEntry>>((ref) async {
  final escrowApi = ref.watch(escrowApiProvider);
  final paymentApi = ref.watch(paymentApiProvider);

  // Run both in parallel — bills time off the slower one, not the sum.
  final results = await Future.wait([
    escrowApi.listMine(),
    paymentApi.listMine(),
  ]);
  final escrows = results[0] as List<EscrowResponse>;
  final payments = results[1] as List<PaymentResponse>;

  // Payments whose flow already produced an Escrow row should be deduped —
  // we'll surface the escrow entry as the source of truth. The escrow's
  // `paymentId` points back to the funding payment.
  final coveredPaymentIds = escrows
      .map((e) => e.paymentId)
      .where((id) => id != null)
      .cast<String>()
      .toSet();

  final entries = <OrderEntry>[
    ...escrows.map((e) => OrderEntry(
          id: 'escrow:${e.id}',
          title: e.description ?? 'iGobi service order',
          reference: e.reference,
          amountMinor: e.amountMinor,
          currency: e.currency,
          createdAt: e.createdAt,
          isService: true,
          statusLabel: _escrowStatusLabel(e.status),
          escrow: e,
          payment: null,
        )),
    ...payments
        .where((p) => !coveredPaymentIds.contains(p.id))
        .map((p) => OrderEntry(
              id: 'payment:${p.id}',
              title: p.description ?? 'iGobi order',
              reference: p.reference,
              amountMinor: p.amountMinor,
              currency: p.currency,
              createdAt: p.createdAt,
              isService: false,
              statusLabel: _paymentStatusLabel(p.status),
              escrow: null,
              payment: p,
            )),
  ];

  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
});
