import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Client-side user-profile preferences layered over the server auth user.
///
/// Holds: chosen role, primary Market Hub (state + LGA), Diaspora Mode,
/// and a Recipient Hub used to delegate visibility while keeping escrow
/// gated on the local recipient.

enum UserRole { buyer, vendor, deliveryAgent, admin }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.vendor:
        return 'Vendor / Service Provider';
      case UserRole.deliveryAgent:
        return 'Delivery Agent';
      case UserRole.admin:
        return 'Platform Admin';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.deliveryAgent:
        return 'Agent';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

class IgobiHub {
  const IgobiHub({
    required this.id,
    required this.name,
    required this.lga,
    required this.state,
  });
  final String id;
  final String name;
  final String lga;
  final String state;

  String get displayLine => '$name · $lga, $state';
}

const igobiHubs = <IgobiHub>[
  IgobiHub(id: 'hub_wuse2', name: 'Wuse II Hub', lga: 'Wuse II', state: 'FCT, Abuja'),
  IgobiHub(id: 'hub_garki', name: 'Garki Hub', lga: 'Garki', state: 'FCT, Abuja'),
  IgobiHub(id: 'hub_maitama', name: 'Maitama Hub', lga: 'Maitama', state: 'FCT, Abuja'),
  IgobiHub(id: 'hub_lugbe', name: 'Lugbe Hub', lga: 'Lugbe', state: 'FCT, Abuja'),
  IgobiHub(id: 'hub_lekki', name: 'Lekki Hub', lga: 'Lekki', state: 'Lagos'),
  IgobiHub(id: 'hub_ikoyi', name: 'Ikoyi Hub', lga: 'Ikoyi', state: 'Lagos'),
  IgobiHub(id: 'hub_yaba', name: 'Yaba Hub', lga: 'Yaba', state: 'Lagos'),
  IgobiHub(id: 'hub_surulere', name: 'Surulere Hub', lga: 'Surulere', state: 'Lagos'),
  IgobiHub(id: 'hub_owerri_n', name: 'Owerri North Hub', lga: 'Owerri North', state: 'Imo'),
  IgobiHub(id: 'hub_aba_s', name: 'Aba South Hub', lga: 'Aba South', state: 'Abia'),
  IgobiHub(id: 'hub_kano_fagge', name: 'Sabon Gari Hub', lga: 'Fagge', state: 'Kano'),
  IgobiHub(id: 'hub_onitsha_n', name: 'Onitsha North Hub', lga: 'Onitsha North', state: 'Anambra'),
];

IgobiHub? hubById(String? id) {
  if (id == null) return null;
  for (final h in igobiHubs) {
    if (h.id == id) return h;
  }
  return null;
}

class UserProfile {
  const UserProfile({
    required this.role,
    required this.primaryHubId,
    required this.setupComplete,
    this.diasporaMode = false,
    this.recipientHubId,
    this.businessCategory,
    this.vendorVerified = false,
    this.deliveryVehicle,
    this.escrowBriefingSeen = false,
  });

  final UserRole role;
  final String primaryHubId;
  final bool setupComplete;
  final bool diasporaMode;
  final String? recipientHubId;
  final String? businessCategory; // vendor: Energy Hub / FMCG / etc.
  final bool vendorVerified;
  final String? deliveryVehicle; // 'Bike' / 'Motorcycle' / 'Van'
  final bool escrowBriefingSeen;

  IgobiHub get primaryHub => hubById(primaryHubId) ?? igobiHubs.first;

  /// The hub used to scope visibility. When in Diaspora Mode, this is the
  /// recipient's hub — so the marketplace presents content as if the buyer
  /// were there. Escrow always stays gated on the *recipient* either way.
  IgobiHub get visibilityHub {
    if (diasporaMode && recipientHubId != null) {
      final h = hubById(recipientHubId);
      if (h != null) return h;
    }
    return primaryHub;
  }

  UserProfile copyWith({
    UserRole? role,
    String? primaryHubId,
    bool? setupComplete,
    bool? diasporaMode,
    Object? recipientHubId = _unset,
    Object? businessCategory = _unset,
    bool? vendorVerified,
    Object? deliveryVehicle = _unset,
    bool? escrowBriefingSeen,
  }) {
    return UserProfile(
      role: role ?? this.role,
      primaryHubId: primaryHubId ?? this.primaryHubId,
      setupComplete: setupComplete ?? this.setupComplete,
      diasporaMode: diasporaMode ?? this.diasporaMode,
      recipientHubId: identical(recipientHubId, _unset)
          ? this.recipientHubId
          : recipientHubId as String?,
      businessCategory: identical(businessCategory, _unset)
          ? this.businessCategory
          : businessCategory as String?,
      vendorVerified: vendorVerified ?? this.vendorVerified,
      deliveryVehicle: identical(deliveryVehicle, _unset)
          ? this.deliveryVehicle
          : deliveryVehicle as String?,
      escrowBriefingSeen: escrowBriefingSeen ?? this.escrowBriefingSeen,
    );
  }
}

const _unset = Object();

class UserProfileController extends StateNotifier<UserProfile> {
  UserProfileController()
      : super(const UserProfile(
          role: UserRole.buyer,
          primaryHubId: 'hub_wuse2',
          setupComplete: true, // seeded so the demo flows without setup
          escrowBriefingSeen: true,
        ));

  void setRole(UserRole role) => state = state.copyWith(role: role);

  void setPrimaryHub(String hubId) =>
      state = state.copyWith(primaryHubId: hubId);

  void setSetupComplete(bool v) => state = state.copyWith(setupComplete: v);

  void enableDiaspora(String recipientHubId) {
    state = state.copyWith(
      diasporaMode: true,
      recipientHubId: recipientHubId,
    );
  }

  void disableDiaspora() {
    state = state.copyWith(
      diasporaMode: false,
      recipientHubId: null,
    );
  }

  void setBusinessCategory(String? category) =>
      state = state.copyWith(businessCategory: category);

  void markVendorPending() =>
      state = state.copyWith(vendorVerified: false);

  void approveVendor() =>
      state = state.copyWith(vendorVerified: true);

  void setDeliveryVehicle(String? vehicle) =>
      state = state.copyWith(deliveryVehicle: vehicle);

  void markBriefingSeen() =>
      state = state.copyWith(escrowBriefingSeen: true);
}

final userProfileControllerProvider =
    StateNotifierProvider<UserProfileController, UserProfile>(
  (_) => UserProfileController(),
);
