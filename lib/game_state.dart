import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'curriculum.dart';

const avatarNames = ['fox', 'rabbit', 'bear', 'cat'];

/// Where an item goes on the fox. One item per slot can be worn at a time.
enum ShopSlot { hat, glasses, scarf, fur, eyes }

/// Prices of the big "change colour" items.
const furPrice = 200;
const eyePrice = 300;

class ShopItem {
  final String name;

  /// Emoji used for the picture of old-style hats and as a fallback.
  final String emoji;
  final int price;
  final ShopSlot slot;

  /// Which drawing to use. `'emoji'` = just show [emoji]; anything else is the
  /// name of a hand-drawn style in fox_look.dart (or, for fur/eyes, the name
  /// of the baked pictures in assets/pets/).
  final String style;

  /// Swatch colour (ARGB) shown on the fur / eye colour cards.
  final int color;
  const ShopItem(this.name, this.emoji, this.price, this.slot, this.style,
      [this.color = 0]);
}

/// IMPORTANT: the position in this list is the item's saved id. Never reorder
/// or delete items - only add new ones at the end - or children's saved
/// purchases would point at the wrong things.
const shopItems = <ShopItem>[
  // 0-3: the original hats (same order and prices as before)
  ShopItem('Explorer hat', '🎩', 40, ShopSlot.hat, 'emoji'),
  ShopItem('Blue cap', '🧢', 30, ShopSlot.hat, 'emoji'),
  ShopItem('Hero crown', '👑', 100, ShopSlot.hat, 'emoji'),
  ShopItem('Magic hat', '✨', 70, ShopSlot.hat, 'magic'),
  // glasses
  ShopItem('Round glasses', '👓', 35, ShopSlot.glasses, 'round'),
  ShopItem('Cool shades', '🕶️', 50, ShopSlot.glasses, 'shades'),
  ShopItem('Heart glasses', '💖', 60, ShopSlot.glasses, 'heart'),
  ShopItem('Star glasses', '⭐', 75, ShopSlot.glasses, 'star'),
  // scarves
  ShopItem('Red scarf', '🧣', 45, ShopSlot.scarf, 'red'),
  ShopItem('Green stripes', '🧣', 55, ShopSlot.scarf, 'green'),
  ShopItem('Rainbow scarf', '🌈', 90, ShopSlot.scarf, 'rainbow'),
  // fur colours (every animal)
  ShopItem('Silver fur', '🐺', furPrice, ShopSlot.fur, 'silver', 0xFFB4C0D4),
  ShopItem('Blue fur', '🦊', furPrice, ShopSlot.fur, 'blue', 0xFF2D9CF0),
  ShopItem('Purple fur', '🦊', furPrice, ShopSlot.fur, 'purple', 0xFF8E52E0),
  ShopItem('Pink fur', '🦊', furPrice, ShopSlot.fur, 'pink', 0xFFFF7FB5),
  // eye colours (every animal)
  ShopItem('Sky eyes', '👁️', eyePrice, ShopSlot.eyes, 'sky', 0xFF29B6F6),
  ShopItem('Green eyes', '👁️', eyePrice, ShopSlot.eyes, 'green', 0xFF3DDC3A),
  ShopItem('Purple eyes', '👁️', eyePrice, ShopSlot.eyes, 'purple', 0xFFA64DFF),
  ShopItem('Pink eyes', '👁️', eyePrice, ShopSlot.eyes, 'pink', 0xFFFF5CA8),
];

/// Everything the fox is currently wearing - what FoxAvatar draws.
class FoxLook {
  final ShopItem? hat, glasses, scarf, fur, eyes;
  const FoxLook({this.hat, this.glasses, this.scarf, this.fur, this.eyes});
  static const none = FoxLook();
}

class LessonResult {
  final int score, stars, coins;
  final bool replay;
  const LessonResult(this.score, this.stars, this.coins, this.replay);
}

class GameState extends ChangeNotifier {
  late SharedPreferences prefs;
  bool loaded = false, profileReady = false;
  String name = '', avatar = 'fox';
  int age = 7, stars = 0, coins = 0, unlocked = 1;
  final Set<int> done = {};
  final Set<int> owned = {};

  /// What is being worn right now: slot -> index into [shopItems].
  final Map<ShopSlot, int> worn = {};

  /// The worn hat (kept for older code/tests that only knew about hats).
  int? get equipped => worn[ShopSlot.hat];

  FoxLook get look => FoxLook(
      hat: _wornItem(ShopSlot.hat),
      glasses: _wornItem(ShopSlot.glasses),
      scarf: _wornItem(ShopSlot.scarf),
      fur: _wornItem(ShopSlot.fur),
      eyes: _wornItem(ShopSlot.eyes));
  ShopItem? _wornItem(ShopSlot slot) {
    final i = worn[slot];
    return i == null ? null : shopItems[i];
  }

  static ShopSlot? _slotByName(String name) {
    for (final s in ShopSlot.values) {
      if (s.name == name) return s;
    }
    return null;
  }
  final Map<String, int> activity = {};
  Future<void> load() async {
    prefs = await SharedPreferences.getInstance();
    name = prefs.getString('name') ?? '';
    age = prefs.getInt('age') ?? 7;
    avatar = prefs.getString('avatar') ?? 'fox';
    if (!avatarNames.contains(avatar)) avatar = 'fox';
    profileReady = prefs.getBool('profileReady') ?? false;
    stars = prefs.getInt('stars') ?? 0;
    coins = prefs.getInt('coins') ?? 0;
    unlocked = (prefs.getInt('unlocked') ?? 1).clamp(1, allMissions.length);
    done.addAll((prefs.getStringList('done') ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id >= 1 && id <= allMissions.length));
    owned.addAll((prefs.getStringList('owned') ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .where((id) => id >= 0 && id < shopItems.length));
    worn.clear();
    for (final entry in prefs.getStringList('worn') ?? <String>[]) {
      final p = entry.split(':');
      if (p.length != 2) continue;
      final slot = _slotByName(p[0]);
      final index = int.tryParse(p[1]);
      if (slot == null || index == null) continue;
      if (index < 0 || index >= shopItems.length) continue;
      if (owned.contains(index) && shopItems[index].slot == slot) {
        worn[slot] = index;
      }
    }
    // Saves from before the shop grew only knew about one worn hat.
    final legacyHat = prefs.getInt('equipped');
    if (!prefs.containsKey('worn') &&
        legacyHat != null &&
        owned.contains(legacyHat) &&
        legacyHat >= 0 &&
        legacyHat < shopItems.length) {
      worn[ShopSlot.hat] = legacyHat;
    }
    for (final entry in prefs.getStringList('activity') ?? <String>[]) {
      final p = entry.split(':');
      if (p.length == 2) activity[p[0]] = int.tryParse(p[1]) ?? 0;
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> updateProfile(String value, int years, String character) async {
    if (value.trim().isEmpty ||
        years < 5 ||
        years > 9 ||
        !avatarNames.contains(character))
      throw ArgumentError('Invalid profile');
    await prefs.setString('name', value.trim());
    await prefs.setInt('age', years);
    await prefs.setString('avatar', character);
    await prefs.setBool('profileReady', true);
    name = value.trim();
    age = years;
    avatar = character;
    profileReady = true;
    notifyListeners();
  }

  Future<LessonResult> finish(Mission mission, int score) async {
    final replay = done.contains(mission.id);
    final addStars = replay
        ? 0
        : score >= 80
            ? 3
            : 2;
    final addCoins = replay
        ? 0
        : score >= 80
            ? 25
            : 15;
    if (!replay) {
      done.add(mission.id);
      stars += addStars;
      coins += addCoins;
      if (mission.id == unlocked && unlocked < allMissions.length) unlocked++;
    }
    final key = DateTime.now().toIso8601String().substring(0, 10);
    activity[key] = (activity[key] ?? 0) + 1;
    await prefs.setStringList('activity',
        activity.entries.map((e) => '${e.key}:${e.value}').toList());
    await prefs.setStringList('done', done.map((v) => '$v').toList());
    await prefs.setInt('completed', done.length);
    await prefs.setInt('stars', stars);
    await prefs.setInt('coins', coins);
    await prefs.setInt('unlocked', unlocked);
    notifyListeners();
    return LessonResult(score, addStars, addCoins, replay);
  }

  Future<void> _saveWorn() => prefs.setStringList(
      'worn', worn.entries.map((e) => '${e.key.name}:${e.value}').toList());

  /// Buys the item if needed (returns false if there are not enough coins)
  /// and puts it on, replacing whatever was in the same slot.
  Future<bool> buyOrEquip(int index) async {
    if (index < 0 || index >= shopItems.length) return false;
    if (!owned.contains(index)) {
      if (coins < shopItems[index].price) return false;
      coins -= shopItems[index].price;
      owned.add(index);
    }
    worn[shopItems[index].slot] = index;
    await prefs.setInt('coins', coins);
    await prefs.setStringList('owned', owned.map((v) => '$v').toList());
    await _saveWorn();
    notifyListeners();
    return true;
  }

  /// Takes the item in [slot] off (it stays owned).
  Future<void> takeOff(ShopSlot slot) async {
    if (worn.remove(slot) == null) return;
    await _saveWorn();
    notifyListeners();
  }
}
