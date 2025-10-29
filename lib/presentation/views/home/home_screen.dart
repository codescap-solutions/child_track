import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/navigation/route_names.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/common_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth status when screen loads
    context.read<AuthBloc>().add(const CheckAuthStatusEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.surfaceColor,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.login,
              (route) => false,
            );
          } else if (state is AuthFailure) {
            AppSnackbar.showError(context, state.message);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: AppSizes.spacingXL),
              _buildQuickActions(),
              const SizedBox(height: AppSizes.spacingXL),
              _buildStatsCards(),
              const Spacer(),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: const Icon(
                    Icons.child_care,
                    size: 30,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.welcomeMessage,
                        style: AppTextStyles.headline5,
                      ),
                      const SizedBox(height: AppSizes.spacingXS),
                      Text(
                        'Track your child\'s safety and location',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headline6),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.location_on,
                title: 'Live Tracking',
                subtitle: 'View real-time location',
                onTap: () {
                  // TODO: Navigate to live tracking
                },
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: _buildActionCard(
                icon: Icons.school,
                title: 'Attendance',
                subtitle: 'Check attendance',
                onTap: () {
                  // TODO: Navigate to attendance
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.security,
                title: 'Safety Alerts',
                subtitle: 'View safety notifications',
                onTap: () {
                  // TODO: Navigate to safety alerts
                },
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: _buildActionCard(
                icon: Icons.settings,
                title: 'Settings',
                subtitle: 'App preferences',
                onTap: () {
                  // TODO: Navigate to settings
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 24),
              ),
              const SizedBox(height: AppSizes.spacingS),
              Text(
                title,
                style: AppTextStyles.subtitle2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spacingXS),
              Text(
                subtitle,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Summary', style: AppTextStyles.headline6),
        const SizedBox(height: AppSizes.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Location Updates',
                value: '12',
                icon: Icons.location_on,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: _buildStatCard(
                title: 'Safety Checks',
                value: '8',
                icon: Icons.security,
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const Spacer(),
                Text(
                  value,
                  style: AppTextStyles.headline4.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingS),
            Text(
              title,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return CommonButton(
          text: 'Logout',
          onPressed: _logout,
          isOutlined: true,
          isLoading: state is AuthLoading,
          width: double.infinity,
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
