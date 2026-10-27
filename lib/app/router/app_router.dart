import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/evaluation/presentation/pages/evaluation_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/parent/presentation/pages/parent_dashboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/teacher/presentation/pages/teacher_dashboard_page.dart';
import '../../shared/widgets/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _studentKey = GlobalKey<NavigatorState>();
final _teacherKey = GlobalKey<NavigatorState>();
final _parentKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthCubit authCubit) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        final authState = authCubit.state;
        final isAuth = authState is AuthAuthenticated;
        final location = state.uri.toString();

        // During startup or any operation, stay on the current page.
        // The splash page is already the initialLocation — no redirect needed.
        if (authState is AuthInitial || authState is AuthLoading) return null;

        if (location == '/splash' || location == '/login') {
          if (isAuth) return _roleHomePath(authState as AuthAuthenticated); // ignore: unnecessary_cast
          return null;
        }

        if (!isAuth) return '/login';

        final authed = authState as AuthAuthenticated; // ignore: unnecessary_cast
        final user = authed.user;
        if (location.startsWith('/student') && user.role != UserRole.student) {
          return _roleHomePath(authed);
        }
        if (location.startsWith('/teacher') && user.role != UserRole.teacher) {
          return _roleHomePath(authed);
        }
        if (location.startsWith('/parent') && user.role != UserRole.parent) {
          return _roleHomePath(authed);
        }

        return null;
      },
      refreshListenable: _GoRouterAuthNotifier(authCubit),
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, __) => const LoginPage()),

        ShellRoute(
          navigatorKey: _studentKey,
          builder: (context, state, child) => StudentShell(child: child),
          routes: [
            GoRoute(path: '/student', builder: (_, __) => const StudentDashboardPage()),
            GoRoute(path: '/student/attendance', builder: (_, __) => const AttendancePage()),
            GoRoute(path: '/student/evaluation', builder: (_, __) => const EvaluationPage()),
            GoRoute(path: '/student/notifications', builder: (_, __) => const NotificationsPage()),
            GoRoute(path: '/student/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),

        ShellRoute(
          navigatorKey: _teacherKey,
          builder: (context, state, child) => TeacherShell(child: child),
          routes: [
            GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardPage()),
            GoRoute(path: '/teacher/attendance', builder: (_, __) => const AttendancePage(isTeacher: true)),
            GoRoute(path: '/teacher/evaluation', builder: (_, __) => const EvaluationPage(isTeacher: true)),
            GoRoute(path: '/teacher/notifications', builder: (_, __) => const NotificationsPage()),
            GoRoute(path: '/teacher/profile', builder: (_, __) => const ProfilePage()),
          ],
        ),

        ShellRoute(
          navigatorKey: _parentKey,
          builder: (context, state, child) => ParentShell(child: child),
          routes: [
            GoRoute(path: '/parent', builder: (_, __) => const ParentDashboardPage()),
            GoRoute(path: '/parent/notifications', builder: (_, __) => const NotificationsPage()),
            GoRoute(path: '/parent/profile', builder: (_, __) => const ProfilePage()),
            GoRoute(
              path: '/parent/attendance/:studentId',
              builder: (_, state) => AttendancePage(
                studentId: state.pathParameters['studentId'],
              ),
            ),
            GoRoute(
              path: '/parent/evaluation/:studentId',
              builder: (_, state) => EvaluationPage(
                studentId: state.pathParameters['studentId'],
              ),
            ),
          ],
        ),
      ],
    );

String _roleHomePath(AuthAuthenticated state) => switch (state.user.role) {
      UserRole.teacher => '/teacher',
      UserRole.parent => '/parent',
      UserRole.student => '/student',
    };

class _GoRouterAuthNotifier extends ChangeNotifier {
  final AuthCubit _authCubit;

  _GoRouterAuthNotifier(this._authCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
  }
}
