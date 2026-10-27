import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white.withAlpha(60),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'م',
                            style: AppTypography.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.fullName ?? '',
                          style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user?.role.label ?? '',
                          style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _InfoCard(user: user),
                    const SizedBox(height: 16),
                    _SettingsSection(context: context),
                    const SizedBox(height: 40),
                    TextButton.icon(
                      onPressed: () => _confirmSignOut(context),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: Text(AppStrings.logout, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنتِ متأكدة من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              context.go('/login');
            },
            child: Text(AppStrings.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserEntity? user;
  const _InfoCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.phone_outlined, label: AppStrings.phone, value: user?.phone ?? 'غير محدد'),
          const Divider(color: AppColors.divider),
          _InfoRow(icon: Icons.badge_outlined, label: 'الدور', value: user?.role.label ?? '-'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final BuildContext context;
  const _SettingsSection({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _SettingTile(icon: Icons.notifications_outlined, title: 'الإشعارات', onTap: () {}),
          const Divider(color: AppColors.divider, height: 1),
          _SettingTile(icon: Icons.lock_outlined, title: 'تغيير كلمة المرور', onTap: () {}),
          const Divider(color: AppColors.divider, height: 1),
          _SettingTile(icon: Icons.info_outline, title: 'حول التطبيق', onTap: () {}),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTypography.bodyMedium),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
