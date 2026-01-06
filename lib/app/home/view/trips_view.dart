import 'package:child_track/app/home/model/trip_list_model.dart';
import 'package:child_track/app/home/view_model/bloc/homepage_bloc.dart';
import 'package:child_track/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:child_track/core/constants/app_colors.dart';
import 'package:child_track/core/constants/app_sizes.dart';
import 'package:child_track/core/constants/app_text_styles.dart';
import 'package:child_track/core/widgets/common_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Trips List View - Shows all trips
class TripsView extends StatefulWidget {
  const TripsView({super.key});

  @override
  State<TripsView> createState() => _TripsViewState();
}

class _TripsViewState extends State<TripsView> {
  late HomepageBloc _homepageBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _homepageBloc = injector<HomepageBloc>();
    _homepageBloc.add(GetTrips(page: 1, pageSize: 10));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.addListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      // TODO: Implement pagination load more
      // _homepageBloc.add(GetTrips(page: nextPage, pageSize: 10));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Trips',
          style: AppTextStyles.headline5.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.surfaceColor,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: BlocBuilder<HomepageBloc, HomepageState>(
        bloc: _homepageBloc,
        builder: (context, state) {
          if (state is HomepageSuccess) {
            if (state.isLoadingTrips && state.trips.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.trips.isEmpty) {
              return const Center(child: Text("No trips found"));
            }

            return ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSizes.paddingL),
              itemCount: state.trips.length + (state.isLoadingTrips ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.trips.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trip = state.trips[index];
                return _SimpleTripCard(trip: trip);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// Simplified Trip Card for List View (No Map Data)
class _SimpleTripCard extends StatelessWidget {
  final Trip trip;

  const _SimpleTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spacingL),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: AppSizes.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.startTime} - ${trip.endTime}',
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${trip.distanceKm} km • ${trip.eventsCount} events',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CommonButton(
                padding: EdgeInsets.zero,
                width: 80,
                text: 'View',
                fontSize: 12,
                textColor: AppColors.surfaceColor,
                onPressed: () {
                  // Navigate to Detail View - will need to fetch detail inside there
                  // Note: TripDetailView currently expects TripSegment.
                  // This part might need adjustment if TripDetailView isn't updated.
                  // As per current task scope, we are focusing on TripsView listing.
                },
                height: 30,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingM),
          // Route info
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.fromPlace,
                  style: AppTextStyles.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 3.5),
            height: 16,
            width: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.toPlace,
                  style: AppTextStyles.body2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
