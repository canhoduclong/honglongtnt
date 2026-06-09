import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/app_version.dart';
import '../widgets/update_dialog.dart';

class UpdateService {
  UpdateService()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          headers: const {'Accept': 'application/json'},
        ),
      );

  static const versionUrl = 'https://hoanglongtnt.com/app-update/version.json';
  static const defaultApkUrl =
      'https://hoanglongtnt.com/app-update/app-release.apk';

  final Dio _dio;
  bool _isChecking = false;
  bool _isDialogOpen = false;

  Future<void> checkForUpdate({bool manual = false}) async {
    if (_isChecking) {
      return;
    }

    _isChecking = true;
    try {
      final latest = await fetchLatestVersion();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (!latest.isNewerThan(currentCode)) {
        if (manual) {
          Get.snackbar(
            'Kiểm tra cập nhật',
            'Bạn đang sử dụng phiên bản mới nhất.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      if (_isDialogOpen) {
        return;
      }

      _isDialogOpen = true;
      await Get.dialog<void>(
        UpdateDialog(
          currentVersion: packageInfo.version,
          latestVersion: latest,
          onUpdateNow: (onProgress) => downloadAndOpenApk(
            latest.apkUrl.isEmpty ? defaultApkUrl : latest.apkUrl,
            onProgress: onProgress,
          ),
          onClosed: () => _isDialogOpen = false,
        ),
        barrierDismissible: !latest.forceUpdate,
      );
      _isDialogOpen = false;
    } catch (error) {
      if (manual) {
        Get.snackbar(
          'Không kiểm tra được cập nhật',
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<AppVersion> fetchLatestVersion() async {
    final response = await _dio.get<Map<String, dynamic>>(versionUrl);
    final data = response.data;
    if (data == null) {
      throw Exception('version.json không có dữ liệu.');
    }
    return AppVersion.fromJson(data);
  }

  Future<void> downloadAndOpenApk(
    String apkUrl, {
    required void Function(double progress) onProgress,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/app-release.apk');

    await _dio.download(
      apkUrl,
      file.path,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total <= 0) {
          return;
        }
        onProgress(received / total);
      },
    );

    onProgress(1);
    final result = await OpenFilex.open(
      file.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}
