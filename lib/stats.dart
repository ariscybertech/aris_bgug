import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:play_games/play_games.dart';

import 'data.dart';
import 'game.dart';
import 'play_user.dart';

part 'stats.g.dart';

@JsonSerializable()
class Score {
  double distance;
  int coins;

  Score(this.distance, this.coins);

  factory Score.fromJson(Map<String, dynamic> json) => _$ScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreToJson(this);

  String toText() => 'Scored ${distance.toStringAsFixed(2)} meters earning $coins coins.';
}

@JsonSerializable()
class Stats {
  static const MAX_SCORES = 10;
  static const MAX_TRIES = 3;

  List<Score> scores;

  double maxDistance;
  double totalDistance;
  int maxJumps;
  int totalJumps;
  int maxDives;
  int totalDives;
  int maxGems;
  int totalGems;
  int maxCoins;
  int totalCoins;

  Stats() {
    scores = [];
    maxDistance = 0;
    totalDistance = 0;
    maxJumps = 0;
    totalJumps = 0;
    maxDives = 0;
    totalDives = 0;
    maxGems = 0;
    totalGems = 0;
    maxCoins = 0;
    totalCoins = 0;
  }

  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);

  Map<String, dynamic> toJson() => _$StatsToJson(this);

  Future<SubmitScoreResults> _submitScoreDistance() {
    final distance = (10 * maxDistance).round(); // one decimal place
    return _submitScore('leaderboard_bgug__max_distances', distance);
  }

  Future<SubmitScoreResults> _submitScoreGems() {
    return _submitScore('leaderboard_bgug__max_gems', maxGems);
  }

  Future<SubmitScoreResults> _submitScoreCoins() {
    return _submitScore('leaderboard_bgug__max_coins', maxCoins);
  }

  Future<SubmitScoreResults> _submitScore(String name, int value, {int tries = 0}) async {
    if (Data.user == null) {
      print('[ACHIEVEMENTS] Skipping because not logged in. Name $name, value: $value');
      return null;
    }
    try {
      final results = await PlayGames.submitScoreByName(name, value);
      print('[ACHIEVEMENTS] Successfully submited! Name: $name, value: $value. Result: $results');
      return results;
    } catch (ex, stacktrace) {
      final message = '[ACHIEVEMENTS] Error while submmiting scoreon try $tries: $ex';
      print(message);
      final data = json.encode({
        'name': name,
        'value': value,
        'message': message,
        'tries': tries,
        'ex': ex.toString(),
        'trace': stacktrace.toString(),
      });
      Crashlytics.instance.setBool('achievements', true);
      Crashlytics.instance.log(data);
      Crashlytics.instance.onError(FlutterErrorDetails(exception: data, stack: stacktrace));
      if (tries == MAX_TRIES) {
        print('[ACHIEVEMENTS] Exceed max tries... Giving up.');
        rethrow;
      }
      Data.user = await PlayUser.singIn();
      if (Data.user == null) {
        rethrow;
      }
      return _submitScore(name, value, tries: tries + 1);
    }
  }

  void firstTimeScoreCheck() {
    _submitScoreDistance();
    _submitScoreCoins();
    _submitScoreGems();
  }

  void calculateStats(BgugGame game) {
    final distance = game.hud.maxDistanceInMeters;
    final jumps = game.totalJumps;
    final dives = game.totalDives;
    final gems = game.totalGems;
    final coins = game.currentCoins;

    final score = Score(distance, coins);
    scores.insert(0, score);
    scores = normalize(scores);

    if (distance > maxDistance) {
      maxDistance = distance;
      _submitScoreDistance();
    }
    totalDistance += distance;

    if (jumps > maxJumps) {
      maxJumps = jumps;
    }
    totalJumps += jumps;

    if (dives > maxDives) {
      maxDives = dives;
    }
    totalDives += dives;

    if (gems > maxGems) {
      maxGems = gems;
      _submitScoreGems();
    }
    totalGems += gems;

    if (coins > maxCoins) {
      maxCoins = coins;
      _submitScoreCoins();
    }
    totalCoins += coins;
  }

  static List<T> normalize<T>(List<T> scores) => scores.sublist(0, MAX_SCORES.clamp(0, scores.length));

  static Stats merge(Stats stats1, Stats stats2) {
    return Stats()
      ..scores = normalize((<Score>{}..addAll(stats1.scores)..addAll(stats2.scores)).toList().cast<Score>())
      ..maxDistance = math.max(stats1.maxDistance, stats2.maxDistance)
      ..totalDistance = math.max(stats1.totalDistance, stats2.totalDistance)
      ..maxJumps = math.max(stats1.maxJumps, stats2.maxJumps)
      ..totalJumps = math.max(stats1.totalJumps, stats2.totalJumps)
      ..maxDives = math.max(stats1.maxDives, stats2.maxDives)
      ..totalDives = math.max(stats1.totalDives, stats2.totalDives)
      ..maxGems = math.max(stats1.maxGems, stats2.maxGems)
      ..totalGems = math.max(stats1.totalGems, stats2.totalGems)
      ..maxCoins = math.max(stats1.maxCoins, stats2.maxCoins)
      ..totalCoins = math.max(stats1.totalCoins, stats2.totalCoins);
  }

  List<String> statsList() {
    return [
      'Max Distance (m): ${maxDistance.toStringAsFixed(2)}',
      'Total Distance (m): ${totalDistance.toStringAsFixed(2)}',
      'Max Jumps: $maxJumps',
      'Total Jumps: $totalJumps',
      'Max Dives: $maxDives',
      'Total Dives: $totalDives',
      'Max Gems: $maxGems',
      'Total Gems: $totalGems',
      'Max Coins: $maxCoins',
      'Total Coins: $totalCoins',
    ];
  }
}
