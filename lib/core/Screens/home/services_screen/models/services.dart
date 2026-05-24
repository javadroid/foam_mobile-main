import 'dart:convert';

List<ServicesList> servicesListFromJson(dynamic str) => List<ServicesList>.from(
      json.decode(str)['services'].map(
            (x) => ServicesList.fromJson(x),
          ),
    );

String servicesListToJson(List<ServicesList> data) => json.encode(
      List<dynamic>.from(
        data.map(
          (x) => x.toJson(),
        ),
      ),
    );

class ServicesList {
  ServicesList({
    required this.id,
    required this.name,
  });

  int id;
  String name;

  factory ServicesList.fromJson(Map<String, dynamic> response) {
    return ServicesList(
      id: response["id"],
      name: response["name"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
      };
}
