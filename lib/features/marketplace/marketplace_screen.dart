import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/toast.dart';
import '../auth/state/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_sheet.dart';
import '../inbox/inbox_sheet.dart';
import 'marketplace_data.dart';
import 'state/marketplace_providers.dart';
import 'widgets/category_tile.dart';
import 'widgets/product_card.dart';
import 'widgets/vendor_card.dart';

/// Filter state for the marketplace.
class MarketplaceFilter {
  const MarketplaceFilter({this.category, this.query = ''});
  final String? category;
  final String query;

  MarketplaceFilter copyWith({Object? category = _unset, String? query}) =>
      MarketplaceFilter(
        category: identical(category, _unset) ? this.category : category as String?,
        query: query ?? this.query,
      );

  /// Map a UI category label ("Energy Hub", "Farm Harvest", "Artisan", etc.)
  /// to the canonical lowercase slug stored on vendor-service products
  /// ("energy", "farm", "services"). Returns the input unchanged when no
  /// mapping exists so unfamiliar labels still match by equality.
  static String _normalize(String label) {
    final n = label.trim().toLowerCase();
    switch (n) {
      case 'energy hub':
      case 'energy':
      case 'lpg':
      case 'fuel':
        return 'energy';
      case 'farm harvest':
      case 'farm':
      case 'farm produce':
        return 'farm';
      case 'community market':
      case 'community':
      case 'community-market':
        return 'community-market';
      case 'fmcg':
      case 'convenience':
      case 'groceries':
        return 'fmcg';
      case 'artisan':
      case 'service':
      case 'services':
        return 'services';
      case 'mccoy parts':
      case 'mccoy-parts':
      case 'parts':
        return 'mccoy-parts';
      case 'mccoy mechanic':
      case 'mechanic':
        return 'mccoy-mechanic';
      default:
        return n;
    }
  }

  bool matches(Product p) {
    final inCategory = category == null ||
        _normalize(p.category) == _normalize(category!);
    final matchesText =
        query.isEmpty || p.name.toLowerCase().contains(query.toLowerCase());
    return inCategory && matchesText;
  }

  static const _unset = Object();
}

final marketplaceFilterProvider =
    StateProvider<MarketplaceFilter>((_) => const MarketplaceFilter());

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    final cart = ref.watch(cartControllerProvider);
    final filter = ref.watch(marketplaceFilterProvider);
    final vendorsAsync = ref.watch(featuredVendorsProvider);
    final productsAsync = ref.watch(trendingProductsProvider);

    final displayName = (state is AuthSignedIn)
        ? (state.user.displayName?.trim().isNotEmpty == true
            ? state.user.displayName!.split(' ').first
            : state.user.email.split('@').first)
        : 'Guest';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final filteredProducts = productsAsync.maybeWhen(
      data: (list) => list.where(filter.matches).toList(),
      orElse: () => const <Product>[],
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              elevation: 0,
              backgroundColor: AppColors.softWhite,
              titleSpacing: 16,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                          color: AppColors.emerald, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Good morning,',
                          style: TextStyle(fontSize: 12, color: AppColors.slate)),
                      Text(
                        displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => showInboxSheet(context),
                  ),
                  _CartButton(count: cart.count, onTap: () => showCartSheet(context)),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: _EscrowBanner()),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Categories')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // 0.78 (was 0.85) — fixes the 1.6px tile overflow on narrow
                  // viewports by giving each cell a touch more vertical room.
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final cat = categories[i];
                    final active = filter.category == cat.label;
                    return CategoryTile(
                      category: cat,
                      active: active,
                      onTap: () {
                        // Some categories are buyer-initiated workflows, not
                        // product filters — they push to their own screens.
                        if (cat.label == 'Community Market') {
                          context.push('/community');
                          return;
                        }
                        if (cat.label == 'Artisan') {
                          context.push('/artisan');
                          return;
                        }
                        if (cat.label == 'Convenience') {
                          context.push('/convenience');
                          return;
                        }
                        if (cat.label == 'Farm Harvest') {
                          context.push('/farm');
                          return;
                        }
                        if (cat.label == 'Energy Hub') {
                          context.push('/energy');
                          return;
                        }
                        if (cat.label == 'FMCG') {
                          context.push('/fmcg');
                          return;
                        }
                        if (cat.label == 'McCoy Parts') {
                          context.push('/mccoy-parts');
                          return;
                        }
                        if (cat.label == 'McCoy Mechanic') {
                          context.push('/mccoy-mechanic');
                          return;
                        }
                        ref.read(marketplaceFilterProvider.notifier).state =
                            filter.copyWith(category: active ? null : cat.label);
                        if (!active) {
                          showToast(
                            context,
                            'Filtered: ${cat.label}',
                            icon: cat.icon,
                            background: cat.color,
                          );
                        }
                      },
                    );
                  },
                  childCount: categories.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _SectionHeader(title: 'Verified vendors')),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 168,
                child: vendorsAsync.when(
                  data: (vendors) => vendors.isEmpty
                      ? const _EmptyVendors()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: vendors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final v = vendors[i];
                            return VendorCard(
                              vendor: v,
                              onTap: () => context.push('/vendor/${v.id}'),
                            );
                          },
                        ),
                  loading: () => const _VendorCarouselSkeleton(),
                  error: (err, _) => _LoadError(
                    message: 'Could not load vendors',
                    onRetry: () => ref.invalidate(featuredVendorsProvider),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: filter.category != null
                    ? '${filter.category} · ${filteredProducts.length} result${filteredProducts.length == 1 ? '' : 's'}'
                    : 'Trending today',
                trailing: filter.category != null || filter.query.isNotEmpty
                    ? TextButton(
                        onPressed: () =>
                            ref.read(marketplaceFilterProvider.notifier).state =
                                const MarketplaceFilter(),
                        child: const Text('Clear'),
                      )
                    : null,
              ),
            ),
            ...productsAsync.when(
              data: (_) {
                if (filteredProducts.isEmpty) {
                  return const [SliverToBoxAdapter(child: _EmptyResults())];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(product: filteredProducts[i]),
                        childCount: filteredProducts.length,
                      ),
                    ),
                  ),
                ];
              },
              loading: () => const [
                SliverToBoxAdapter(child: _ProductGridSkeleton()),
              ],
              error: (err, _) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _LoadError(
                      message: 'Could not load products',
                      onRetry: () => ref.invalidate(trendingProductsProvider),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_bag_outlined),
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.emerald,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.softWhite, width: 2),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(marketplaceFilterProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: AppColors.charcoal, fontSize: 15),
        onChanged: (v) {
          ref.read(marketplaceFilterProvider.notifier).state = filter.copyWith(query: v);
        },
        decoration: InputDecoration(
          hintText: 'Search vendors, products, services…',
          hintStyle: const TextStyle(color: AppColors.slate),
          prefixIcon: const Icon(Icons.search, color: AppColors.slate),
          suffixIcon: filter.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.slate),
                  onPressed: () {
                    _controller.clear();
                    ref.read(marketplaceFilterProvider.notifier).state =
                        filter.copyWith(query: '');
                  },
                )
              : Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
        ),
      ),
    );
  }
}

class _EscrowBanner extends StatelessWidget {
  const _EscrowBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showToast(
        context,
        'Your money is escrow-protected on every order.',
        icon: Icons.shield_outlined,
        background: AppColors.emerald,
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emerald, AppColors.emeraldDark],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your money is safe with Escrow',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Released only when you confirm delivery.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slateLight),
        ),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.slate, size: 48),
            SizedBox(height: 10),
            Text(
              'No results for this filter',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              'Try clearing the search or pick another category.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: AppColors.slate, size: 36),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorCarouselSkeleton extends StatelessWidget {
  const _VendorCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.slateLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.slateLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _EmptyVendors extends StatelessWidget {
  const _EmptyVendors();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'No verified vendors yet — check back soon.',
          style: TextStyle(color: AppColors.slate, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
