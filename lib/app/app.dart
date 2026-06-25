import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection_container.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import 'router/app_router.dart';

class MasaarApp extends StatefulWidget {
  const MasaarApp({super.key});

  @override
  State<MasaarApp> createState() => _MasaarAppState();
}

class _MasaarAppState extends State<MasaarApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = sl<AuthCubit>();
    _router = createRouter(_authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'مسار العلم',
        theme: AppTheme.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [
          Locale('ar', 'SA'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
      ),
    );
  }
}
