import 'package:child_track/core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import '../view_model/bloc/subscription_bloc.dart';
import '../view_model/bloc/subscription_event.dart';
import '../view_model/bloc/subscription_state.dart';

class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubscriptionBloc()..add(const LoadOfferingsEvent()),
      child: const _SubscriptionBody(),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _SubscriptionBody extends StatelessWidget {
  const _SubscriptionBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) {
        if (state is SubscriptionSuccess) {
          _showSuccessDialog(context, state.customerInfo);
          // User cancelled native payment sheet — reload to dismiss the spinner
          context.read<SubscriptionBloc>().add(const LoadOfferingsEvent());
        } else if (state is SubscriptionError &&
            !state.isLoadError &&
            !state.isCancelled) {
          // Purchase failed — show snackbar; the builder keeps the plan UI
          AppSnackbar.showError(
            context,
            "Subscription failed. Please try again or contact support if the issue persists.",
          );
          context.read<SubscriptionBloc>().add(const LoadOfferingsEvent());
        }
        // isLoadError states are handled by the builder (_ErrorView with retry)
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          body: CustomScrollView(
            slivers: [
              _buildHeroAppBar(context, state),
              SliverToBoxAdapter(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  // ── Hero AppBar ─────────────────────────────────────────────────────────

  Widget _buildHeroAppBar(BuildContext context, SubscriptionState state) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(background: _HeroHeader()),
    );
  }

  // ── Main body ───────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, SubscriptionState state) {
    if (state is SubscriptionInitial || state is SubscriptionLoading) {
      return const _LoadingView();
    }

    // Only full-page error for offerings load failures
    if (state is SubscriptionError && state.isLoadError) {
      return _ErrorView(message: state.message);
    }

    if (state is SubscriptionLoaded) {
      return _PlanContent(loaded: state);
    }

    if (state is SubscriptionPurchasing || state is SubscriptionRestoring) {
      return const _BusyOverlay();
    }

    return const SizedBox.shrink();
  }

  // ── Success dialog ──────────────────────────────────────────────────────

  void _showSuccessDialog(BuildContext context, CustomerInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF03DAC6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to NaviQ Pro!',
              style: AppTextStyles.headline5,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your subscription is active. All premium features are now unlocked.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.of(context)
                  ..pop() // close dialog
                  ..pop(); // back to settings
              },
              child: Text('Get Started', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF2196F3), Color(0xFF03DAC6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Shield badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'NaviQ Pro',
                style: AppTextStyles.headline3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Protect your child with every premium feature',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan content ──────────────────────────────────────────────────────────────

class _PlanContent extends StatelessWidget {
  final SubscriptionLoaded loaded;
  const _PlanContent({required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        children: [
          // ── Tab row ──
          _PlanTabRow(selectedIndex: loaded.selectedIndex),
          const SizedBox(height: 20),

          // ── Price card ──
          _PriceCard(loaded: loaded),
          const SizedBox(height: 16),

          // ── CTA ──
          _SubscribeButton(loaded: loaded),
          const SizedBox(height: 8),

          // ── Restore ──
          TextButton(
            onPressed: () => context.read<SubscriptionBloc>().add(
              const RestorePurchasesEvent(),
            ),
            child: Text(
              'Restore Purchases',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Features table ──
          _FeaturesCard(selectedIndex: loaded.selectedIndex),
          const SizedBox(height: 12),

          // ── Legal ──
          Text(
            'Cancel anytime · Terms & Privacy Policy\nSubscriptions auto-renew unless cancelled.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Tab Row ───────────────────────────────────────────────────────────────────

class _PlanTabRow extends StatelessWidget {
  final int selectedIndex;
  const _PlanTabRow({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Monthly',
              index: 0,
              selected: selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Yearly',
              index: 1,
              selected: selectedIndex == 1,
              badge: 'SAVE 30%',
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final String? badge;
  const _Tab({
    required this.label,
    required this.index,
    required this.selected,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<SubscriptionBloc>().add(SelectPlanEvent(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
                )
              : null,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.subtitle2.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.overline.copyWith(
                    color: selected ? Colors.white : AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Price Card ────────────────────────────────────────────────────────────────

class _PriceCard extends StatelessWidget {
  final SubscriptionLoaded loaded;
  const _PriceCard({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final pkg = loaded.selectedPackage;
    final product = pkg?.storeProduct;

    final price = product?.priceString ?? '—';
    final period = loaded.selectedIndex == 0 ? 'per month' : 'per year';
    final perMonth = loaded.selectedIndex == 1 && product != null
        ? '≈ ${_estimatedMonthlyPrice(product.price)} / month'
        : null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(loaded.selectedIndex),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loaded.selectedIndex == 0 ? 'Monthly Plan' : 'Annual Plan',
              style: AppTextStyles.overline.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: AppTextStyles.headline2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              period,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            if (perMonth != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  perMonth,
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _estimatedMonthlyPrice(double yearlyPrice) {
    final monthly = yearlyPrice / 12;
    return '\$${monthly.toStringAsFixed(2)}';
  }
}

// ── Subscribe Button ──────────────────────────────────────────────────────────

class _SubscribeButton extends StatelessWidget {
  final SubscriptionLoaded loaded;
  const _SubscribeButton({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final pkg = loaded.selectedPackage;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: pkg == null
            ? null
            : () => context.read<SubscriptionBloc>().add(
                PurchasePackageEvent(pkg),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          disabledBackgroundColor: AppColors.borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          pkg == null ? 'Plan unavailable' : 'Subscribe Now',
          style: AppTextStyles.button.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}

// ── Features Card ─────────────────────────────────────────────────────────────

class _FeaturesCard extends StatelessWidget {
  final int selectedIndex;
  const _FeaturesCard({required this.selectedIndex});

  static const _features = [
    ('Real-time Location Tracking', true, true),
    ('Geofence Zones', true, true),
    ('SOS Emergency Alert', true, true),
    ('Battery & Network Monitor', true, true),
    ('App Usage Reports', true, true),
    ('Block 18+ Websites', true, true),
    ('Location History', false, true),
    ('Movement Alerts', false, true),
    ('Steps Tracker', false, true),
    ('Multi-Child Support', false, true),
    ('Priority Support', false, true),
    ('Social Media Usage Insights', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Feature',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _HeaderCell('Monthly', isSelected: selectedIndex == 0),
                const SizedBox(width: 16),
                _HeaderCell('Yearly', isSelected: selectedIndex == 1),
              ],
            ),
          ),
          // Rows
          ..._features.asMap().entries.map((entry) {
            final i = entry.key;
            final (name, monthly, yearly) = entry.value;
            final isLast = i == _features.length - 1;
            return _FeatureRow(
              name: name,
              monthlyIncluded: monthly,
              yearlyIncluded: yearly,
              selectedIndex: selectedIndex,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final bool isSelected;
  const _HeaderCell(this.text, {required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: isSelected ? AppColors.primaryColor : AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String name;
  final bool monthlyIncluded;
  final bool yearlyIncluded;
  final int selectedIndex;
  final bool showDivider;

  const _FeatureRow({
    required this.name,
    required this.monthlyIncluded,
    required this.yearlyIncluded,
    required this.selectedIndex,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final monthlyHighlight = selectedIndex == 0;
    final yearlyHighlight = selectedIndex == 1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(name, style: AppTextStyles.body2)),
              _CheckCell(
                included: monthlyIncluded,
                highlighted: monthlyHighlight,
              ),
              const SizedBox(width: 16),
              _CheckCell(
                included: yearlyIncluded,
                highlighted: yearlyHighlight,
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _CheckCell extends StatelessWidget {
  final bool included;
  final bool highlighted;
  const _CheckCell({required this.included, required this.highlighted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Icon(
        included ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 20,
        color: included
            ? (highlighted ? AppColors.primaryColor : const Color(0xFF81C784))
            : AppColors.textHint,
      ),
    );
  }
}

// ── Loading / Error / Busy views ──────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.wifi_off_rounded,
            size: 60,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load plans',
            style: AppTextStyles.headline6,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<SubscriptionBloc>().add(
              const LoadOfferingsEvent(),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 20),
            Text(
              'Processing payment…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
