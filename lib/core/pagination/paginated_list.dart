import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page of items from a server-side cursor or skip/limit endpoint. We keep
/// it minimal so the notifier doesn't care which pagination convention the
/// service uses — the fetcher returns whatever it knows and we trust it.
@immutable
class PaginatedPage<T> {
  const PaginatedPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextCursor;
}

typedef PageFetcher<T> = Future<PaginatedPage<T>> Function({
  required int skip,
  required int limit,
  String? cursor,
});

@immutable
class PaginatedListState<T> {
  const PaginatedListState({
    required this.items,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.cursor,
  });

  const PaginatedListState.initial()
      : items = const [],
        isLoading = false,
        hasMore = true,
        error = null,
        cursor = null;

  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? cursor;

  PaginatedListState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? cursor,
    bool clearError = false,
  }) =>
      PaginatedListState<T>(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        error: clearError ? null : (error ?? this.error),
        cursor: cursor ?? this.cursor,
      );
}

/// Drop-in pagination engine for any infinite-scroll list. The caller supplies
/// a [PageFetcher] that knows how to talk to the relevant service; the
/// notifier owns the loaded items, the cursor, hasMore, and the in-flight
/// flag so the UI never double-fires a load when the user scrolls fast.
///
/// Usage:
/// ```dart
/// final marketplaceProductsProvider = StateNotifierProvider.autoDispose<
///     PaginatedListNotifier<Product>, PaginatedListState<Product>>(
///   (ref) => PaginatedListNotifier<Product>(
///     pageSize: 20,
///     fetcher: ({required skip, required limit, cursor}) async {
///       final res = await ref.read(vendorApiProvider).getJson(
///             '/api/v1/products?skip=$skip&limit=$limit',
///           );
///       final list = (res['data'] as List).cast<Map<String, dynamic>>();
///       return PaginatedPage(
///         items: list.map(Product.fromJson).toList(),
///         hasMore: list.length == limit,
///       );
///     },
///   )..loadFirstPage(),
/// );
/// ```
///
/// In the screen, fire [loadNextPage] from your ScrollController when within
/// ~600px of the bottom and the state's hasMore is true and isLoading is
/// false. The notifier guards against the rest.
class PaginatedListNotifier<T> extends StateNotifier<PaginatedListState<T>> {
  PaginatedListNotifier({
    required this.fetcher,
    this.pageSize = 20,
  }) : super(const PaginatedListState.initial());

  final PageFetcher<T> fetcher;
  final int pageSize;

  Future<void> loadFirstPage() async {
    state = const PaginatedListState.initial();
    await _loadPage(reset: true);
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;
    await _loadPage(reset: false);
  }

  Future<void> refresh() async {
    // Keep current items on screen until the new page lands so we don't flash
    // an empty list when the user pulls to refresh.
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await fetcher(skip: 0, limit: pageSize, cursor: null);
      state = PaginatedListState<T>(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadPage({required bool reset}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final skip = reset ? 0 : state.items.length;
      final page = await fetcher(
        skip: skip,
        limit: pageSize,
        cursor: reset ? null : state.cursor,
      );
      final merged = reset ? page.items : [...state.items, ...page.items];
      state = PaginatedListState<T>(
        items: merged,
        isLoading: false,
        hasMore: page.hasMore,
        cursor: page.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
