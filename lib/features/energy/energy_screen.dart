import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/success_logo_burst.dart';
import 'state/energy_providers.dart';

enum FuelType { pms, ago, dpk, lpg }

extension FuelTypeX on FuelType {
  String get code => switch (this) {
        FuelType.pms => 'PMS',
        FuelType.ago => 'AGO',
        FuelType.dpk => 'DPK',
        FuelType.lpg => 'LPG',
      };
  String get displayName => switch (this) {
        FuelType.pms => 'Premium Motor Spirit',
        FuelType.ago => 'Automotive Gas Oil',
        FuelType.dpk => 'Dual Purpose Kerosene',
        FuelType.lpg => 'Liquefied Petroleum Gas',
      };
  String get casual => switch (this) {
        FuelType.pms => 'Petrol',
        FuelType.ago => 'Diesel',
        FuelType.dpk => 'Kerosene',
        FuelType.lpg => 'Cooking Gas',
      };
  IconData get icon => switch (this) {
        FuelType.pms => Icons.local_gas_station_rounded,
        FuelType.ago => Icons.local_shipping_rounded,
        FuelType.dpk => Icons.local_fire_department_rounded,
        FuelType.lpg => Icons.propane_tank_rounded,
      };
  // Fallback unit label used until live catalog data arrives.
  String get unitLabel => this == FuelType.lpg ? 'KG' : 'L';

  // Indicative fallback prices (₦/unit). Live prices from the energy catalog
  // override these in the screen; these keep the UI sane while loading/offline.
  int get pricePerUnitNgn => switch (this) {
        FuelType.pms => 950,
        FuelType.ago => 1450,
        FuelType.dpk => 1300,
        FuelType.lpg => 1500,
      };

  static FuelType? fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PMS':
        return FuelType.pms;
      case 'AGO':
        return FuelType.ago;
      case 'DPK':
        return FuelType.dpk;
      case 'LPG':
        return FuelType.lpg;
      default:
        return null;
    }
  }
}

enum DeliveryVehicle { bike, truck, tanker }

extension DeliveryVehicleX on DeliveryVehicle {
  String get label => switch (this) {
        DeliveryVehicle.bike => 'Bike',
        DeliveryVehicle.truck => 'Truck',
        DeliveryVehicle.tanker => 'Tanker',
      };
  IconData get icon => switch (this) {
        DeliveryVehicle.bike => Icons.two_wheeler_rounded,
        DeliveryVehicle.truck => Icons.local_shipping_rounded,
        DeliveryVehicle.tanker => Icons.directions_bus_filled_rounded,
      };
}

const _logisticsSyncFeeNgn = 2000;
const _orange = Color(0xFFF97316);
const _orangeDark = Color(0xFFC2410C);

final _money =
    NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

class EnergyHubScreen extends ConsumerStatefulWidget {
  const EnergyHubScreen({super.key});
  @override
  ConsumerState<EnergyHubScreen> createState() => _EnergyHubScreenState();
}

class _EnergyHubScreenState extends ConsumerState<EnergyHubScreen> {
  FuelType _fuel = FuelType.pms;
  int _qty = 0;
  // Live per-unit prices keyed by fuel code (PMS/AGO/DPK/LPG), populated from
  // the energy catalog in build(). Falls back to indicative prices.
  Map<String, int> _livePrices = const {};

  int get _unitPrice => _livePrices[_fuel.code] ?? _fuel.pricePerUnitNgn;

  DeliveryVehicle get _autoVehicle {
    if (_fuel == FuelType.lpg) {
      if (_qty < 25) return DeliveryVehicle.bike;
      if (_qty < 100) return DeliveryVehicle.truck;
      return DeliveryVehicle.tanker;
    }
    // PMS / AGO / DPK in litres
    if (_qty < 50) return DeliveryVehicle.bike;
    if (_qty < 200) return DeliveryVehicle.truck;
    return DeliveryVehicle.tanker;
  }

  int get _productSubtotal => _qty * _unitPrice;
  int get _total => _productSubtotal + _logisticsSyncFeeNgn;

  @override
  Widget build(BuildContext context) {
    // Pull live catalog prices; keep last good values if a refresh is pending.
    final products = ref.watch(energyProductsProvider).valueOrNull;
    if (products != null && products.isNotEmpty) {
      _livePrices = {for (final p in products) p.code: p.pricePerUnitNgn};
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  const _Hero(),
                  const SizedBox(height: 12),
                  const _NetworkActiveStrip(),
                  const SizedBox(height: 20),
                  const _SectionLabel('Choose fuel'),
                  const SizedBox(height: 8),
                  _FuelGrid(
                    selected: _fuel,
                    onPick: (f) => setState(() {
                      _fuel = f;
                      _qty = 0;
                    }),
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel(
                      'Quantity (${_fuel.unitLabel}) · ${_money.format(_unitPrice)}/${_fuel.unitLabel}'),
                  const SizedBox(height: 8),
                  _QuantityPanel(
                    qty: _qty,
                    unit: _fuel.unitLabel,
                    onChange: (q) => setState(() => _qty = q),
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Logistics protocol'),
                  const SizedBox(height: 8),
                  _VehicleRow(active: _autoVehicle, qty: _qty),
                  const SizedBox(height: 16),
                  const _EscrowBypassNotice(),
                ],
              ),
            ),
            _OrderFooter(
              productSubtotal: _productSubtotal,
              total: _total,
              fuel: _fuel,
              qty: _qty,
              vehicle: _autoVehicle,
              onOrder: () => _confirm(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    if (_qty <= 0) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SyncingDialog(),
    );
    try {
      await ref.read(energyApiProvider).createOrder(
            fuelCode: _fuel.code,
            qty: _qty,
            unit: _fuel.unitLabel,
            vehicle: _autoVehicle.label,
            totalNgn: _total,
          );
      if (!context.mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (_) => _DispatchedDialog(
          fuel: _fuel,
          qty: _qty,
          total: _total,
          vehicle: _autoVehicle,
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not place the order. Try again.')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
          ),
          const Text('Energy Hub',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_orange, _orangeDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'DIRECT SYNC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.flash_on_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Standardised pricing · immediate dispatch.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verified petroleum stations and gas plants — synced to the iGobi logistics grid.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkActiveStrip extends StatefulWidget {
  const _NetworkActiveStrip();
  @override
  State<_NetworkActiveStrip> createState() => _NetworkActiveStripState();
}

class _NetworkActiveStripState extends State<_NetworkActiveStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.success
                    .withValues(alpha: 0.4 + (_c.value * 0.5)),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'LGA Network Active · 38 stations syncing in your zone',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.slate,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _FuelGrid extends StatelessWidget {
  const _FuelGrid({required this.selected, required this.onPick});
  final FuelType selected;
  final ValueChanged<FuelType> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.0,
      ),
      itemCount: FuelType.values.length,
      itemBuilder: (_, i) {
        final f = FuelType.values[i];
        final isOn = f == selected;
        return InkWell(
          onTap: () => onPick(f),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn ? _orange.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOn ? _orange : AppColors.slateLight,
                width: isOn ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(f.icon, color: _orange, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.code,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      Text(f.casual,
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuantityPanel extends StatelessWidget {
  const _QuantityPanel({
    required this.qty,
    required this.unit,
    required this.onChange,
  });
  final int qty;
  final String unit;
  final ValueChanged<int> onChange;

  void _add(int n) => onChange(qty + n);
  void _clear() => onChange(0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slateLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.softWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    qty == 0 ? '— $unit' : '$qty $unit',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.backspace_outlined,
                      color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickAdd(label: '+5', onTap: () => _add(5)),
              const SizedBox(width: 8),
              _QuickAdd(label: '+10', onTap: () => _add(10)),
              const SizedBox(width: 8),
              _QuickAdd(label: '+25', onTap: () => _add(25)),
              const SizedBox(width: 8),
              _QuickAdd(label: '+50', onTap: () => _add(50)),
              const SizedBox(width: 8),
              _QuickAdd(label: '+100', onTap: () => _add(100)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _orange.withValues(alpha: 0.25)),
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                  color: _orangeDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                )),
          ),
        ),
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.active, required this.qty});
  final DeliveryVehicle active;
  final int qty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final v in DeliveryVehicle.values) ...[
          Expanded(child: _VehicleTile(v: v, active: v == active, qty: qty)),
          if (v != DeliveryVehicle.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile(
      {required this.v, required this.active, required this.qty});
  final DeliveryVehicle v;
  final bool active;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final help = switch (v) {
      DeliveryVehicle.bike => 'small loads',
      DeliveryVehicle.truck => 'mid-range',
      DeliveryVehicle.tanker => 'bulk',
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? _orange.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? _orange : AppColors.slateLight,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(v.icon,
              color: active ? _orange : AppColors.slate, size: 24),
          const SizedBox(height: 6),
          Text(v.label,
              style: TextStyle(
                color: active ? _orange : AppColors.charcoal,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              )),
          Text(help,
              style: const TextStyle(color: AppColors.slate, fontSize: 10)),
        ],
      ),
    );
  }
}

class _EscrowBypassNotice extends StatelessWidget {
  const _EscrowBypassNotice();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: _orange, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, height: 1.4),
                children: [
                  TextSpan(
                    text: 'Escrow bypass · ',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _orangeDark,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Verified energy nodes settle directly per iGobi Terms §6 — keeps the petroleum logistics moving.',
                    style: TextStyle(color: AppColors.charcoalSoft),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFooter extends StatelessWidget {
  const _OrderFooter({
    required this.productSubtotal,
    required this.total,
    required this.fuel,
    required this.qty,
    required this.vehicle,
    required this.onOrder,
  });
  final int productSubtotal;
  final int total;
  final FuelType fuel;
  final int qty;
  final DeliveryVehicle vehicle;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    final disabled = qty <= 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 16 + MediaQuery.of(context).padding.bottom),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$qty ${fuel.unitLabel} ${fuel.code} · ${vehicle.label}',
                style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(_money.format(productSubtotal),
                  style: const TextStyle(fontSize: 13, color: AppColors.slate)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LOGISTICS SYNC',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(_money.format(_logisticsSyncFeeNgn),
                  style: const TextStyle(fontSize: 13, color: AppColors.slate)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                _money.format(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: disabled
                      ? [AppColors.slateLight, AppColors.slateLight]
                      : [_orange, _orangeDark],
                ),
                boxShadow: disabled
                    ? null
                    : [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: disabled ? null : onOrder,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.flash_on_rounded,
                          color: disabled ? AppColors.slate : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          disabled ? 'Enter quantity' : 'Dispatch now',
                          style: TextStyle(
                            color: disabled ? AppColors.slate : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
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
}

class _SyncingDialog extends StatelessWidget {
  const _SyncingDialog();
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
              child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
            ),
            SizedBox(width: 14),
            Text('Syncing with nearest station…',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DispatchedDialog extends StatelessWidget {
  const _DispatchedDialog({
    required this.fuel,
    required this.qty,
    required this.total,
    required this.vehicle,
  });
  final FuelType fuel;
  final int qty;
  final int total;
  final DeliveryVehicle vehicle;

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
            const SuccessLogoBurst(size: 88, tint: _orange),
            const SizedBox(height: 6),
            const Text(
              'Dispatched',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$qty ${fuel.unitLabel} ${fuel.code} via ${vehicle.label} · paid direct to station',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slateLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Charged',
                          style: TextStyle(color: AppColors.slate, fontSize: 12)),
                      Text(
                        _money.format(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: _orangeDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Settlement',
                          style: TextStyle(color: AppColors.slate, fontSize: 12)),
                      Text('Direct to station · escrow bypass',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _orangeDark,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Track dispatch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
