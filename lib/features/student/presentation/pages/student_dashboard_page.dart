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
import '../cubit/student_cubit.dart';
import '../cubit/student_state.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudentCubit>()..loadDashboard(),
      child: const _StudentDashboardView(),
    );
  }
}

class _StudentDashboardView extends StatelessWidget {
  const _StudentDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<StudentCubit, StudentState>(
        builder: (context, state) {
          if (state is StudentLoading) {
            return const LoadingWidget(message: AppStrings.loading);
          }
          if (state is StudentError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<StudentCubit>().loadDashboard(),
            );
          }
          final data = state is StudentLoaded ? state.dashboard : null;
          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    if (data?.halaqah != null) ...[
                      _HalaqahCard(halaqah: data!.halaqah!),
                      const SizedBox(height: 20),
                    ],
                    _buildStatsRow(context, data),
                    const SizedBox(height: 20),
                    if (data?.nextLesson != null) ...[
                      _NextLessonCard(lesson: data!.nextLesson!),
                      const SizedBox(height: 20),
                    ],
                    _buildSectionHeader(context, AppStrings.attendanceRate),
                    const SizedBox(height: 12),
                    _AttendanceProgressCard(
                      rate: data?.attendanceRate ?? 0,
                      attended: data?.attendedLessons ?? 0,
                      total: data?.totalLessons ?? 0,
                    ),
                    const SizedBox(height: 20),
                    if (data?.latestEvaluation != null) ...[
                      _buildSectionHeader(context, AppStrings.recentEvaluation),
                      const SizedBox(height: 12),
                      _EvaluationCard(eval: data!.latestEvaluation!),
                    ],
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
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
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
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
                              style: AppTypography.bodyMedium.copyWith(
                                color: Colors.white.withAlpha(200),
                              ),
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
                      GestureDetector(
                        onTap: () => context.push('/student/profile'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withAlpha(60),
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0]
                                : 'ط',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
        title: Text(
          AppStrings.home,
          style: AppTypography.titleMedium.copyWith(color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => context.push('/student/notifications'),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, dynamic data) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'الدروس المكتملة',
            value: '${data?.attendedLessons ?? 0}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'نسبة الحضور',
            value: '${(data?.attendanceRate ?? 0).toStringAsFixed(0)}%',
            icon: Icons.trending_up_rounded,
            color: AppColors.primary,
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HalaqahCard extends StatelessWidget {
  final dynamic halaqah;
  const _HalaqahCard({required this.halaqah});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_2_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.myHalaqah,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                Text(
                  halaqah.name ?? 'حلقتي',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (halaqah.teacherName != null)
                  Text(
                    'المعلمة: ${halaqah.teacherName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
              ],
            ),
          ),
          if (halaqah.scheduleDay != null)
            Column(
              children: [
                Text(
                  halaqah.scheduleDay ?? '',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white),
                ),
                Text(
                  halaqah.scheduleTime ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }
}

class _NextLessonCard extends StatelessWidget {
  final dynamic lesson;
  const _NextLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.nextLesson,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  lesson.title,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${lesson.durationMinutes} د',
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2);
  }
}

class _AttendanceProgressCard extends StatelessWidget {
  final double rate;
  final int attended;
  final int total;

  const _AttendanceProgressCard({
    required this.rate,
    required this.attended,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$attended ${AppStrings.of} $total درس',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                '${rate.toStringAsFixed(0)}%',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 80 ? AppColors.success : rate >= 60 ? AppColors.warning : AppColors.error,
              ),
              minHeight: 10,
            ),
          ),
        ],
      ),
    ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2);
  }
}

class _EvaluationCard extends StatelessWidget {
  final dynamic eval;
  const _EvaluationCard({required this.eval});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryVariant.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${eval.score.toInt()}',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.type.label,
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  eval.grade,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                ),
                if (eval.teacherName != null)
                  Text(
                    'المعلمة: ${eval.teacherName}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            '${eval.score.toInt()}/${eval.maxScore.toInt()}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2);
  }
}

