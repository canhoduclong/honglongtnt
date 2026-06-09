class AppVersion {
  const AppVersion({
    required this.version,
    required this.versionCode,
    required this.apkUrl,
    required this.forceUpdate,
    required this.message,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: (json['version'] ?? '').toString(),
      versionCode: _readInt(json['version_code']),
      apkUrl: (json['apk_url'] ?? '').toString(),
      forceUpdate: json['force_update'] == true,
      message: (json['message'] ?? '').toString(),
    );
  }

  final String version;
  final int versionCode;
  final String apkUrl;
  final bool forceUpdate;
  final String message;

  bool isNewerThan(int currentVersionCode) {
    return versionCode > currentVersionCode;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
