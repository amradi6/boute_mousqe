import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      _navigateByRole(authState);
    } else {
      context.go('/login');
    }
  }

  void _navigateByRole(AuthAuthenticated state) {
    switch (state.user.role) {
      case UserRole.teacher:
        context.go('/teacher');
      case UserRole.parent:
        context.go('/parent');
      case UserRole.student:
        context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _navigateByRole(state);
        } else if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _AppLogo()
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.6, 0.6), duration: 800.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'مسار العلم',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Text(
                'سكينة في كل خطوة',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                )
                    .animate(delay: 1000.ms)
                    .fadeIn(duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}
