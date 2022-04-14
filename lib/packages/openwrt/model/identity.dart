class Identity {
  const Identity({required this.username, required this.password});

  final String username;
  final String password;

  Map toJson() => {
        'username': username,
        'password': password,
      };

  static Identity fromJson(Map<String, dynamic> json) {
    return Identity(
        username: json['username'].toString(),
        password: json['password'].toString());
  }
}
