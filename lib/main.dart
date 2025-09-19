import 'package:netframes/features/home/data/providers/m_player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/theme_service.dart';
import 'package:netframes/features/home/data/providers/dramadrip_provider.dart';
import 'package:netframes/features/home/data/providers/jio_hotstar_provider.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/data/providers/noxx_provider.dart';
import 'package:netframes/features/home/data/providers/prime_video_provider.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_bloc.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_state.dart';
import 'package:netframes/features/shell/presentation/pages/shell_page.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_bloc.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Create a single instance of the providers
  final netflixMirrorProvider = NetflixMirrorProvider();
  final jioHotstarProvider = JioHotstarProvider();
  final primeVideoProvider = PrimeVideoProvider();
  final dramaDripProvider = DramaDripProvider();
  final mPlayerProvider = MPlayerProvider();
  final noxxProvider = NoxxProvider();
  // Pre-fetch the cookies at startup
  await netflixMirrorProvider.bypass();
  await jioHotstarProvider.bypass();
  await primeVideoProvider.bypass();

  runApp(
    MyApp(
      netflixMirrorProvider: netflixMirrorProvider,
      jioHotstarProvider: jioHotstarProvider,
      primeVideoProvider: primeVideoProvider,
      dramaDripProvider: dramaDripProvider,
      mPlayerProvider: mPlayerProvider,
      noxxProvider: noxxProvider,
    ),
  );
}

class MyApp extends StatelessWidget {
  final NetflixMirrorProvider netflixMirrorProvider;
  final JioHotstarProvider jioHotstarProvider;
  final PrimeVideoProvider primeVideoProvider;
  final DramaDripProvider dramaDripProvider;
  final MPlayerProvider mPlayerProvider;
  final NoxxProvider noxxProvider;

  const MyApp({
    super.key,
    required this.netflixMirrorProvider,
    required this.jioHotstarProvider,
    required this.primeVideoProvider,
    required this.dramaDripProvider,
    required this.mPlayerProvider,
    required this.noxxProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(
            movieApiService: MovieApiService(),
            netflixMirrorProvider: netflixMirrorProvider,
            jioHotstarProvider: jioHotstarProvider,
            primeVideoProvider: primeVideoProvider,
            dramaDripProvider: dramaDripProvider,
            mPlayerProvider: mPlayerProvider,
            noxxProvider: noxxProvider,
          )..add(const FetchHomeData('Netflix')),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(themeService: ThemeService()),
        ),
        BlocProvider(
          create: (context) =>
              TvShowsBloc(movieApiService: MovieApiService())
                ..add(FetchTvShowsData()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Netframes',
            themeMode: themeState.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeState.accentColor,
              ),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android:
                      PredictiveBackPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeState.accentColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: <TargetPlatform, PageTransitionsBuilder>{
                  TargetPlatform.android:
                      PredictiveBackPageTransitionsBuilder(),
                },
              ),
            ),
            home: const ShellPage(),
          );
        },
      ),
    );
  }
}
