import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/supabase_config.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/lookup_user_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/student/presentation/cubit/student_cubit.dart';
import '../../features/teacher/presentation/cubit/teacher_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External: Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );

  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ─── Auth ───
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => LookupUserByNameUseCase(sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SetFirstPasswordUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      lookupByName: sl(),
      signIn: sl(),
      setFirstPassword: sl(),
      signOut: sl(),
      authRepository: sl(),
    ),
  );

  // ─── Student ───
  sl.registerFactory(() => StudentCubit(sl()));

  // ─── Teacher ───
  sl.registerFactory(() => TeacherCubit(sl()));
}
