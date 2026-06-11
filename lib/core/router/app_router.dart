import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/artisan/artisan_screen.dart';
import '../../features/auth/delete_account_screen.dart';
import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/legal/legal_screens.dart';
import '../../features/community/community_screen.dart';
import '../../features/convenience/convenience_screen.dart';
import '../../features/convenience/store_detail_screen.dart';
import '../../features/energy/energy_screen.dart';
import '../../features/farm/farm_detail_screen.dart';
import '../../features/farm/farm_screen.dart';
import '../../features/fmcg/fmcg_detail_screen.dart';
import '../../features/fmcg/fmcg_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/impact/impact_screen.dart';
import '../../features/marketplace/vendor_detail_screen.dart';
import '../../features/mccoy_mechanic/mccoy_mechanic_screen.dart';
import '../../features/mccoy_parts/mccoy_parts_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/role_setup_screen.dart';
import '../../features/recurring/recurring_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wallet/wallet_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, __) => const SignUpScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeShell()),
      GoRoute(path: '/setup', builder: (_, __) => const RoleSetupScreen()),
      GoRoute(
        path: '/account/delete',
        builder: (_, __) => const DeleteAccountScreen(),
      ),
      GoRoute(
        path: '/impact',
        builder: (_, __) => const ImpactScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (_, __) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/vendor/:id',
        builder: (_, state) => VendorDetailScreen(vendorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/community',
        builder: (_, __) => const CommunityMarketScreen(),
      ),
      GoRoute(
        path: '/artisan',
        builder: (_, __) => const ArtisanHubScreen(),
      ),
      GoRoute(
        path: '/convenience',
        builder: (_, __) => const ConvenienceScreen(),
      ),
      GoRoute(
        path: '/store/:id',
        builder: (_, state) =>
            StoreDetailScreen(storeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farm',
        builder: (_, __) => const FarmHarvestScreen(),
      ),
      GoRoute(
        path: '/farm/:id',
        builder: (_, state) =>
            FarmDetailScreen(farmId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/energy',
        builder: (_, __) => const EnergyHubScreen(),
      ),
      GoRoute(
        path: '/fmcg',
        builder: (_, __) => const FMCGScreen(),
      ),
      GoRoute(
        path: '/fmcg/:id',
        builder: (_, state) =>
            FMCGDetailScreen(vendorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/mccoy-parts',
        builder: (_, __) => const McCoyPartsScreen(),
      ),
      GoRoute(
        path: '/mccoy-mechanic',
        builder: (_, __) => const McCoyMechanicScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (_, __) => const WalletScreen(),
      ),
      GoRoute(
        path: '/rewards',
        builder: (_, __) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/recurring',
        builder: (_, __) => const RecurringScreen(),
      ),
    ],
  );
});
