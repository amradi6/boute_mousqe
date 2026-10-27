import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/user_entity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<AuthCubit>().resetToNameEntry();
        }
      },
      builder: (context, state) {
        final cubit = context.read<AuthCubit>();
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  _buildLogo().animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.8, 0.8),
                      ),
                  const SizedBox(height: 40),
                  if (state is AuthNeedsPassword)
                    _buildSetPasswordStep(context, cubit, state, isLoading)
                  else if (state is AuthNameFound)
                    _buildPasswordStep(context, cubit, state, isLoading)
                  else
                    _buildNameStep(context, cubit, isLoading),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameStep(BuildContext context, AuthCubit cubit, bool isLoading) {
    return Form(
      key: _nameFormKey,
      child: Column(
        children: [
          Text(
            AppStrings.login,
            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            'أدخلي اسمك للمتابعة',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 40),
          AppTextField(
            controller: _nameController,
            label: AppStrings.fullName,
            hint: AppStrings.namePlaceholder,
            prefixIcon: Icons.person_outline,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.fieldRequired;
              return null;
            },
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 32),
          AppButton(
            label: AppStrings.next,
            onPressed: isLoading
                ? null
                : () {
                    if (_nameFormKey.currentState?.validate() ?? false) {
                      cubit.lookupByName(_nameController.text);
                    }
                  },
            isLoading: isLoading,
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(
    BuildContext context,
    AuthCubit cubit,
    AuthNameFound state,
    bool isLoading,
  ) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          Text(
            AppStrings.welcomeBack,
            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          _buildRoleChip(state.role),
          const SizedBox(height: 4),
          Text(
            state.name,
            style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
          ).animate(delay: 50.ms).fadeIn(),
          const SizedBox(height: 40),
          AppTextField(
            controller: _passwordController,
            label: AppStrings.password,
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.fieldRequired;
              return null;
            },
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 24),
          AppButton(
            label: AppStrings.login,
            onPressed: isLoading
                ? null
                : () {
                    if (_passwordFormKey.currentState?.validate() ?? false) {
                      cubit.signIn(
                        name: state.name,
                        password: _passwordController.text,
                        entityType: state.entityType,
                        entityId: state.appUserId,
                      );
                    }
                  },
            isLoading: isLoading,
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () {
              _passwordController.clear();
              cubit.resetToNameEntry();
            },
            child: Text(
              AppStrings.backToName,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetPasswordStep(
    BuildContext context,
    AuthCubit cubit,
    AuthNeedsPassword state,
    bool isLoading,
  ) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          Text(
            AppStrings.createPassword,
            style: AppTypography.headlineSmall.copyWith(color: AppColors.primary),
          ).animate().fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 8),
          _buildRoleChip(state.role),
          const SizedBox(height: 4),
          Text(
            state.name,
            style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
          ).animate(delay: 50.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            AppStrings.createPasswordSubtitle,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 40),
          AppTextField(
            controller: _passwordController,
            label: AppStrings.newPassword,
            hint: '••••••••',
            obscureText: _obscurePassword,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.fieldRequired;
              if (v.length < 8) return AppStrings.passwordTooShort;
              return null;
            },
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 16),
          AppTextField(
            controller: _confirmController,
            label: AppStrings.confirmPassword,
            hint: '••••••••',
            obscureText: _obscureConfirm,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return AppStrings.fieldRequired;
              if (v != _passwordController.text) return AppStrings.passwordsMismatch;
              return null;
            },
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 32),
          AppButton(
            label: AppStrings.setPassword,
            onPressed: isLoading
                ? null
                : () {
                    if (_passwordFormKey.currentState?.validate() ?? false) {
                      cubit.setFirstPassword(
                        appUserId: state.appUserId,
                        entityType: state.entityType,
                        name: state.name,
                        password: _passwordController.text,
                        role: state.role,
                      );
                    }
                  },
            isLoading: isLoading,
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () {
              _passwordController.clear();
              _confirmController.clear();
              cubit.resetToNameEntry();
            },
            child: Text(
              AppStrings.backToName,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
      ),
    ).animate(delay: 30.ms).fadeIn();
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 12),
        Text(
          'مسار العلم',
          style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
