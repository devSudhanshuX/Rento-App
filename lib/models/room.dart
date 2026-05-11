class Room {
  final String id;
  final String title;
  final String description;
  final double price;
  final double securityDeposit;
  final String location;
  final String city;
  final String address;
  final String contactNumber;
  final String ownerName;
  final List<String> images;
  final String roomType;
  final String furnishing;
  final String preferredTenant;
  final String? availableFrom;
  final List<String> rules;
  final bool isAvailable;
  final String ownerId;
  final List<String> amenities;

  Room({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.securityDeposit = 0,
    required this.location,
    this.city = '',
    this.address = '',
    this.contactNumber = '',
    this.ownerName = '',
    required this.images,
    required this.roomType,
    this.furnishing = '',
    this.preferredTenant = '',
    this.availableFrom,
    this.rules = const [],
    this.isAvailable = true,
    required this.ownerId,
    this.amenities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'securityDeposit': securityDeposit,
      'location': location,
      'city': city,
      'address': address,
      'contactNumber': contactNumber,
      'ownerName': ownerName,
      'images': images,
      'roomType': roomType,
      'furnishing': furnishing,
      'preferredTenant': preferredTenant,
      'availableFrom': availableFrom,
      'rules': rules,
      'isAvailable': isAvailable,
      'ownerId': ownerId,
      'amenities': amenities,
    };
  }

  Room copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? securityDeposit,
    String? location,
    String? city,
    String? address,
    String? contactNumber,
    String? ownerName,
    List<String>? images,
    String? roomType,
    String? furnishing,
    String? preferredTenant,
    String? availableFrom,
    List<String>? rules,
    bool? isAvailable,
    String? ownerId,
    List<String>? amenities,
  }) {
    return Room(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      location: location ?? this.location,
      city: city ?? this.city,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      ownerName: ownerName ?? this.ownerName,
      images: images ?? this.images,
      roomType: roomType ?? this.roomType,
      furnishing: furnishing ?? this.furnishing,
      preferredTenant: preferredTenant ?? this.preferredTenant,
      availableFrom: availableFrom ?? this.availableFrom,
      rules: rules ?? this.rules,
      isAvailable: isAvailable ?? this.isAvailable,
      ownerId: ownerId ?? this.ownerId,
      amenities: amenities ?? this.amenities,
    );
  }

  factory Room.fromJson(Map<String, dynamic> json) {
    final priceValue = json['price'];
    final depositValue = json['securityDeposit'];

    return Room(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: priceValue is num
          ? priceValue.toDouble()
          : double.tryParse(priceValue?.toString() ?? '') ?? 0,
      securityDeposit: depositValue is num
          ? depositValue.toDouble()
          : double.tryParse(depositValue?.toString() ?? '') ?? 0,
      location: json['location'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      ownerName: json['ownerName'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      roomType: json['roomType'] ?? '',
      furnishing: json['furnishing'] ?? '',
      preferredTenant: json['preferredTenant'] ?? '',
      availableFrom: json['availableFrom'],
      rules: List<String>.from(json['rules'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      ownerId: json['ownerId'] ?? '',
      amenities: List<String>.from(json['amenities'] ?? []),
    );
  }
}
