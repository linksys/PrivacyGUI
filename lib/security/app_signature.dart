import 'package:equatable/equatable.dart';

List<CloudAppSignature> mappingAppSignature(
    List<dynamic> source, List<dynamic> mapped) {
  final sourceList = List<MapEntry<String, AppSignature>>.from(source
      .map((e) => AppSignature.fromJson(e))
      .map((e) => MapEntry<String, AppSignature>(e.id, e)));
  final Map<String, AppSignature> sourceMap = Map.fromEntries(sourceList);

  final mappedList = List<MapEntry<String, CloudAppSignature>>.from(mapped
      .map((e) => CloudAppSignature.fromJson(e))
      .map((e) => MapEntry(e.id, e)));
  final Map<String, CloudAppSignature> mappedMap = Map.fromEntries(mappedList);

  final result = sourceMap.map((key, value) => MapEntry(
        key,
        mappedMap.containsKey(key)
            ? mappedMap[key]!.copyWithAppSignature(signature: value)
            : CloudAppSignature.fromAppSignature(value),
      ));

  return List.from(result.values);
}

class SecurityPresetSignatures {
  const SecurityPresetSignatures(
      {required this.name, required this.identifier, required this.signatures});

  final String name;
  final String identifier;
  final List<CloudAppSignature> signatures;
}

///
///   {
///     "name": "GTunnel",
///     "id": "17540",
///     "category": "6",
///     "popularity": "1",
///     "risk": "5",
///     "weight": "10",
///     "technology": "2.Client-Server",
///     "behavior": "6.Tunneling",
///     "protocol": "1.TCP, 9.HTTP"
///   }
class AppSignature extends Equatable {
  const AppSignature({
    required this.name,
    required this.id,
    required this.category,
    required this.popularity,
    required this.risk,
    required this.weight,
    required this.technology,
    required this.behavior,
    required this.protocol,
  });

  factory AppSignature.fromJson(Map<String, dynamic> json) {
    return AppSignature(
      name: json['name'],
      id: json['id'],
      category: json['category'],
      popularity: json['popularity'],
      risk: json['risk'],
      weight: json['weight'],
      technology: json['technology'],
      behavior: json['behavior'],
      protocol: json['protocol'],
    );
  }

  final String name;
  final String id;
  final String category;
  final String popularity;
  final String risk;
  final String weight;
  final String technology;
  final String behavior;
  final String protocol;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'category': category,
      'popularity': popularity,
      'risk': risk,
      'weight': weight,
      'technology': technology,
      'behavior': behavior,
      'protocol': protocol,
    };
  }

  AppSignature copyWith({
    String? name,
    String? id,
    String? category,
    String? popularity,
    String? risk,
    String? weight,
    String? technology,
    String? behavior,
    String? protocol,
  }) {
    return AppSignature(
      name: name ?? this.name,
      id: id ?? this.id,
      category: category ?? this.category,
      popularity: popularity ?? this.popularity,
      risk: risk ?? this.risk,
      weight: weight ?? this.weight,
      technology: technology ?? this.technology,
      behavior: behavior ?? this.behavior,
      protocol: protocol ?? this.protocol,
    );
  }

  @override
  List<Object?> get props => [
        name,
        id,
        category,
        popularity,
        risk,
        weight,
        technology,
        behavior,
        protocol
      ];
}

/// {
///     "name": "126.Mail",
///     "id": 16554,
///     "categoryName": "Email",
///     "category": 21,
///     "behavior": "",
///     "language": "Chinese",
///     "popularity": 4,
///     "risk": 3,
///     "technology": "Browser-Based",
///     "vendor": "Netease",
///     "isCloud": "No",
///     "requireSSLInspection": "No"
///   }
class CloudAppSignature extends AppSignature {
  const CloudAppSignature({
    required super.name,
    required super.id,
    required super.category,
    required super.popularity,
    required super.risk,
    required super.weight,
    required super.technology,
    required super.behavior,
    required super.protocol,
    required this.categoryName,
    required this.language,
    required this.vendor,
    required this.isCloud,
    required this.requireSSLInspection,
  });

  factory CloudAppSignature.fromJson(Map<String, dynamic> json) {
    return CloudAppSignature(
      name: json['name'],
      id: json['id'].toString(),
      category: json['category'],
      popularity: json['popularity'],
      risk: json['risk'],
      weight: '',
      // Cloud app signature doesn't have weight
      technology: json['technology'],
      behavior: json['behavior'],
      protocol: '',
      // Cloud app signature doesn't have protocol
      isCloud: json['isCloud'],
      categoryName: json['categoryName'],
      language: json['language'],
      requireSSLInspection: json['requireSSLInspection'],
      vendor: json['vendor'],
    );
  }

  factory CloudAppSignature.fromAppSignature(AppSignature signature) {
    return CloudAppSignature(
      name: signature.name,
      id: signature.id,
      category: signature.category,
      popularity: signature.popularity,
      risk: signature.risk,
      weight: signature.weight,
      technology: signature.technology,
      behavior: signature.behavior,
      protocol: signature.protocol,
      isCloud: '',
      categoryName: '',
      language: '',
      requireSSLInspection: '',
      vendor: '',
    );
  }

  final String categoryName;
  final String language;
  final String vendor;
  final String isCloud;
  final String requireSSLInspection;

  @override
  Map<String, dynamic> toJson() {
    return super.toJson()
      ..addAll({
        'isCloud': isCloud,
        'categoryName': categoryName,
        'language': language,
        'requireSSLInspection': requireSSLInspection,
        'vendor': vendor,
      });
  }

  @override
  CloudAppSignature copyWith({
    String? name,
    String? id,
    String? category,
    String? popularity,
    String? risk,
    String? weight,
    String? technology,
    String? behavior,
    String? protocol,
    String? categoryName,
    String? language,
    String? vendor,
    String? isCloud,
    String? requireSSLInspection,
  }) {
    return CloudAppSignature(
      name: name ?? this.name,
      id: id ?? this.id,
      category: category ?? this.category,
      popularity: popularity ?? this.popularity,
      risk: risk ?? this.risk,
      weight: weight ?? this.weight,
      technology: technology ?? this.technology,
      behavior: behavior ?? this.behavior,
      protocol: protocol ?? this.protocol,
      isCloud: isCloud ?? this.isCloud,
      categoryName: categoryName ?? this.categoryName,
      language: language ?? this.language,
      requireSSLInspection: requireSSLInspection ?? this.requireSSLInspection,
      vendor: vendor ?? this.vendor,
    );
  }

  CloudAppSignature copyWithAppSignature({required AppSignature signature}) {
    return CloudAppSignature(
      name: signature.name,
      id: signature.id,
      category: signature.category,
      popularity: signature.popularity,
      risk: signature.risk,
      weight: signature.weight,
      technology: signature.technology,
      behavior: signature.behavior,
      protocol: signature.protocol,
      isCloud: isCloud,
      categoryName: categoryName,
      language: language,
      requireSSLInspection: requireSSLInspection,
      vendor: vendor,
    );
  }

  @override
  List<Object?> get props => super.props
    ..addAll([isCloud, categoryName, language, requireSSLInspection, vendor]);
}
