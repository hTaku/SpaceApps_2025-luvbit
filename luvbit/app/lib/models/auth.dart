class AuthResponse {
  final String accessToken;
  final int? userId;
  final String? satelliteName;
  
  AuthResponse({
    required this.accessToken,
    this.userId,
    this.satelliteName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      userId: json['user_id'],
      satelliteName: json['satellite_name'],
    );
  }
}