import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netframes/core/api/movie_api_service.dart';
import 'package:netframes/core/services/theme_service.dart';
import 'package:netframes/features/home/data/providers/netflix_mirror_provider.dart';
import 'package:netframes/features/home/presentation/bloc/home_bloc.dart';
import 'package:netframes/features/home/presentation/bloc/home_event.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_bloc.dart';
import 'package:netframes/features/settings/presentation/bloc/theme_state.dart';
import 'package:netframes/features/shell/presentation/pages/shell_page.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_bloc.dart';
import 'package:netframes/features/tv_shows/presentation/bloc/tv_shows_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Create a single instance of the provider
  final netflixMirrorProvider = NetflixMirrorProvider();
  // Pre-fetch the cookie at startup
  await netflixMirrorProvider.bypass();

  runApp(MyApp(netflixMirrorProvider: netflixMirrorProvider));
}

class MyApp extends StatelessWidget {
  final NetflixMirrorProvider netflixMirrorProvider;

  const MyApp({super.key, required this.netflixMirrorProvider});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeBloc(
            movieApiService: MovieApiService(),
            netflixMirrorProvider: netflixMirrorProvider, // Use the single instance
          )..add(const FetchHomeData('Netflix')),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(themeService: ThemeService()),
        ),
        BlocProvider(
          create: (context) => TvShowsBloc(
            movieApiService: MovieApiService(),
          )..add(FetchTvShowsData()),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Netframes',
            themeMode: themeState.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: themeState.accentColor),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF121212),
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeState.accentColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const ShellPage(),
          );
        },
      ),
    );
  }
}