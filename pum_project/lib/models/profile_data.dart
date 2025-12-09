class ProfileData {
  String? userName;
  String? firstName;
  String? lastName;
  String? email;
  DateTime? dateOfBirth;
  String? gender;
  double? height;
  double? weight;
  String? avatarUrl;
  double totalDistanceKm;
  int totalActivities;
  double totalDurationSeconds;

  ProfileData({
    this.userName,
    this.firstName,
    this.lastName,
    this.email,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.avatarUrl,
    this.totalDistanceKm = 0.0,
    this.totalActivities = 0,
    this.totalDurationSeconds = 0.0,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userName: json['userName'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      dateOfBirth: json['dateOfBirth'] != null && json['dateOfBirth'].toString().isNotEmpty
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'],
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      avatarUrl: json['avatarUrl'],
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      totalActivities: json['totalActivities'] as int? ?? 0,
      totalDurationSeconds: (json['totalDurationSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'avatarUrl': avatarUrl,
      'totalDistanceKm': totalDistanceKm,
      'totalActivities': totalActivities,
      'totalDurationSeconds': totalDurationSeconds,
    };
  }
}