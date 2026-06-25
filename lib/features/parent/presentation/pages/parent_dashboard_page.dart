import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart' as app_auth;

class ParentDashboardPage extends StatefulWidget {
  const ParentDashboardPage({super.key});

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _children = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  String? get _entityId =>
      Supabase.instance.client.auth.currentUser?.userMetadata?['entity_id'] as String?;

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entityId = _entityId;
      if (entityId == null) throw Exception('المستخدم غير موجود');

      final data = await Supabase.instance.client
          .from('guardian_students')
          .select('students(id, name, group_id, halaqah_groups(name))')
          .eq('guardian_id', entityId);

      final children = (data as List).map((d) {
        final student = (d['students'] as Map).cast<String, dynamic>();
        final group = student['halaqah_groups'] as Map?;
        return {
          'id': student['id'],
          'name': student['name'] as String? ?? 'الابنة',
          'avatarUrl': null,
          'halaqahName': group?['name'] as String? ?? 'غير محددة',
        };
      }).toList();

      setState(() {
        _children = children;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                if (_loading) const LoadingWidget(),
                if (_error != null)
                  AppErrorWidget(message: _error!, onRetry: _loadChildren),
                if (!_loading && _error == null) ...[
                  Text(
                    AppStrings.children,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  if (_children.isEmpty)
                    const AppEmptyWidget(
                      message: 'لا يوجد أبناء مرتبطون بحسابك',
                      icon: Icons.family_restroom_outlined,
                    )
                  else
                    ..._children.map((child) => _ChildCard(child: child, index: _children.indexOf(child))
                        .animate(delay: Duration(milliseconds: 100 * _children.indexOf(child)))
                        .fadeIn()
                        .slideY(begin: 0.2)),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: BlocBuilder<AuthCubit, app_auth.AuthState>(
                builder: (context, state) {
                  final user = state is app_auth.AuthAuthenticated ? state.user : null;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(user?.greeting ?? AppStrings.goodMorning,
                                style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(user?.fullName ?? '',
                                style: AppTypography.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withAlpha(60),
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'و',
                          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        title: Text(AppStrings.home, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/parent/notifications'),
        ),
      ],
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final int index;

  const _ChildCard({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryVariant.withAlpha(40),
                child: Text(
                  (child['name'] as String).isNotEmpty ? (child['name'] as String)[0] : 'ط',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child['name'] as String,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'الحلقة: ${child['halaqahName']}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_today_outlined,
                  label: AppStrings.attendance,
                  onTap: () => context.push('/parent/attendance/${child['id']}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.star_outline_rounded,
                  label: AppStrings.evaluation,
                  onTap: () => context.push('/parent/evaluation/${child['id']}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.message_outlined,
                  label: 'تواصل',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
