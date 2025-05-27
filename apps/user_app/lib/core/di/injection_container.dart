import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:domain/domain.dart';
import '../api/api_client.dart';
import '../../features/auth/presentation/bloc/user_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Core
  sl.registerLazySingleton(() => ApiClient(sl()));

  // Blocs
  sl.registerFactory(
    () => UserBloc(sl()),
  );
  // Register AuthBloc
  sl.registerFactory(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
} 