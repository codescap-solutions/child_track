import 'package:child_track/app/childapp/view_model/repository/child_location_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/child_repo.dart';
import 'package:child_track/app/home/view_model/home_repo.dart';
import 'package:child_track/app/childapp/view_model/repository/device_info_service.dart';
import 'package:child_track/core/services/connectivity/bloc/connectivity_bloc.dart';
import 'package:child_track/core/services/firebase_notification_service.dart';
import 'package:child_track/core/services/socket_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dio_client.dart';
import '../services/shared_prefs_service.dart';
import '../../app/auth/view_model/auth_repository.dart';
import '../../app/auth/view_model/bloc/auth_bloc.dart';
import '../../app/home/view_model/bloc/homepage_bloc.dart';
import '../../app/map/view_model/map_bloc.dart';
import '../../app/childapp/view_model/bloc/child_bloc.dart';
import '../../app/addplace/service/saved_places_service.dart';

final GetIt injector = GetIt.instance;

Future<void> initializeDependencies() async {
  // Initialize SharedPreferences
  await SharedPrefsService.init();

  // Register SharedPreferences
  injector.registerSingleton<SharedPreferences>(SharedPrefsService.prefs);

  // Register SharedPrefsService
  injector.registerSingleton<SharedPrefsService>(SharedPrefsService());

  // Register Connectivity (required by ConnectivityBloc)
  injector.registerLazySingleton<Connectivity>(() => Connectivity());

  // Register ConnectivityBloc (required by DioClient)
  injector.registerLazySingleton<ConnectivityBloc>(
    () => ConnectivityBloc(connectivity: injector<Connectivity>()),
  );

  // Register DioClient (requires ConnectivityBloc)
  injector.registerSingleton<DioClient>(
    DioClient(connectivityBloc: injector<ConnectivityBloc>()),
  );

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

  injector.registerLazySingleton<ChildRepo>(
    () => ChildRepo(
      dioClient: injector<DioClient>(),
      sharedPrefsService: injector<SharedPrefsService>(),
    ),
  );
  injector.registerLazySingleton<ChildInfoService>(() => ChildInfoService());

  injector.registerLazySingleton<ChildGoogleMapsRepo>(
    () => ChildGoogleMapsRepo(),
  );

  injector.registerLazySingleton<SavedPlacesService>(
    () => SavedPlacesService(),
  );

  injector.registerLazySingleton<SocketService>(() => SocketService());

  // Register blocs
  injector.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      authRepository: injector<AuthRepository>(),
      sharedPrefsService: injector<SharedPrefsService>(),
    ),
  );
  injector.registerLazySingleton<MapBloc>(() => MapBloc());
  injector.registerLazySingleton<HomepageBloc>(
    () => HomepageBloc(
      homeRepository: injector<HomeRepository>(),
      mapBloc: injector<MapBloc>(),
      sharedPrefsService: injector<SharedPrefsService>(),
      socketService: injector<SocketService>(),
    ),
  );
  injector.registerLazySingleton<ChildBloc>(
    () => ChildBloc(
      sharedPrefsService: injector<SharedPrefsService>(),
      deviceInfoService: injector<ChildInfoService>(),
      childRepo: injector<ChildRepo>(),
      childLocationRepo: injector<ChildGoogleMapsRepo>(),
    ),
  );

  // Register Firebase Notification Service
  injector.registerLazySingleton<FirebaseNotificationService>(
    () => FirebaseNotificationService(),
  );
}
