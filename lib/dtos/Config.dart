class Config {
  final String name;
  final String model;
  final String message;

  Config({required this.name, required this.model, required this.message});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      name: json['name'],
      model: json['model'],
      message: json['message'],
    );
  }
}

class AllConfig {
  final String name;
  final String id;

  AllConfig({required this.name, required this.id});

  factory AllConfig.fromJson(Map<String, dynamic> json) {
    return AllConfig(
      name: json['name'],
      id: json['id'],
    );
  }
}