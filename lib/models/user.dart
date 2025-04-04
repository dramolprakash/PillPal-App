class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final List<EmergencyContact> emergencyContacts;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.emergencyContacts = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<EmergencyContact> contacts = [];
    if (json['emergencyContacts'] != null) {
      contacts = List<EmergencyContact>.from(
        json['emergencyContacts'].map((contact) => EmergencyContact.fromJson(contact))
      );
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      emergencyContacts: contacts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'emergencyContacts': emergencyContacts.map((contact) => contact.toJson()).toList(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class EmergencyContact {
  final int? id;
  final String name;
  final String phone;
  final String relationship;

  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      relationship: json['relationship'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
    };
  }
}
