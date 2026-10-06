import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'game_state.dart';
import 'app_ui.dart';
export 'curriculum.dart';
export 'game_state.dart';
export 'app_ui.dart';
export 'fox_look.dart';
export 'fox_stage.dart';
export 'pictures.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EnglishFoxApp());
}

class EnglishFoxApp extends StatefulWidget {
  const EnglishFoxApp({super.key});
  @override
  State<EnglishFoxApp> createState() => _EnglishFoxAppState();
}

class _EnglishFoxAppState extends State<EnglishFoxApp> {
  final game = GameState();
  final tts = FlutterTts();
  bool started = false;
  @override
  void initState() {
    super.initState();
    game.load();
    tts.setLanguage('en-US');
    tts.setSpeechRate(.42);
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  @override
  void dispose() {
    tts.stop();
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: game,
      builder: (_, child) => MaterialApp(
            title: 'English Fox',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Nunito',
                fontFamilyFallback: const ['Segoe UI Emoji'],
                scaffoldBackgroundColor: cream,
                cardTheme: CardThemeData(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE8E5D8)))),
                colorScheme: ColorScheme.fromSeed(seedColor: blue)
                    .copyWith(primary: blue, secondary: leaf),
                textTheme: ThemeData.light().textTheme.apply(
                    fontFamily: 'Nunito', bodyColor: ink, displayColor: ink),
                appBarTheme: const AppBarTheme(
                    backgroundColor: cream,
                    foregroundColor: ink,
                    centerTitle: true,
                    elevation: 0),
                inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none)),
                filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Nunito'),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28))))),
            home: !game.loaded
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()))
                : !started
                    ? WelcomeScreen(
                        returning: game.profileReady,
                        onStart: () => setState(() => started = true))
                    : !game.profileReady
                        ? ProfileSetup(
                            initialName:
                                game.name == 'Explorer' ? '' : game.name,
                            initialAge: game.age,
                            initialAvatar: game.avatar,
                            onSave: game.updateProfile,
                            onBack: () => setState(() => started = false))
                        : Dashboard(game: game, speak: speak),
          ));
}
