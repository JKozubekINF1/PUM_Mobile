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
    };
  }
}