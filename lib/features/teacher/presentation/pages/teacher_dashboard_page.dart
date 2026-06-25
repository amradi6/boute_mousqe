import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/teacher_cubit.dart';
import '../cubit/teacher_state.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TeacherCubit>()..loadDashboard(),
      child: const _TeacherDashboardView(),
    );
  }
}

class _TeacherDashboardView extends StatelessWidget {
  const _TeacherDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<TeacherCubit, TeacherState>(
        builder: (context, state) {
          if (state is TeacherLoading) {
            return const LoadingWidget(message: AppStrings.loading);
          }
          if (state is TeacherError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<TeacherCubit>().loadDashboard(),
            );
          }

          final data = state is TeacherLoaded ? state.dashboard : <String, dynamic>{};
          final studentCount = data['studentCount'] as int? ?? 0;
          final groups = (data['groups'] as List?) ?? [];
          final todayLessons = (data['todayLessons'] as List?) ?? [];
          final recentEvals = (data['recentEvaluations'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: AppStrings.totalStudents,
                            value: '$studentCount',
                            icon: Icons.people_outline_rounded,
                            color: AppColors.primary,
                          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'الحلقات النشطة',
                            value: '${groups.length}',
                            icon: Icons.groups_2_outlined,
                            color: AppColors.primaryVariant,
                          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (todayLessons.isNotEmpty) ...[
                      Text(
                        AppStrings.todaySchedule,
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ).animate(delay: 200.ms).fadeIn(),
                      const SizedBox(height: 12),
                      ...todayLessons.map((lesson) => _LessonCard(lesson: lesson as Map<String, dynamic>)
                          .animate(delay: 250.ms)
                          .fadeIn()
                          .slideY(begin: 0.2)),
                      const SizedBox(height: 20),
                    ],
                    Text(
                      'حلقاتي',
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ).animate(delay: 300.ms).fadeIn(),
                    const SizedBox(height: 12),
                    if (groups.isEmpty)
                      const AppEmptyWidget(
                        message: 'لا توجد حلقات مضافة بعد',
                        icon: Icons.groups_outlined,
                      )
                    else
                      ...groups.map((g) => _GroupCard(group: g as Map<String, dynamic>)
                          .animate(delay: 350.ms)
                          .fadeIn()
                          .slideY(begin: 0.2)),
                    if (recentEvals.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'آخر التقييمات',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ).animate(delay: 400.ms).fadeIn(),
                      const SizedBox(height: 12),
                      ...recentEvals.take(3).map((e) => _RecentEvalCard(eval: e as Map<String, dynamic>)
                          .animate(delay: 450.ms)
                          .fadeIn()
                          .slideY(begin: 0.2)),
                    ],
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher/attendance'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.how_to_reg_outlined),
        label: Text(AppStrings.markAttendance, style: AppTypography.labelLarge.copyWith(color: Colors.white)),
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
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final user = state is AuthAuthenticated ? state.user : null;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              user?.greeting ?? AppStrings.goodMorning,
                              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.fullName ?? '',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withAlpha(60),
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'م',
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
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(AppStrings.home, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/teacher/notifications'),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Map<String, dynamic> lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['title'] as String? ?? 'درس',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (lesson['halaqah_groups'] != null)
                  Text(
                    (lesson['halaqah_groups'] as Map)['name'] as String? ?? '',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${lesson['duration_minutes'] ?? 60} د',
              style: AppTypography.labelSmall.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryVariant.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups_2_outlined, color: AppColors.primaryVariant, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group['name'] as String? ?? 'حلقة',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (group['location'] != null)
                  Text(
                    group['location'] as String,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/teacher/attendance'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(AppStrings.attendance, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _RecentEvalCard extends StatelessWidget {
  final Map<String, dynamic> eval;
  const _RecentEvalCard({required this.eval});

  @override
  Widget build(BuildContext context) {
    final student = (eval['students'] as Map?)?.cast<String, dynamic>();
    final profile = (student?['profiles'] as Map?)?.cast<String, dynamic>();
    final score = (eval['score'] as num?)?.toInt() ?? 0;
    final maxScore = (eval['max_score'] as num?)?.toInt() ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryVariant.withAlpha(40),
            child: Text(
              profile?['full_name']?.toString().isNotEmpty == true
                  ? (profile!['full_name'] as String)[0]
                  : 'ط',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?['full_name'] as String? ?? 'طالبة',
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  eval['type'] as String? ?? '',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '$score/$maxScore',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
