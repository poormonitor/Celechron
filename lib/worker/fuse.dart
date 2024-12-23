import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';

import 'package:celechron/database/database_helper.dart';

class Fuse {
  late DateTime lastUpdateTime;

  final bool isBeta = true;
  final version = [0, 3, 2];
  List<int>? remoteVersion;
  bool hasNewVersion = false;

  final HttpClient _httpClient = HttpClient();
  final DatabaseHelper _db = Get.find<DatabaseHelper>(tag: 'db');

  String get displayVersion => version.join('.') + (isBeta ? ' beta' : '');

  Fuse() {
    lastUpdateTime = DateTime(2001, 1, 1);
  }

  Future<String?> checkUpdate() async {
    try {
      if (lastUpdateTime
          .isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        return null;
      }

      late String checkUpdateUrl;
      if (Platform.isAndroid) {
        checkUpdateUrl = "https://api.celechron.top/checkUpdate?platform=android";
      } else if (Platform.isIOS) {
        checkUpdateUrl = "https://api.celechron.top/checkUpdate?platform=ios";
      } else {
        return "https://api.celechron.top/checkUpdate?platform=others";
      }

      var request = await _httpClient
          .getUrl(Uri.parse(checkUpdateUrl))
          .timeout(const Duration(seconds: 8));
      var response = await request.close().timeout(const Duration(seconds: 8));
      var html = await response.transform(utf8.decoder).join();

      var match = RegExp('[0-9.]+').firstMatch(html)!;
      remoteVersion =
          match.group(0)!.split('.').map((e) => int.parse(e)).toList();

      hasNewVersion = _compareVersion(html.contains('beta'));
      lastUpdateTime = DateTime.now();
      await _db.setFuse(this);

      if (hasNewVersion) {
        return "有新版本可用";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _compareVersion(bool remoteIsBeta) {
    if (remoteVersion == null) {
      return false;
    }
    if (remoteVersion![0] > version[0]) {
      return true;
    } else if (remoteVersion![0] == version[0]) {
      if (remoteVersion![1] > version[1]) {
        return true;
      } else if (remoteVersion![1] == version[1]) {
        if (remoteVersion![2] > version[2]) {
          return true;
        } else if (remoteVersion![2] == version[2]) {
          if (isBeta && !remoteIsBeta) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        'lastUpdateTime': lastUpdateTime.toIso8601String(),
      };

  Fuse.fromJson(Map<String, dynamic> json) {
    lastUpdateTime = DateTime.parse(json['lastUpdateTime']);
  }
}
