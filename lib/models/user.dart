enum UserRole { tenant, landowner, both }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String profilePhotoUrl;
  final String alternateContact;
  final String gender;
  final DateTime? dateOfBirth;
  final bool isVerified;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String appTheme;
  final bool locationEnabled;
  final String profileVisibility;
  final bool twoFactorEnabled;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profilePhotoUrl = '',
    this.alternateContact = '',
    this.gender = '',
    this.dateOfBirth,
    this.isVerified = false,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.language = 'English',
    this.appTheme = 'system',
    this.locationEnabled = true,
    this.profileVisibility = 'public',
    this.twoFactorEnabled = false,
  });

  String get roleLabel {
    switch (role) {
      case UserRole.tenant:
        return 'Tenant';
      case UserRole.landowner:
        return 'Owner';
      case UserRole.both:
        return 'Owner & Tenant';
    }
  }

  int get profileCompletion {
    final fields = [
      name.trim(),
      email.trim(),
      phone.trim(),
      profilePhotoUrl.trim(),
      alternateContact.trim(),
      gender.trim(),
      dateOfBirth?.toIso8601String() ?? '',
    ];
    final completed = fields.where((field) => field.isNotEmpty).length;
    return ((completed / fields.length) * 100).round();
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? profilePhotoUrl,
    String? alternateContact,
    String? gender,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    bool? isVerified,
    bool? emailNotifications,
    bool? smsNotifications,
    String? language,
    String? appTheme,
    bool? locationEnabled,
    String? profileVisibility,
    bool? twoFactorEnabled,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      alternateContact: alternateContact ?? this.alternateContact,
      gender: gender ?? this.gender,
      dateOfBirth: clearDateOfBirth ? null : dateOfBirth ?? this.dateOfBirth,
      isVerified: isVerified ?? this.isVerified,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      language: language ?? this.language,
      appTheme: appTheme ?? this.appTheme,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profilePhotoUrl': profilePhotoUrl,
      'alternateContact': alternateContact,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
      'isVerified': isVerified,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'appTheme': appTheme,
      'locationEnabled': locationEnabled,
      'profileVisibility': profileVisibility,
      'twoFactorEnabled': twoFactorEnabled,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final roleName = json['role']?.toString() ?? UserRole.tenant.name;
    final dobValue = json['dateOfBirth'] ?? json['date_of_birth'];

    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == roleName,
        orElse: () => UserRole.tenant,
      ),
      profilePhotoUrl:
          (json['profilePhotoUrl'] ?? json['profile_photo_url'] ?? '')
              .toString(),
      alternateContact:
          (json['alternateContact'] ?? json['alternate_contact'] ?? '')
              .toString(),
      gender: json['gender']?.toString() ?? '',
      dateOfBirth: dobValue == null || dobValue.toString().isEmpty
          ? null
          : DateTime.tryParse(dobValue.toString()),
      isVerified: json['isVerified'] == true || json['is_verified'] == true,
      emailNotifications:
          json['emailNotifications'] ?? json['email_notifications'] ?? true,
      smsNotifications:
          json['smsNotifications'] ?? json['sms_notifications'] ?? false,
      language: json['language']?.toString() ?? 'English',
      appTheme: (json['appTheme'] ?? json['app_theme'] ?? 'system').toString(),
      locationEnabled:
          json['locationEnabled'] ?? json['location_enabled'] ?? true,
      profileVisibility:
          (json['profileVisibility'] ?? json['profile_visibility'] ?? 'public')
              .toString(),
      twoFactorEnabled:
          json['twoFactorEnabled'] ?? json['two_factor_enabled'] ?? false,
    );
  }
}
