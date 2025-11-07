class UserDetails {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String district;
  final String postalCode;
  final String role;

  UserDetails({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'role': role,
    };
  }
}
