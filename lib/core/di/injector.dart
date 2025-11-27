import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dio_client.dart';
import '../services/shared_prefs_service.dart';
import '../../app/auth/view_model/auth_repository.dart';
import '../../app/auth/view_model/bloc/auth_bloc.dart';
import '../../app/home/view_model/bloc/homepage_bloc.dart';
import '../../app/map/view_model/map_bloc.dart';
import '../../app/childapp/view_model/sos_bloc.dart';

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

  injector.registerLazySingleton<HomeRepository>(
    () => HomeRepository(dioClient: injector<DioClient>()),
  );

  // Register blocs
  injector.registerLazySingleton<AuthBloc>(() => AuthBloc());
  injector.registerLazySingleton<MapBloc>(() => MapBloc());
  injector.registerLazySingleton<HomepageBloc>(
    () => HomepageBloc(
      homeRepository: injector<HomeRepository>(),
      mapBloc: injector<MapBloc>(),
    ),
  );
  injector.registerLazySingleton<SosBloc>(() => SosBloc());
}
