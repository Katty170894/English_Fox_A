import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'curriculum.dart';
import 'fox_look.dart';
import 'fox_stage.dart';
import 'game_state.dart';
import 'pictures.dart';
import 'sound.dart';

const ink = Color(0xFF123C62),
    blue = Color(0xFF168EF3),
    cream = Color(0xFFFFFBF1),
    leaf = Color(0xFF47B932);

class SkyPanel extends StatelessWidget {
  final Widget child;
  const SkyPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF97DEFC), Color(0xFFF6FCED)])),
      child: child);
}

class Pill extends StatelessWidget {
  final String text;
  const Pill(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(22)),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)));
}

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;
  final bool returning;
  const WelcomeScreen(
      {super.key, required this.onStart, this.returning = false});
  Widget logo(String text, double size, Color color) =>
      Stack(alignment: Alignment.center, children: [
        Text(text,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                height: .95,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 9
                  ..color = Colors.white)),
        Text(text,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                height: .95,
                color: color))
      ]);
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/welcome-fox.png', fit: BoxFit.cover),
        SafeArea(
            child: LayoutBuilder(
                builder: (context, box) => Padding(
                    padding: const EdgeInsets.fromLTRB(26, 24, 26, 30),
                    child: Column(children: [
                      logo(
                          'English',
                          math.min(box.maxWidth * .17,
                              box.maxHeight < 500 ? 36 : 72),
                          ink),
                      logo(
                          'FOX',
                          math.min(box.maxWidth * .23,
                              box.maxHeight < 500 ? 48 : 92),
                          const Color(0xFFFF8B19)),
                      const SizedBox(height: 12),
                      const Text('Small steps —\nbig dreams!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                      const Spacer(),
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                  key: const Key('start-adventure'),
                                  onPressed: onStart,
                                  style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD755),
                                      foregroundColor: ink,
                                      minimumSize: const Size(0, 62),
                                      side: const BorderSide(
                                          color: Colors.white, width: 3),
                                      elevation: 5),
                                  label: Text(returning
                                      ? 'Continue Adventure'
                                      : 'Start Adventure'),
                                  icon: const Icon(
                                      Icons.arrow_forward_rounded)))),
                      const SizedBox(height: 8)
                    ]))))
      ]));
}

class ProfileSetup extends StatefulWidget {
  final String initialName, initialAvatar;
  final int initialAge;
  final Future<void> Function(String, int, String) onSave;
  final VoidCallback? onBack;
  final bool editing;
  const ProfileSetup(
      {super.key,
      this.initialName = '',
      this.initialAge = 7,
      this.initialAvatar = 'fox',
      required this.onSave,
      this.onBack,
      this.editing = false});
  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  late final TextEditingController name;
  late int age;
  late String avatar;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initialName);
    age = widget.initialAge.clamp(5, 9);
    avatar = widget.initialAvatar;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Please enter your name');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave(name.text.trim(), age, avatar);
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          error = 'Could not save. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SkyPanel(
          child: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: Column(children: [
                            Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton.filledTonal(
                                    onPressed: widget.onBack,
                                    icon:
                                        const Icon(Icons.arrow_back_rounded))),
                            Container(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                decoration: BoxDecoration(
                                    color: cream,
                                    borderRadius: BorderRadius.circular(42),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x15246080),
                                          blurRadius: 20,
                                          offset: Offset(0, 8))
                                    ]),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                          widget.editing
                                              ? 'Your little explorer'
                                              : "Let’s get started!",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 8),
                                      const Text(
                                          'Tell us about the little learner',
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 20),
                                      Center(
                                          child: FoxAvatar(
                                              character: avatar, size: 125)),
                                      const SizedBox(height: 20),
                                      TextField(
                                          key: const Key('profile-name'),
                                          controller: name,
                                          maxLength: 20,
                                          textCapitalization:
                                              TextCapitalization.words,
                                          onChanged: (_) {
                                            if (error != null)
                                              setState(() => error = null);
                                          },
                                          decoration: InputDecoration(
                                              labelText: 'Name',
                                              hintText: 'Your name',
                                              counterText: '',
                                              errorText: error,
                                              suffixIcon: const Icon(
                                                  Icons.edit_rounded))),
                                      const SizedBox(height: 22),
                                      const Text('Age',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        for (var value = 5; value <= 9; value++)
                                          Expanded(
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 3),
                                                  child: ChoiceChip(
                                                      key: Key('age-$value'),
                                                      label: Text('$value'),
                                                      selected: age == value,
                                                      showCheckmark: false,
                                                      onSelected: (_) =>
                                                          setState(() =>
                                                              age = value),
                                                      selectedColor: blue,
                                                      labelStyle: TextStyle(
                                                          color: age == value
                                                              ? Colors.white
                                                              : ink,
                                                          fontWeight:
                                                              FontWeight.w800),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 10))))
                                      ]),
                                      const SizedBox(height: 22),
                                      const Text('Choose a character',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 12),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: avatarNames
                                              .map((a) => Expanded(
                                                  child: FittedBox(
                                                      child: Semantics(
                                                          label: 'Choose $a',
                                                          selected: avatar == a,
                                                          button: true,
                                                          child: InkWell(
                                                              key: Key(
                                                                  'avatar-$a'),
                                                              onTap: () =>
                                                                  setState(() =>
                                                                      avatar =
                                                                          a),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                              child: Container(
                                                                  padding: const EdgeInsets.all(3),
                                                                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: avatar == a ? blue : Colors.transparent, width: 3)),
                                                                  child: FoxAvatar(character: a, size: 54)))))))
                                              .toList()),
                                      const SizedBox(height: 25),
                                      FilledButton(
                                          key: const Key('save-profile'),
                                          onPressed: saving ? null : submit,
                                          child: Text(saving
                                              ? 'Saving…'
                                              : widget.editing
                                                  ? 'Save profile'
                                                  : 'Continue')),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'Your profile stays on this device.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF687F8C)))
                                    ])),
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('🌿  🌼  🌿',
                                    style: TextStyle(fontSize: 28)))
                          ])))))));
}

class Dashboard extends StatefulWidget {
  final GameState game;
  final Future<void> Function(String) speak;
  const Dashboard({super.key, required this.game, required this.speak});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int tab = 0;
  void openWorld(World world) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WorldLessons(
                game: widget.game, world: world, speak: widget.speak)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.game,
      builder: (_, child) {
        final g = widget.game;
        return Scaffold(
            body: IndexedStack(index: tab, children: [
              AdventureMap(
                  game: g,
                  onWorld: openWorld,
                  onProfile: () => setState(() => tab = 3)),
              LessonsLibrary(game: g, onWorld: openWorld),
              ShopPage(game: g),
              ProfilePage(game: g)
            ]),
            bottomNavigationBar: NavigationBar(
                height: 72,
                selectedIndex: tab,
                onDestinationSelected: (value) => setState(() => tab = value),
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFDDF2FF),
                destinations: const [
                  NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: 'Map'),
                  NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: 'Lessons'),
                  NavigationDestination(
                      icon: Icon(Icons.shopping_bag_outlined),
                      selectedIcon: Icon(Icons.shopping_bag_rounded),
                      label: 'Shop'),
                  NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Profile')
                ]));
      });
}

class AdventureMap extends StatelessWidget {
  final GameState game;
  final void Function(World) onWorld;
  final VoidCallback onProfile;
  const AdventureMap(
      {super.key,
      required this.game,
      required this.onWorld,
      required this.onProfile});
  @override
  Widget build(BuildContext context) => SkyPanel(
      child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  InkWell(
                      onTap: onProfile,
                      child: FoxAvatar(
                          character: game.avatar,
                          size: 48,
                          look: game.look)),
                  const SizedBox(width: 7),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Level ${game.done.length ~/ 7 + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                            value: (game.done.length % 7) / 7,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(9))
                      ])),
                  const SizedBox(width: 10),
                  Pill('⭐ ${game.stars}'),
                  const SizedBox(width: 5),
                  Pill('🪙 ${game.coins}')
                ])),
            Expanded(
                child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                        child: SizedBox(
                            height: math.max(c.maxHeight, c.maxWidth * 1.42),
                            child: Stack(fit: StackFit.expand, children: [
                              Image.asset('assets/adventure-map.png',
                                  fit: BoxFit.cover),
                              ...List.generate(worlds.length, (i) {
                                const positions = [
                                  Offset(.23, .69),
                                  Offset(.24, .46),
                                  Offset(.75, .47),
                                  Offset(.23, .19),
                                  Offset(.52, .34),
                                  Offset(.77, .19)
                                ];
                                final w = worlds[i],
                                    open = game.unlocked >= w.missions.first.id;
                                return Align(
                                    alignment: Alignment(
                                        positions[i].dx * 2 - 1,
                                        positions[i].dy * 2 - 1),
                                    child: SizedBox(
                                        width: 135,
                                        child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                                key: Key('world-${w.id}'),
                                                onTap: () => onWorld(w),
                                                borderRadius:
                                                    BorderRadius.circular(22),
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                          width: 56,
                                                          height: 56,
                                                          decoration: BoxDecoration(
                                                              color: open
                                                                  ? const Color(
                                                                      0xFFFFD85B)
                                                                  : Colors.white.withValues(alpha: .9),
                                                              shape: BoxShape.circle,
                                                              border: Border.all(color: Colors.white, width: 3),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                    color: Colors
                                                                        .black26,
                                                                    blurRadius:
                                                                        8,
                                                                    offset:
                                                                        Offset(
                                                                            0,
                                                                            3))
                                                              ]),
                                                          child: Center(
                                                              child: Text(
                                                                  w.emoji,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          31)))),
                                                      Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 7),
                                                          decoration: BoxDecoration(
                                                              color: cream,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                              border: Border.all(
                                                                  color: const Color(0xFFE2C997)),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                    color: Colors
                                                                        .black12,
                                                                    blurRadius:
                                                                        4)
                                                              ]),
                                                          child: Text(
                                                              '${open ? '' : '🔒 '}${w.title}',
                                                              textAlign: TextAlign
                                                                  .center,
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900)))
                                                    ])))));
                              }),
                              Positioned(
                                  bottom: 16,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                          color: cream.withValues(alpha: .95),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(
                                          '${game.done.length} / 42 missions completed • Keep exploring!',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800))))
                            ])))))
          ])));
}

class LessonsLibrary extends StatelessWidget {
  final GameState game;
  final void Function(World) onWorld;
  const LessonsLibrary({super.key, required this.game, required this.onWorld});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Your lessons',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Little discoveries. Every single day.'),
        const SizedBox(height: 20),
        ...worlds.map((w) {
          final count =
              w.missions.where((m) => game.done.contains(m.id)).length;
          return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 14),
              child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Text(w.emoji, style: const TextStyle(fontSize: 36)),
                  title: Text(w.title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$count / 7 missions'),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                                value: count / 7,
                                borderRadius: BorderRadius.circular(8))
                          ])),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onWorld(w)));
        })
      ]));
}

class WorldLessons extends StatelessWidget {
  final GameState game;
  final World world;
  final Future<void> Function(String) speak;
  const WorldLessons(
      {super.key,
      required this.game,
      required this.world,
      required this.speak});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: game,
      builder: (_, child) => Scaffold(
          appBar: AppBar(
              title: Text(world.title,
                  style: const TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(padding: const EdgeInsets.all(18), children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                    height: 160,
                    color: const Color(0xFFD9F5EA),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset('assets/adventure-map.png',
                          fit: BoxFit.cover, alignment: Alignment.topCenter),
                      Container(color: Colors.white.withValues(alpha: .18)),
                      Align(
                          alignment: Alignment.center,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFF77CEF9),
                                            width: 3),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Color(0x33000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3))
                                        ]),
                                    child: ClipOval(
                                        child: WordPicture(
                                            world.missions.first.words.first,
                                            size: 85))),
                                const SizedBox(width: 14),
                                FoxAvatar(character: game.avatar, size: 100, look: game.look)
                              ]))
                    ]))),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(world.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            ...world.missions.map((m) {
              final open = m.id <= game.unlocked,
                  done = game.done.contains(m.id);
              return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: WordPicture(m.words.first,
                                size: 54,
                                colorMeaning: m.words.contains('red'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('${m.id}. ${m.title}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 5),
                              Text('${m.words.length} words',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF70828A))),
                              if (done)
                                const Text('⭐ Completed',
                                    style: TextStyle(fontSize: 12, color: leaf))
                            ])),
                        const SizedBox(width: 5),
                        open
                            ? FilledButton(
                                key: Key('mission-${m.id}'),
                                style: FilledButton.styleFrom(
                                    backgroundColor: leaf,
                                    minimumSize: const Size(64, 40),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12)),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => LessonScreen(
                                            game: game,
                                            mission: m,
                                            speak: speak))),
                                child: Text(done ? 'Replay' : 'Start',
                                    style: const TextStyle(fontSize: 13)))
                            : const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.lock_rounded,
                                    color: Color(0xFF9EACB3)))
                      ])));
            }),
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('⭐ Complete lessons to unlock the next adventure.',
                    textAlign: TextAlign.center))
          ])));
}

class ShopPage extends StatefulWidget {
  final GameState game;
  const ShopPage({super.key, required this.game});
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _stage = GlobalKey<HappyFoxStageState>();
  ShopSlot _tab = ShopSlot.hat;

  // Turned on by the first purchase, so items already worn when the shop
  // opens just appear, while newly bought ones drop / pop onto the fox.
  bool _animate = false;

  String _tabEmoji(ShopSlot s) => switch (s) {
        ShopSlot.hat => '🎩',
        ShopSlot.glasses => '🕶️',
        ShopSlot.scarf => '🧣',
        ShopSlot.fur => '🎨',
        ShopSlot.eyes => '👀'
      };
  String _tabLabel(ShopSlot s) => switch (s) {
        ShopSlot.hat => 'Hats',
        ShopSlot.glasses => 'Glasses',
        ShopSlot.scarf => 'Scarves',
        ShopSlot.fur => 'Fur',
        ShopSlot.eyes => 'Eyes'
      };
  String _tabTitle(ShopSlot s) => switch (s) {
        ShopSlot.hat => 'Hats & treasures',
        ShopSlot.glasses => 'Glasses',
        ShopSlot.scarf => 'Scarves',
        ShopSlot.fur => 'Fur colors',
        ShopSlot.eyes => 'Eye colors'
      };

  Future<void> _tap(int i) async {
    final game = widget.game;
    final item = shopItems[i];
    // Already wearing it: take it off again.
    if (game.worn[item.slot] == i) {
      await game.takeOff(item.slot);
      SoundService.instance.playOff();
      return;
    }
    final wasOwned = game.owned.contains(i);
    // Must be on before the purchase notifies, so the new item animates in.
    if (!_animate) setState(() => _animate = true);
    final ok = await game.buyOrEquip(i);
    if (!mounted) return;
    if (!ok) {
      _stage.currentState?.celebrate(FoxMood.nope);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keep learning to earn more coins!')));
      return;
    }
    if (wasOwned) {
      SoundService.instance.playWear();
      _stage.currentState?.celebrate(FoxMood.hop);
    } else {
      SoundService.instance.playBuyCelebration();
      _stage.currentState?.celebrate(FoxMood.joy);
    }
  }

  Widget _card(int i) {
    final game = widget.game;
    final item = shopItems[i];
    final owned = game.owned.contains(i);
    final selected = game.worn[item.slot] == i;
    final isColor = item.slot == ShopSlot.fur || item.slot == ShopSlot.eyes;
    return Card(
        color: Colors.white,
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                      height: 56,
                      child: Center(
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ItemArt(item, size: 52)))),
                  Text(item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(owned ? 'Owned' : '🪙 ${item.price}'),
                  FilledButton(
                      key: Key('buy-$i'),
                      onPressed: () => _tap(i),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          backgroundColor: selected
                              ? const Color(0xFFDDF2FF)
                              : const Color(0xFFFFC744),
                          foregroundColor: ink),
                      child: Text(selected
                          ? (isColor ? 'Original' : 'Take off')
                          : owned
                              ? 'Wear'
                              : 'Buy'))
                ])));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: AnimatedBuilder(
          animation: widget.game,
          builder: (context, _) {
            final game = widget.game;
            final items = <int>[
              for (var i = 0; i < shopItems.length; i++)
                if (shopItems[i].slot == _tab) i
            ];
            return LayoutBuilder(builder: (context, box) {
              // The fox stays pinned at the top so you always see it react;
              // on short screens it simply gets a little smaller.
              final foxSize = (box.maxHeight * .26).clamp(96.0, 200.0).toDouble();
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Row(children: [
                      const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('My Fox',
                                style: TextStyle(
                                    fontSize: 30, fontWeight: FontWeight.w900)),
                            Text('A little style for a big adventure')
                          ])),
                      Pill('🪙 ${game.coins}')
                    ])),
                HappyFoxStage(
                    key: _stage,
                    character: game.avatar,
                    look: game.look,
                    size: foxSize,
                    animateItems: _animate),
                SizedBox(
                    height: 44,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        children: [
                          for (final slot in ShopSlot.values)
                            Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                    key: Key('tab-${slot.name}'),
                                    label: Text(
                                        '${_tabEmoji(slot)} ${_tabLabel(slot)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    selected: _tab == slot,
                                    onSelected: (_) =>
                                        setState(() => _tab = slot)))
                        ])),
                Expanded(
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                        children: [
                      Text(_tabTitle(_tab),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .72,
                            children: [for (final i in items) _card(i)]),
                      const SizedBox(height: 18),
                      const Text(
                          'Earn coins by completing lessons.\nNo real-money purchases.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF71838A)))
                    ]))
              ]);
            });
          }));
}

class ProfilePage extends StatelessWidget {
  final GameState game;
  const ProfilePage({super.key, required this.game});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Parent Dashboard',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        Card(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  FoxAvatar(
                      character: game.avatar, size: 76, look: game.look),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(game.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        Text(
                            'Age ${game.age} • Level ${game.done.length ~/ 7 + 1}'),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                            value: game.done.length / 42,
                            borderRadius: BorderRadius.circular(8)),
                        const SizedBox(height: 5),
                        Text('${game.done.length}/42 missions',
                            style: const TextStyle(fontSize: 12))
                      ])),
                  IconButton(
                      key: const Key('edit-profile'),
                      tooltip: 'Edit profile',
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProfileSetup(
                                  editing: true,
                                  initialName: game.name,
                                  initialAge: game.age,
                                  initialAvatar: game.avatar,
                                  onBack: () => Navigator.pop(context),
                                  onSave: (name, age, avatar) async {
                                    await game.updateProfile(name, age, avatar);
                                    if (context.mounted) Navigator.pop(context);
                                  }))),
                      icon: const Icon(Icons.edit_rounded))
                ]))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard('⭐', '${game.stars}', 'Stars')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('🪙', '${game.coins}', 'Fox Coins'))
        ]),
        const SizedBox(height: 20),
        Card(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Learning progress',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      ...worlds.map((w) {
                        final count = w.missions
                            .where((m) => game.done.contains(m.id))
                            .length;
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(children: [
                              Row(children: [
                                Text(w.emoji),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(w.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
                                Text('${(count / 7 * 100).round()}%')
                              ]),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                  value: count / 7,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.primaries[w.id * 2])
                            ]));
                      })
                    ]))),
        const SizedBox(height: 12),
        Card(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last 7 days',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 18),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(7, (i) {
                            final date =
                                DateTime.now().subtract(Duration(days: 6 - i));
                            final count = game.activity[
                                    date.toIso8601String().substring(0, 10)] ??
                                0;
                            return Column(children: [
                              Text('$count',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              SizedBox(
                                  height: 55,
                                  child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                          width: 16,
                                          height: math
                                              .min(55, 4 + count * 10)
                                              .toDouble(),
                                          decoration: BoxDecoration(
                                              color: count == 0
                                                  ? const Color(0xFFE2ECF0)
                                                  : const Color(0xFF4FC294),
                                              borderRadius:
                                                  BorderRadius.circular(8))))),
                              const SizedBox(height: 8),
                              Text(
                                  [
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                    'S'
                                  ][date.weekday - 1],
                                  style: const TextStyle(fontSize: 12))
                            ]);
                          }))
                    ]))),
        const SizedBox(height: 14),
        const Text('Progress and profile are saved on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF71838A)))
      ]));
}

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  const _StatCard(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Text('$icon $value',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        Text(label)
      ]));
}

class LessonScreen extends StatefulWidget {
  final GameState game;
  final Mission mission;
  final Future<void> Function(String) speak;
  const LessonScreen(
      {super.key,
      required this.game,
      required this.mission,
      required this.speak});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int step = 0, correct = 0;
  bool learning = true, saving = false;
  String? selected, error;
  late List<String> options;
  String get target => widget.mission.words[step];
  bool get colorMeaning => widget.mission.words.contains('red');
  @override
  void initState() {
    super.initState();
    makeOptions();
  }

  void makeOptions() {
    final pool = widget.mission.words.where((w) => w != target).toList()
      ..shuffle();
    options = [target, ...pool.take(3)]..shuffle();
  }

  Future<void> next() async {
    if (saving) return;
    if (learning) {
      setState(() {
        if (step == widget.mission.words.length - 1) {
          learning = false;
          step = 0;
        } else {
          step++;
        }
        makeOptions();
      });
      return;
    }
    if (selected == null) return;
    if (step < widget.mission.words.length - 1) {
      setState(() {
        step++;
        selected = null;
        makeOptions();
      });
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result = await widget.game.finish(widget.mission,
          (correct / widget.mission.words.length * 100).round());
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => RewardScreen(
                  result: result,
                  mission: widget.mission,
                  completed: widget.game.done.length)));
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          error = 'Could not save. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          leading: IconButton(
              tooltip: 'Close lesson',
              icon: const Icon(Icons.close_rounded),
              onPressed: saving ? null : () => Navigator.pop(context)),
          title: Column(children: [
            Text(widget.mission.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            LinearProgressIndicator(
                value: (step + 1) / widget.mission.words.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(6))
          ]),
          actions: [
            Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                    child: Text('${step + 1}/${widget.mission.words.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800))))
          ]),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 510),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(learning ? 'Listen and repeat' : 'What is it?',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 18),
                            Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: const Color(0xFFE9E5D9)),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x0D123C62),
                                          blurRadius: 12,
                                          offset: Offset(0, 5))
                                    ]),
                                child: Column(children: [
                                  WordPicture(target,
                                      key: const Key('prompt-picture'),
                                      size: learning ? 220 : 175,
                                      colorMeaning: colorMeaning),
                                  if (learning) ...[
                                    const SizedBox(height: 14),
                                    Text(target,
                                        style: const TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900))
                                  ],
                                  const SizedBox(height: 10),
                                  IconButton.filledTonal(
                                      key: const Key('speak-word'),
                                      tooltip: 'Listen to the word',
                                      onPressed: () => widget.speak(target),
                                      icon: const Icon(Icons.volume_up_rounded,
                                          size: 30))
                                ])),
                            const SizedBox(height: 18),
                            if (learning) ...[
                              const Text('Tap the speaker. Say the word aloud!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFF6A818E))),
                              const SizedBox(height: 20)
                            ] else ...[
                              GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.65,
                                  children: options.map((word) {
                                    final good =
                                            selected != null && word == target,
                                        bad =
                                            selected == word && word != target;
                                    return Material(
                                        color: good
                                            ? const Color(0xFFE4F6E8)
                                            : bad
                                                ? const Color(0xFFFFE9E3)
                                                : Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            side: BorderSide(
                                                color: good
                                                    ? leaf
                                                    : bad
                                                        ? Colors.deepOrange
                                                        : const Color(
                                                            0xFFE5E6E1),
                                                width: good || bad ? 2 : 1)),
                                        child: InkWell(
                                            key: Key('answer-$word'),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            onTap: selected != null
                                                ? null
                                                : () {
                                                    setState(() {
                                                      selected = word;
                                                      if (word == target)
                                                        correct++;
                                                    });
                                                    widget.speak(target);
                                                  },
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(children: [
                                                  WordPicture(word,
                                                      size: 42,
                                                      colorMeaning:
                                                          colorMeaning),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                      child: Text(word,
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800)))
                                                ]))));
                                  }).toList()),
                              const SizedBox(height: 14),
                              if (selected != null)
                                Text(
                                    selected == target
                                        ? '⭐ Great job!'
                                        : 'Good try! This is $target.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: selected == target
                                            ? leaf
                                            : Colors.deepOrange)),
                              const SizedBox(height: 12)
                            ],
                            if (error != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(error!,
                                      style:
                                          const TextStyle(color: Colors.red))),
                            FilledButton(
                                key: const Key('lesson-next'),
                                onPressed:
                                    saving || (!learning && selected == null)
                                        ? null
                                        : next,
                                child: Text(saving
                                    ? 'Saving…'
                                    : learning
                                        ? (step ==
                                                widget.mission.words.length - 1
                                            ? "Let’s play!"
                                            : 'Next word')
                                        : (step ==
                                                widget.mission.words.length - 1
                                            ? 'Finish lesson'
                                            : 'Next'))),
                            const SizedBox(height: 14),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    widget.mission.words.length,
                                    (i) => Container(
                                        width: 6,
                                        height: 6,
                                        margin: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: i == step
                                                ? blue
                                                : const Color(0xFFD9E1E5)))))
                          ]))))));
}

class RewardScreen extends StatefulWidget {
  final LessonResult result;
  final Mission mission;
  final int completed;
  const RewardScreen(
      {super.key,
      required this.result,
      required this.mission,
      required this.completed});
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    // Only chime when a reward was actually earned, not on a practice
    // replay where stars/coins were already collected earlier.
    if (!widget.result.replay) SoundService.instance.playReward();
  }

  LessonResult get result => widget.result;
  Mission get mission => widget.mission;
  int get completed => widget.completed;

  @override
  Widget build(BuildContext context) => Scaffold(
      body: SkyPanel(
          child: SafeArea(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 450),
                          child: Column(children: [
                            const SizedBox(height: 15),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Image.asset('assets/great-job.png',
                                    semanticLabel:
                                        'Great job! Happy fox celebrating')),
                            Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                    color: cream,
                                    borderRadius: BorderRadius.circular(28)),
                                child: Column(children: [
                                  Text('${result.score}% correct',
                                      key: const Key('result-score'),
                                      style: const TextStyle(
                                          fontSize: 27,
                                          fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 18),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text('⭐ +${result.stars}',
                                            key: const Key('result-stars'),
                                            style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFE5AB00))),
                                        Text('🪙 +${result.coins}',
                                            key: const Key('result-coins'),
                                            style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFE5AB00)))
                                      ]),
                                  const SizedBox(height: 15),
                                  Text(
                                      result.replay
                                          ? 'Great practice! Your reward was collected earlier.'
                                          : 'You completed ${mission.title}!',
                                      textAlign: TextAlign.center),
                                  if (completed == 42) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                        '🏆 All 42 missions complete!\nYou are an English Fox Hero!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900))
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                          key: const Key('reward-continue'),
                                          style: FilledButton.styleFrom(
                                              backgroundColor: leaf),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Continue'))),
                                  const SizedBox(height: 20),
                                  LinearProgressIndicator(
                                      value: completed / 42,
                                      minHeight: 9,
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color(0xFFFFC743)),
                                  const SizedBox(height: 8),
                                  Text('$completed / 42 missions completed')
                                ]))
                          ])))))));
}
