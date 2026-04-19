import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'services/audio_playback_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark status bar / navigation bar for immersive feel
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initAudioPlaybackService();

  runApp(const ProviderScope(child: OshoApp()));
}

class OshoApp extends StatelessWidget {
  const OshoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NeumorphicTheme(
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkNeumorphicTheme,
      darkTheme: AppTheme.darkNeumorphicTheme,
      child: MaterialApp.router(
        title: 'Osho Discourses',
        themeMode: ThemeMode.dark,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
