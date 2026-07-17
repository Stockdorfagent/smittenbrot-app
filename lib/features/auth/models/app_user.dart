class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
  });

  factory AppUser.fromSupabase(Map<String, dynamic> data) {
    return AppUser(
      id: data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'],
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'phone': phone,
  };
}