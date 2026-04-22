import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final svc = AudioService();
  ref.onDispose(svc.dispose);
  return svc;
});

class AudioService {
  final AudioPlayer _enginePlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _sfxVolume = 0.8;
  double _musicVolume = 0.5;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  Future<void> init() async {
    await _enginePlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_musicVolume);
  }

  // ---- Engine Sound ----

  Future<void> startEngine() async {
    if (!_soundEnabled) return;
    await _enginePlayer.play(AssetSource('audio/engine_idle.mp3'));
    await _enginePlayer.setVolume(0.3);
  }

  Future<void> updateEngineRpm(double rpm, double maxRpm) async {
    if (!_soundEnabled) return;
    final ratio = (rpm / maxRpm).clamp(0.3, 1.0);
    await _enginePlayer.setPlaybackRate(0.6 + ratio * 0.8);
    await _enginePlayer.setVolume(_sfxVolume * (0.3 + ratio * 0.4));
  }

  Future<void> stopEngine() async {
    await _enginePlayer.stop();
  }

  // ---- SFX ----

  Future<void> playSkid() async {
    if (!_soundEnabled) return;
    await _sfxPlayer.play(AssetSource('audio/skid.mp3'));
    await _sfxPlayer.setVolume(_sfxVolume * 0.5);
  }

  Future<void> playCollision(double intensity) async {
    if (!_soundEnabled) return;
    final clip = intensity > 20 ? 'audio/collision_hard.mp3' : 'audio/collision_soft.mp3';
    await _sfxPlayer.play(AssetSource(clip));
    await _sfxPlayer.setVolume(_sfxVolume * intensity.clamp(0.3, 1.0));
  }

  Future<void> playConeHit() async {
    if (!_soundEnabled) return;
    await _sfxPlayer.play(AssetSource('audio/cone_hit.mp3'));
    await _sfxPlayer.setVolume(_sfxVolume * 0.6);
  }

  Future<void> playParkSuccess() async {
    if (!_soundEnabled) return;
    await _sfxPlayer.play(AssetSource('audio/park_success.mp3'));
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  Future<void> playGearShift() async {
    if (!_soundEnabled) return;
    await _sfxPlayer.play(AssetSource('audio/gear_shift.mp3'));
    await _sfxPlayer.setVolume(_sfxVolume * 0.4);
  }

  Future<void> playCountdown() async {
    if (!_soundEnabled) return;
    await _sfxPlayer.play(AssetSource('audio/countdown.mp3'));
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  // ---- Music ----

  Future<void> startMenuMusic() async {
    if (!_musicEnabled) return;
    await _musicPlayer.play(AssetSource('audio/music_menu.mp3'));
  }

  Future<void> startGameMusic() async {
    if (!_musicEnabled) return;
    await _musicPlayer.play(AssetSource('audio/music_game.mp3'));
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  // ---- Config ----

  void setSoundEnabled(bool v) => _soundEnabled = v;
  void setMusicEnabled(bool v) {
    _musicEnabled = v;
    if (!v) stopMusic();
  }
  void setSfxVolume(double v) {
    _sfxVolume = v;
    _sfxPlayer.setVolume(v);
  }
  void setMusicVolume(double v) {
    _musicVolume = v;
    _musicPlayer.setVolume(v);
  }

  Future<void> dispose() async {
    await _enginePlayer.dispose();
    await _musicPlayer.dispose();
    await _sfxPlayer.dispose();
  }
}
