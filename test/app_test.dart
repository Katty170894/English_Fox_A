import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:english_fox/main.dart';
import 'package:english_fox/word_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in <String, String>{
      'Nunito': 'assets/fonts/Nunito.ttf',
      'Roboto':
          '../.build-tools/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
      'MaterialIcons':
          '../.build-tools/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      'Segoe UI Emoji': 'C:/Windows/Fonts/seguiemj.ttf',
    }.entries) {
      if (!File(entry.value).existsSync()) continue;
      final loader = FontLoader(entry.key)
        ..addFont(File(entry.value)
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (_) async => 1);
  });
  void phone(WidgetTester t, {double width = 390, double height = 844}) {
    t.view.physicalSize = Size(width, height);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      for (final p in [
        'assets/welcome-fox.png',
        'assets/animals-atlas.png',
        'assets/food-atlas.png',
        'assets/adventure-map.png',
        'assets/great-job.png'
      ]) {
        await precacheImage(
            AssetImage(p), tester.element(find.byType(MaterialApp)));
      }
    });
    await tester.pumpAndSettle();
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/previews').createSync(recursive: true);
      File('build/previews/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('All curriculum words have offline pictures', () {
    for (final word in allMissions.expand((m) => m.words).toSet()) {
      expect(WordPicture.supports(word), isTrue, reason: word);
    }
    for (final path in wordAssets.values.toSet()) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
  test('Profile migration preserves progress; rewards and purchases persist',
      () async {
    SharedPreferences.setMockInitialValues({
      'name': 'Explorer',
      'done': ['1'],
      'completed': 1,
      'unlocked': 2,
      'stars': 3,
      'coins': 25
    });
    final game = GameState();
    await game.load();
    await game.updateProfile('Emma', 8, 'cat');
    expect(game.done, {1});
    expect(game.coins, 25);
    expect(await game.buyOrEquip(0), isFalse);
    expect(game.coins, 25);
    final replay = await game.finish(allMissions[0], 100);
    expect(replay.coins, 0);
    expect(game.coins, 25);
    final reward = await game.finish(allMissions[1], 100);
    expect(reward.stars, 3);
    expect(game.unlocked, 3);
    expect(await game.buyOrEquip(0), isTrue);
    expect(game.coins, 10);
    expect(await game.buyOrEquip(0), isTrue);
    expect(game.coins, 10);
    final restored = GameState();
    await restored.load();
    expect(restored.name, 'Emma');
    expect(restored.age, 8);
    expect(restored.avatar, 'cat');
    expect(restored.profileReady, isTrue);
    expect(restored.done, {1, 2});
    expect(restored.equipped, 0);
    expect(restored.coins, 10);
  });
  testWidgets('Onboarding, profile validation, avatar and menu persist',
      (tester) async {
    phone(tester);
    await tester.pumpWidget(
        const RepaintBoundary(key: Key('capture'), child: EnglishFoxApp()));
    await tester.pumpAndSettle();
    await screenshot(tester, '01-welcome');
    await tester.tap(find.byKey(const Key('start-adventure')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('profile-name')), 'Emma');
    await tester.tap(find.byKey(const Key('age-8')));
    await tester.tap(find.byKey(const Key('avatar-cat')));
    await tester.pumpAndSettle();
    await screenshot(tester, '02-profile-setup');
    await tester.ensureVisible(find.byKey(const Key('save-profile')));
    await tester.tap(find.byKey(const Key('save-profile')));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await screenshot(tester, '03-map');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Emma'), findsOneWidget);
    expect(find.textContaining('Age 8'), findsOneWidget);
    await screenshot(tester, '07-dashboard');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('avatar'), 'cat');
    expect(prefs.getInt('age'), 8);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const EnglishFoxApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-adventure')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetup), findsNothing);
    expect(find.byType(Dashboard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Learn illustrated words, finish quiz and unlock the next lesson',
      (tester) async {
    phone(tester);
    SharedPreferences.setMockInitialValues(
        {'profileReady': true, 'name': 'Emma', 'age': 7, 'avatar': 'fox'});
    await tester.pumpWidget(
        const RepaintBoundary(key: Key('capture'), child: EnglishFoxApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start-adventure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-1')));
    await tester.pumpAndSettle();
    await screenshot(tester, '04-lessons');
    await tester.tap(find.byKey(const Key('mission-1')));
    await tester.pumpAndSettle();
    await screenshot(tester, '05-learn-word');
    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.byKey(const Key('lesson-next')));
      await tester.tap(find.byKey(const Key('lesson-next')));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 5; i++) {
      final word = tester
          .widget<WordPicture>(find.byKey(const Key('prompt-picture')))
          .word;
      await tester.ensureVisible(find.byKey(Key('answer-$word')));
      await tester.tap(find.byKey(Key('answer-$word')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('lesson-next')));
      await tester.tap(find.byKey(const Key('lesson-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(RewardScreen), findsOneWidget);
    expect(find.text('100% correct'), findsOneWidget);
    expect(find.text('⭐ +3'), findsOneWidget);
    expect(find.text('🪙 +25'), findsOneWidget);
    await screenshot(tester, '06-great-job');
    await tester.ensureVisible(find.byKey(const Key('reward-continue')));
    await tester.tap(find.byKey(const Key('reward-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mission-2')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coins'), 25);
    expect(prefs.getInt('unlocked'), 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Small screen profile and shop fit without overflow',
      (tester) async {
    phone(tester, width: 320, height: 640);
    await tester.pumpWidget(
        MaterialApp(home: ProfileSetup(onSave: (_, __, ___) async {})));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final game = GameState();
    await game.load();
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: ShopPage(game: game))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Welcome remains usable in landscape', (tester) async {
    phone(tester, width: 640, height: 360);
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen(onStart: () {})));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('start-adventure')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('Shop: accessories, colours and the happy fox', () {
    int idx(String name) => shopItems.indexWhere((e) => e.name == name);
    void mockAudio() {
      for (final name in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(name), (_) async => 1);
      }
    }

    test('old hats keep their saved ids and prices', () {
      expect(shopItems[0].name, 'Explorer hat');
      expect(shopItems[0].price, 40);
      expect(shopItems[1].price, 30);
      expect(shopItems[2].price, 100);
      expect(shopItems[3].name, 'Magic hat');
      expect(shopItems[3].price, 70);
      for (var i = 0; i < 4; i++) {
        expect(shopItems[i].slot, ShopSlot.hat);
      }
    });

    test('fur colours cost 200, eye colours 300, everything else less', () {
      for (final item in shopItems) {
        if (item.slot == ShopSlot.fur) {
          expect(item.price, 200, reason: item.name);
        } else if (item.slot == ShopSlot.eyes) {
          expect(item.price, 300, reason: item.name);
        } else {
          expect(item.price, lessThan(200), reason: item.name);
        }
      }
      expect(shopItems.where((e) => e.slot == ShopSlot.glasses), isNotEmpty);
      expect(shopItems.where((e) => e.slot == ShopSlot.scarf), isNotEmpty);
    });

    test('items from different slots are worn together; same slot replaces',
        () async {
      SharedPreferences.setMockInitialValues({'coins': 1000});
      final game = GameState();
      await game.load();
      expect(await game.buyOrEquip(idx('Explorer hat')), isTrue);
      expect(await game.buyOrEquip(idx('Magic hat')), isTrue);
      expect(game.worn[ShopSlot.hat], idx('Magic hat'));
      expect(game.owned, contains(idx('Explorer hat')));
      expect(await game.buyOrEquip(idx('Cool shades')), isTrue);
      expect(await game.buyOrEquip(idx('Rainbow scarf')), isTrue);
      expect(await game.buyOrEquip(idx('Blue fur')), isTrue);
      expect(await game.buyOrEquip(idx('Green eyes')), isTrue);
      expect(game.coins, 1000 - 40 - 70 - 50 - 90 - 200 - 300);
      final look = game.look;
      expect(look.hat?.name, 'Magic hat');
      expect(look.glasses?.name, 'Cool shades');
      expect(look.scarf?.name, 'Rainbow scarf');
      expect(look.fur?.style, 'blue');
      expect(look.eyes?.style, 'green');

      final restored = GameState();
      await restored.load();
      expect(restored.worn, game.worn);
      expect(restored.coins, game.coins);

      await restored.takeOff(ShopSlot.glasses);
      expect(restored.look.glasses, isNull);
      expect(restored.owned, contains(idx('Cool shades')));
      final again = GameState();
      await again.load();
      expect(again.look.glasses, isNull);
      expect(again.look.hat?.name, 'Magic hat');
    });

    test('cannot buy a colour without enough coins', () async {
      SharedPreferences.setMockInitialValues({'coins': 199});
      final game = GameState();
      await game.load();
      expect(await game.buyOrEquip(idx('Pink fur')), isFalse);
      expect(await game.buyOrEquip(idx('Pink eyes')), isFalse);
      expect(game.coins, 199);
      expect(game.look.fur, isNull);
      game.coins = 200;
      expect(await game.buyOrEquip(idx('Pink fur')), isTrue);
      expect(game.coins, 0);
      expect(await game.buyOrEquip(idx('Pink eyes')), isFalse);
    });

    test('every animal has a baked picture for every colour', () {
      for (final animal in avatarNames) {
        for (final item in shopItems) {
          if (item.slot == ShopSlot.fur) {
            expect(File('assets/pets/${animal}_fur_${item.style}.png').existsSync(),
                isTrue, reason: '$animal ${item.name}');
          } else if (item.slot == ShopSlot.eyes) {
            expect(File('assets/pets/${animal}_eyes_${item.style}.png').existsSync(),
                isTrue, reason: '$animal ${item.name}');
          }
        }
      }
    });

    test('a save from before the shop grew still loads its hat', () async {
      SharedPreferences.setMockInitialValues({
        'owned': ['0', '3'],
        'equipped': 3,
        'coins': 5
      });
      final game = GameState();
      await game.load();
      expect(game.equipped, 3);
      expect(game.look.hat?.name, 'Magic hat');
    });

    for (final size in [const Size(320, 640), const Size(390, 844)]) {
      testWidgets('every shop tab fits at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        mockAudio();
        phone(tester, width: size.width, height: size.height);
        SharedPreferences.setMockInitialValues({'coins': 50});
        final game = GameState();
        await game.load();
        await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: ShopPage(game: game))));
        await tester.pumpAndSettle();
        for (final slot in ShopSlot.values) {
          await tester.tap(find.byKey(Key('tab-${slot.name}')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: slot.name);
        }
      });
    }

    testWidgets('buying shows the fox hopping for joy, then settles',
        (tester) async {
      mockAudio();
      phone(tester);
      SharedPreferences.setMockInitialValues({'coins': 500});
      final game = GameState();
      await game.load();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: ShopPage(game: game))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tab-glasses')));
      await tester.pumpAndSettle();
      final shades = idx('Cool shades');
      await tester.tap(find.byKey(Key('buy-$shades')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Take off'), findsOneWidget);
      // let the animation, speech bubble and delayed sounds all finish
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(game.worn[ShopSlot.glasses], shades);
      expect(game.coins, 450);
      expect(tester.takeException(), isNull);

      // tapping it again takes the glasses off
      await tester.tap(find.byKey(Key('buy-$shades')));
      await tester.pumpAndSettle();
      expect(game.look.glasses, isNull);
      expect(find.text('Wear'), findsOneWidget);
    });

    testWidgets('not enough coins: fox shakes its head and a hint appears',
        (tester) async {
      mockAudio();
      phone(tester);
      SharedPreferences.setMockInitialValues({'coins': 10});
      final game = GameState();
      await game.load();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: ShopPage(game: game))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('buy-${idx('Explorer hat')}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Keep learning to earn more coins!'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(game.coins, 10);
      expect(game.owned, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final animal in avatarNames) {
      testWidgets('$animal can buy and wear fur and eye colours, hats and scarves',
          (tester) async {
        mockAudio();
        phone(tester);
        SharedPreferences.setMockInitialValues(
            {'coins': 900, 'avatar': animal});
        final game = GameState();
        await game.load();
        await tester.pumpWidget(
            MaterialApp(home: Scaffold(body: ShopPage(game: game))));
        await tester.pumpAndSettle();
        for (final entry in {
          'tab-hat': 'Magic hat',
          'tab-glasses': 'Heart glasses',
          'tab-scarf': 'Rainbow scarf',
          'tab-fur': 'Purple fur',
          'tab-eyes': 'Green eyes'
        }.entries) {
          await tester.tap(find.byKey(Key(entry.key)));
          await tester.pumpAndSettle();
          final button = find.byKey(Key('buy-${idx(entry.value)}'));
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pump();
          await tester.pump(const Duration(seconds: 3));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$animal ${entry.value}');
        }
        expect(game.worn.length, 5);
        expect(game.coins, 900 - 70 - 60 - 90 - 200 - 300);
      });
    }
  });
}
