import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/toast.dart';
import '../../cart/cart_controller.dart';
import '../marketplace_data.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0)
        .format(product.priceNgn);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => showToast(
          context,
          '${product.name} — details coming soon',
          icon: Icons.info_outline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.slateLight.withValues(alpha: 0.5),
                child: Center(
                  child: Text(product.emoji, style: const TextStyle(fontSize: 56)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'per ${product.unit}',
                    style: const TextStyle(color: AppColors.slate, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          ref.read(cartControllerProvider.notifier).add(product);
                          showToast(
                            context,
                            'Added ${product.name} to cart',
                            icon: Icons.shopping_bag_outlined,
                            background: AppColors.emerald,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
