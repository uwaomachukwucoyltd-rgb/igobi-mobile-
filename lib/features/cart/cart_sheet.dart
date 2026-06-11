import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/success_logo_burst.dart';
import '../auth/state/auth_controller.dart';
import '../checkout/checkout_webview_screen.dart';
import '../checkout/data/checkout_quote_models.dart';
import '../checkout/data/escrow_models.dart';
import '../checkout/data/payment_models.dart';
import '../checkout/state/checkout_providers.dart';
import 'cart_controller.dart';

// Sentinel URL the Flutterwave hosted page is told to redirect to after
// payment completes. The webview never lets it actually load — we intercept
// the navigation and pop back to the caller. Does not need to be a real page.
const String _checkoutReturnUrl = 'https://igobi.app/checkout/return';

final _money = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

Future<void> showCartSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CartSheet(),
  );
}

class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.slateLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text(
                    'Your cart',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!cart.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cart.count} item${cart.count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cart.isEmpty
                  ? _EmptyState(onClose: () => Navigator.pop(context))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
                    ),
            ),
            if (!cart.isEmpty) _CartFooter(cart: cart),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  size: 40, color: AppColors.emerald),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the + on any product to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 13),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
              child: const Text('Browse marketplace'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});
  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartControllerProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.slateLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(item.product.emoji, style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_money.format(item.product.priceNgn)} / ${item.product.unit}',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  _money.format(item.subtotalNgn),
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _QtyStepper(
            qty: item.qty,
            onIncrement: () => cart.increment(item.product.id),
            onDecrement: () => cart.decrement(item.product.id),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.charcoal),
      ),
    );
  }
}

class _CartFooter extends ConsumerWidget {
  const _CartFooter({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.slateLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Itemised breakdown — pulled from /checkout/quote so the customer
          // sees exactly what they'll be charged, including the line that
          // goes to their religious organisation. Falls back to the simple
          // subtotal display while the quote is still loading.
          _QuoteBreakdown(cart: cart),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 14, color: AppColors.emerald),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cart.isAllService
                      ? 'Funds are held in iGobi escrow until you confirm delivery.'
                      : cart.isMixedTypes
                          ? 'Services and products must check out separately.'
                          : cart.isMixedFeeCategories
                              ? 'Items from different categories must check out separately.'
                              : 'Vendors are paid directly. If something goes wrong, file a complaint and the vendor is suspended until you confirm resolution.',
                  style: const TextStyle(color: AppColors.slate, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.emerald, AppColors.emeraldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _placeOrder(context, ref),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Place order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final auth = ref.read(authControllerProvider);
    if (auth is! AuthSignedIn) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Please sign in to complete checkout.'),
      ));
      return;
    }
    if (cart.items.isEmpty) return;

    // Mixed-type carts are blocked. The Nigerian commerce model: products
    // pay vendors directly (no escrow); services hold funds in escrow. The
    // two flows can't share a single transaction in v1.
    if (cart.isMixedTypes) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
          "Services and products check out separately — please remove one type to continue.",
        ),
        duration: Duration(seconds: 5),
      ));
      return;
    }

    if (cart.isAllPhysical) {
      await _placePhysicalOrder(context, ref, auth);
    } else {
      await _placeServiceOrder(context, ref, auth);
    }
  }

  /// Physical-product checkout. No escrow — payment-service credits the
  /// vendor's wallet on SUCCESS (driven by metadata.productType + vendorId).
  Future<void> _placePhysicalOrder(
    BuildContext context,
    WidgetRef ref,
    AuthSignedIn auth,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final paymentApi = ref.read(paymentApiProvider);

    // Resolve the live quote — the customer is charged what the receipt on
    // their screen says. If the quote failed (network or mixed cart), fall
    // back to the raw subtotal so they can still try.
    final quote = await ref.read(cartQuoteProvider.future);
    final total = quote?.totalChargeNgn ?? cart.totalNgn;
    final amountMinor = quote?.totalChargeMinor.toInt() ?? cart.totalNgn * 100;

    // v1: single-vendor carts only. Multi-vendor splits land alongside a
    // future orders-service that fans the payment across each vendor.
    final vendorId = cart.items.first.product.vendorId;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PlacingDialog(),
    );

    PaymentResponse payment;
    try {
      // POST /orders creates an Order (vendor's Orders screen picks it up)
      // AND initialises the Payment in one call. metadata.productType +
      // metadata.vendorId are stamped server-side on the linked Payment so
      // the existing ledger / payout fan-out keeps working.
      payment = await paymentApi.createOrder(
        vendorId: vendorId,
        items: cart.items
            .map((i) => {
                  'productId': i.product.id,
                  'name': i.product.name,
                  'qty': i.qty,
                  'unitPriceMinor': i.product.priceNgn * 100,
                })
            .toList(growable: false),
        description: 'iGobi order (${cart.count} item${cart.count == 1 ? '' : 's'})',
        callbackUrl: _checkoutReturnUrl,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    final authUrl = payment.authorizationUrl;
    if (!context.mounted) return;
    Navigator.pop(context);

    if (authUrl == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Checkout could not be started. Please try again.'),
      ));
      return;
    }

    final result = await Navigator.of(context, rootNavigator: true).push<CheckoutResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CheckoutWebViewScreen(
          authorizationUrl: authUrl,
          callbackUrl: _checkoutReturnUrl,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result?.kind != CheckoutResultKind.completed) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _VerifyingDialog(),
    );

    PaymentResponse verified;
    try {
      verified = await paymentApi.verify(payment.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    if (verified.status == PaymentStatus.success) {
      ref.read(cartControllerProvider.notifier).clear();
      Navigator.of(context).maybePop();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _OrderPlacedDialog(
          reference: verified.reference,
          total: total,
          escrowed: false,
          quote: quote,
        ),
      );
      messenger.hideCurrentSnackBar();
    } else if (verified.status == PaymentStatus.pending) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Payment is still processing. We'll update your order shortly."),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(
          verified.status == PaymentStatus.abandoned
              ? 'Checkout was cancelled.'
              : 'Payment did not complete. Please try again.',
        ),
      ));
    }
  }

  /// Service checkout. Funds an escrow held until the buyer confirms the
  /// service was delivered.
  Future<void> _placeServiceOrder(
    BuildContext context,
    WidgetRef ref,
    AuthSignedIn auth,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final paymentApi = ref.read(paymentApiProvider);
    final escrowApi = ref.read(escrowApiProvider);

    final quote = await ref.read(cartQuoteProvider.future);
    final total = quote?.totalChargeNgn ?? cart.totalNgn;
    final amountMinor = quote?.totalChargeMinor.toInt() ?? cart.totalNgn * 100;
    final vendorId = cart.items.first.product.vendorId;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PlacingDialog(),
    );

    EscrowResponse escrow;
    try {
      escrow = await escrowApi.create(
        vendorId: vendorId,
        amountMinor: amountMinor,
        currency: 'NGN',
        description: 'iGobi service (${cart.count} item${cart.count == 1 ? '' : 's'})',
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    PaymentResponse payment;
    try {
      payment = await paymentApi.create(
        amountMinor: amountMinor,
        currency: 'NGN',
        customerEmail: auth.user.email,
        description: 'iGobi escrow ${escrow.reference}',
        callbackUrl: _checkoutReturnUrl,
        idempotencyKey: 'escrow-${escrow.id}',
        metadata: {
          'productType': 'SERVICE',
          'vendorId': vendorId,
          'escrowId': escrow.id,
          // Phase B — same as physical path; payment-service replays the
          // quote on SUCCESS to record stakeholder splits.
          if (quote != null) 'feeCategory': feeCategoryToWire(quote.category),
          if (quote != null) 'subtotalMinor': quote.subtotalMinor.toInt(),
          if (auth.user.selectedReligiousOrgId != null)
            'religiousOrgId': auth.user.selectedReligiousOrgId,
        },
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    final authUrl = payment.authorizationUrl;
    if (!context.mounted) return;
    Navigator.pop(context);

    if (authUrl == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Checkout could not be started. Please try again.'),
      ));
      return;
    }

    final result = await Navigator.of(context, rootNavigator: true).push<CheckoutResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CheckoutWebViewScreen(
          authorizationUrl: authUrl,
          callbackUrl: _checkoutReturnUrl,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result?.kind != CheckoutResultKind.completed) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _VerifyingDialog(),
    );

    PaymentResponse verified;
    try {
      verified = await paymentApi.verify(payment.id);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (verified.status != PaymentStatus.success) {
      if (!context.mounted) return;
      Navigator.pop(context);
      if (verified.status == PaymentStatus.pending) {
        messenger.showSnackBar(const SnackBar(
          content: Text("Payment is still processing. We'll update your order shortly."),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(
            verified.status == PaymentStatus.abandoned
                ? 'Checkout was cancelled.'
                : 'Payment did not complete. Please try again.',
          ),
        ));
      }
      return;
    }

    EscrowResponse funded;
    try {
      funded = await escrowApi.fund(
        escrowId: escrow.id,
        paymentId: verified.id,
        paymentReference: verified.reference,
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Payment received but escrow could not be set up: ${e.message}. Support has been notified.',
        ),
        duration: const Duration(seconds: 6),
      ));
      return;
    } on NetworkException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    if (!context.mounted) return;
    Navigator.pop(context);
    ref.read(cartControllerProvider.notifier).clear();
    Navigator.of(context).maybePop();

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _OrderPlacedDialog(
        reference: funded.reference,
        total: total,
        quote: quote,
        escrowed: true,
      ),
    );
    messenger.hideCurrentSnackBar();
  }
}

class _VerifyingDialog extends StatelessWidget {
  const _VerifyingDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: AppColors.emerald, strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Text('Confirming your payment…',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Renders the itemised receipt above the Place Order button. While the
/// quote is in flight, falls back to the simple cart total so the customer
/// never sees a flicker. On error we still let the user proceed (the
/// payment leg will recompute server-side); we just hide the breakdown.
class _QuoteBreakdown extends ConsumerWidget {
  const _QuoteBreakdown({required this.cart});
  final CartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(cartQuoteProvider);
    return quoteAsync.maybeWhen(
      data: (quote) => quote == null
          ? _SimpleTotal(amountNgn: cart.totalNgn)
          : _DetailedBreakdown(quote: quote),
      orElse: () => _SimpleTotal(amountNgn: cart.totalNgn),
    );
  }
}

class _SimpleTotal extends StatelessWidget {
  const _SimpleTotal({required this.amountNgn});
  final int amountNgn;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                )),
            SizedBox(height: 2),
          ],
        ),
        Text(
          _money.format(amountNgn),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _DetailedBreakdown extends StatelessWidget {
  const _DetailedBreakdown({required this.quote});
  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Each non-donation line item as a label + amount row.
        for (final item
            in quote.lineItems.where((i) => i.stakeholder != FeeStakeholder.donation))
          _BreakdownRow(label: item.label, amountNgn: item.amountNgn),
        // Donation line is dimmer + has a subtle leading dot — visually
        // distinct from the lines that change what the customer pays.
        if (quote.hasDonation) ...[
          const SizedBox(height: 2),
          _DonationRow(quote: quote),
        ],
        const Divider(height: 16, color: AppColors.slateLight),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                )),
            Text(
              _money.format(quote.totalChargeNgn),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.amountNgn});
  final String label;
  final int amountNgn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.slate, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _money.format(amountNgn),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  const _DonationRow({required this.quote});
  final CheckoutQuote quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded,
              size: 12, color: AppColors.emerald),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_money.format(quote.religiousDonationNgn)} of our fee goes to your community',
              style: const TextStyle(
                color: AppColors.emerald,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacingDialog extends StatelessWidget {
  const _PlacingDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: AppColors.emerald, strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Text('Preparing secure checkout…',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _OrderPlacedDialog extends StatelessWidget {
  const _OrderPlacedDialog({
    required this.reference,
    required this.total,
    required this.escrowed,
    this.quote,
  });
  final String reference;
  final int total;
  /// True for service checkouts (escrow), false for direct-pay product orders.
  final bool escrowed;
  /// The quote the customer was charged from. Nullable so the dialog still
  /// renders for legacy flows; when present, we show the itemised receipt.
  final CheckoutQuote? quote;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessLogoBurst(size: 88),
            const SizedBox(height: 4),
            const Text(
              'Order placed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text(
              escrowed
                  ? 'Your funds are held in iGobi escrow. The vendor is notified and will\nconfirm shortly.'
                  : 'Payment received and sent to the vendor. They\'ve been notified and will\narrange delivery shortly.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(escrowed ? 'ESCROW REFERENCE' : 'ORDER REFERENCE',
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    reference,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(escrowed ? 'Amount held' : 'Amount paid',
                          style: const TextStyle(color: AppColors.slate, fontSize: 12)),
                      Text(
                        _money.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                  if (quote != null && quote!.hasDonation) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            size: 12, color: AppColors.emerald),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_money.format(quote!.religiousDonationNgn)} of our fee will support your community',
                            style: const TextStyle(
                              color: AppColors.emerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Track order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
