import 'package:audioplayers/audioplayers.dart';

/// Plays the short reward/purchase sound effects used across the app.
///
/// Kept deliberately tiny and forgiving: sound is a nice-to-have for a
/// kids' app, so a device with no audio output, a silent switch flipped,
/// or (in widget tests) no real audio plugin at all should never cause a
/// crash or a delay — playback errors are swallowed on purpose.
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  // A few players used in turn, so that several sounds can overlap (the
  // "buy" pop, the fox's boing and the happy jingle all play together)
  // without cutting each other off.
  final List<AudioPlayer> _players = [];
  int _next = 0;

  AudioPlayer _pick() {
    if (_players.isEmpty) {
      for (var i = 0; i < 3; i++) {
        _players.add(AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setPlayerMode(PlayerMode.lowLatency));
      }
    }
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    return player;
  }

  Future<void> _play(String fileName, {double volume = .85}) async {
    try {
      final player = _pick();
      await player.stop();
      await player.play(AssetSource('sounds/$fileName'), volume: volume);
    } catch (_) {
      // No audio available right now — that's fine, keep going silently.
    }
  }

  void _later(int milliseconds, String fileName, {double volume = .85}) {
    Future<void>.delayed(
        Duration(milliseconds: milliseconds), () => _play(fileName, volume: volume));
  }

  /// A bright little ascending chime for stars & coins landing on the
  /// "Great job!" screen after finishing a lesson.
  Future<void> playReward() => _play('reward.wav');

  /// A short, satisfying "pop" for buying or equipping a shop item.
  Future<void> playPurchase() => _play('purchase.wav');

  /// The whole "I bought something and the fox is thrilled!" moment:
  /// pop, then the fox's boing as it jumps, then a happy jingle.
  Future<void> playBuyCelebration() async {
    _later(200, 'boing.wav', volume: .7);
    _later(380, 'yay.wav', volume: .8);
    await _play('purchase.wav');
  }

  /// Soft swoosh + pop when putting on something that is already owned.
  Future<void> playWear() => _play('wear.wav', volume: .8);

  /// Little downward blip when taking something off.
  Future<void> playOff() => _play('off.wav', volume: .7);

  /// The fox's happy hop when it is tapped.
  Future<void> playBoing() => _play('boing.wav', volume: .7);
}
