import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'package:json_annotation/json_annotation.dart';
import 'package:play_games/play_games.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'async_saver.dart';
import 'buy.dart';
import 'iap.dart';
import 'options.dart';
import 'play_user.dart';
import 'skin_list.dart';
import 'stats.dart';

part 'data.g.dart';

@JsonSerializable()
class SavedData {
  Options options;
  Stats stats;
  Buy buy;

  bool showTutorial;

  SavedData() {
    showTutorial = true;
    options = Options();
    stats = Stats();
    buy = Buy();
  }

  factory SavedData.fromJson(Map<String, dynamic> json) => _$SavedDataFromJson(json);

  Map<String, dynamic> toJson() => _$SavedDataToJson(this);

  static SavedData merge(SavedData s1, SavedData s2) {
    return SavedData()
      ..showTutorial = s1.showTutorial || s2.showTutorial
      ..options = s1.options ?? s2.options
      ..stats = Stats.merge(s1.stats, s2.stats)
      ..buy = Buy.merge(s1.buy, s2.buy);
  }
}

class Data {
  static const SAVE_NAME = 'bgug.data.v3';

  static SkinList skinList;
  static SavedData _data;

  static Options get options => _data.options ??= Options();

  static set options(Options options) => _data.options = options ?? Options();

  static Stats get stats => _data.stats ??= Stats();

  static Buy get buy => _data.buy ??= Buy();

  static PlayUser _user;

  static PlayUser get user => _user;

  static set user(PlayUser user) {
    _user = user;
    userStream.values.forEach((fn) => fn(user));
  }

  static Options currentOptions;
  static bool pristine = true;
  static bool isSaving = false;
  static bool hasOpened = false;

  static Map<String, void Function(PlayUser)> userStream = {};

  static String addUserCallback(void Function(PlayUser) fn) {
    final key = Uuid().v4();
    userStream[key] = fn;
    return key;
  }

  static void removeUserCallback(String key) {
    userStream.remove(key);
  }

  static void checkAchievementsAndSkins() {
    if (stats.totalDistance >= 21000) {
      _achievement('achievement_half_marathoner');
    }
    if (stats.totalDistance >= 42000) {
      _achievement('achievement_marathoner');
      if (!buy.skinsOwned.contains('marathonist.png')) {
        buy.skinsOwned.add('marathonist.png');
      }
    }
    if (stats.totalJumps > 500) {
      _achievement('achievement_jumper');
    }
    if (stats.totalJumps > 1000) {
      _achievement('achievement_super_jumper');
      if (!buy.skinsOwned.contains('jumping.png')) {
        buy.skinsOwned.add('jumping.png');
      }
    }
    if (buy.skinsOwned.length > 1) {
      _achievement('achievement_the_disguised_bot');
    }
    if (buy.skinsOwned.length > 10) {
      _achievement('achievement_a_small_collection');
    }
    if (buy.skinsOwned.length > 20) {
      _achievement('achievement_the_collector');
    }
    if (buy.skinsOwned.length > 30) {
      _achievement('achievement_the_completionist');
    }
  }

  static Future _achievement(String name) async {
    if (user != null) {
      await PlayGames.unlockAchievementByName(name);
    }
  }

  static Future loadHardData() {
    return SkinList.fetch().then((r) => skinList = r);
  }

  static Future loadLocalSoftData() async {
    pristine = true;
    _data = await Data.fetch(true);
    validatePro(IAP.pro);
  }

  static bool get hasData => _data != null;

  static bool get playGames => user != null;

  static Future<bool> getAndToggleShowTutorial() async {
    if (_data.showTutorial) {
      _data.showTutorial = false;
      await save();
      return true;
    }
    return false;
  }

  static Future save() async {
    if (isSaving) {
      print('will save in a while!');
      return Future.delayed(const Duration(seconds: 3)).then((_) => save());
    }
    isSaving = true;
    pristine = false;
    final data = json.encode(_data.toJson());
    final result = await _saveInternal(data);
    print('Saved data! playGames: $playGames');
    isSaving = false;
    return result;
  }

  static Future<Object> _saveInternal(String data) async {
    if (playGames) {
      if (!hasOpened) {
        await _openInternal();
        hasOpened = true;
      }
      print('Saving $data');
      final status = await PlayGames.saveSnapshot(SAVE_NAME, data);
      print('Saved $status');
      return await _openInternal();
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.setString(SAVE_NAME, data);
    }
  }

  static Future<Snapshot> _openInternal() async {
    try {
      return await PlayGames.openSnapshot(SAVE_NAME);
    } catch (ex) {
      if (ex is CloudSaveConflictError) {
        final result = _mergeInternal(ex.local, ex.server);
        return await PlayGames.resolveSnapshotConflict(SAVE_NAME, ex.conflictId, result);
      }
      rethrow;
    }
  }

  static Future<SavedData> fetch(bool createNew) async {
    final loaded = await _doFetch(createNew);
    loaded?.stats?.firstTimeScoreCheck();
    return loaded;
  }

  static Future<SavedData> _doFetch(bool createNew) async {
    if (playGames) {
      return await _fetchFromPlayGames(createNew);
    } else {
      return await _fetchFromSharedPreferences(createNew);
    }
  }

  static Future<SavedData> _fetchFromPlayGames(bool createNew) async {
    final snap = await _openInternal();
    if (snap.content == null || snap.content.trim().isEmpty) {
      return createNew ? SavedData() : null;
    }
    hasOpened = true;
    return SavedData.fromJson(json.decode(snap.content));
  }

  static Future<SavedData> _fetchFromSharedPreferences(bool createNew) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(SAVE_NAME);
    if (jsonStr == null) {
      return createNew ? SavedData() : null;
    }
    return SavedData.fromJson(json.decode(jsonStr));
  }

  static void forceData(SavedData data) {
    pristine = false;
    _data = data;
    validatePro(IAP.pro);
  }

  static void mergeData(SavedData other) {
    _data = SavedData.merge(other, _data);
    validatePro(IAP.pro);
  }

  static void setData(SavedData data) {
    if (Data.pristine) {
      Data.forceData(data);
    } else {
      Data.mergeData(data);
    }
  }

  static String _mergeInternal(Snapshot local, Snapshot server) {
    final s1 = SavedData.fromJson(json.decode(local.content));
    final s2 = SavedData.fromJson(json.decode(server.content));
    return json.encode(SavedData.merge(s1, s2).toJson());
  }

  static void saveAsync() async {
    final saver = AsyncSaver.start();
    await Data.save();
    saver.stop();
  }

  static void validatePro(bool pro) {
    const goldSkin = 'gold.png';
    if (pro == true) {
      if (!buy.skinsOwned.contains(goldSkin)) {
        buy.skinsOwned.add(goldSkin);
      }
    } else {
      buy.skinsOwned.remove(goldSkin);
      if (buy.selectedSkin == goldSkin) {
        buy.selectedSkin = 'asimov.png';
      }
    }
  }
}
