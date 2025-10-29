import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dio_client.dart';
import '../services/shared_prefs_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';

final GetIt injector = GetIt.instance;

Future<void> initializeDependencies() async {
  // Initialize SharedPreferences
  await SharedPrefsService.init();

  // Register SharedPreferences
  injector.registerSingleton<SharedPreferences>(SharedPrefsService.prefs);

  // Register SharedPrefsService
  injector.registerSingleton<SharedPrefsService>(SharedPrefsService());

  // Register DioClient
  injector.registerSingleton<DioClient>(DioClient());

  // Register Repositories
  injector.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      dioClient: injector<DioClient>(),
      sharedPrefsService: injector<SharedPrefsService>(),
    ),
  );

  // Register ViewModels
  injector.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(authRepository: injector<AuthRepository>()),
  );
}
