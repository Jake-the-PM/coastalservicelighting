import 'dart:convert';

class Installation {
  final String id;
  final String customerName;
  final String address;
  final DateTime dateInstalled;
  final List<String> controllerIps;
  final String? previewImage;
  final String? customerEmail;

  Installation({
    required this.id,
    required this.customerName,
    required this.address,
    required this.dateInstalled,
    required this.controllerIps,
    this.previewImage,
    this.customerEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'address': address,
      'dateInstalled': dateInstalled.toIso8601String(),
      'controllerIps': controllerIps,
      'previewImage': previewImage,
      'customerEmail': customerEmail,
    };
  }

  factory Installation.fromJson(Map<String, dynamic> json) {
    return Installation(
      id: json['id'],
      customerName: json['customerName'],
      address: json['address'],
      dateInstalled: DateTime.parse(json['dateInstalled']),
      controllerIps: List<String>.from(json['controllerIps']),
      previewImage: json['previewImage'],
      customerEmail: json['customerEmail'],
    );
  }
}
