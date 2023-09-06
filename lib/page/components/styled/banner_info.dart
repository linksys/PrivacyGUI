// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_widgets/widgets/banner/banner_style.dart';




class BannerInfo extends Equatable {
 final bool isDiaplay;
 final BannerStyle style;
 final String text;
  const BannerInfo({
    required this.isDiaplay,
    required this.style,
    required this.text,
  });


  BannerInfo copyWith({
    bool? isDiaplay,
    BannerStyle? style,
    String? text,
  }) {
    return BannerInfo(
      isDiaplay: isDiaplay ?? this.isDiaplay,
      style: style ?? this.style,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isDiaplay': isDiaplay,
      'style': style.name,
      'text': text,
    };
  }

  factory BannerInfo.fromMap(Map<String, dynamic> map) {
    return BannerInfo(
      isDiaplay: map['isDiaplay'] as bool,
      style: BannerStyle.values.firstWhereOrNull((value) => value == map['style']) ?? BannerStyle.success,
      text: map['text'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory BannerInfo.fromJson(String source) => BannerInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isDiaplay, style, text];
}
