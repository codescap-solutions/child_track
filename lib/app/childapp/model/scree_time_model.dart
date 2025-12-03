class AppScreenTimeModel {
  final String package;
  final int seconds;

  AppScreenTimeModel({required this.package, required this.seconds});

  factory AppScreenTimeModel.fromJson(Map<String, dynamic> json) {
    return AppScreenTimeModel(
      package: json['package'] ?? '',
      seconds: json['seconds'] ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'package': package,
      'seconds': seconds,
    };
  }
}
