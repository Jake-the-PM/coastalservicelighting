import 'dart:convert';

class Installation {
  final String id;
  final String customerName;
  final String address;
  final DateTime dateInstalled;
  final List<String> controllerIps;
  final List<String>? controllerNames; // mDNS Hostnames for self-healing
  final List<String>? controllerMacs; // Hardware fingerprints for identity verification
  final String? previewImage;
  final String? customerEmail;

  Installation({
    required this.id,
    required this.customerName,
    required this.address,
    required this.dateInstalled,
    required this.controllerIps,
    this.controllerNames,
    this.controllerMacs,
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
      'controllerNames': controllerNames,
      'controllerMacs': controllerMacs,
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
      controllerNames: json['controllerNames'] != null ? List<String>.from(json['controllerNames']) : null,
      controllerMacs: json['controllerMacs'] != null ? List<String>.from(json['controllerMacs']) : null,
      previewImage: json['previewImage'],
      customerEmail: json['customerEmail'],
    );
  }
}
