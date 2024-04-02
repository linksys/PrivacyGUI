// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

const tempData = {
  "subject": "Here's what we are working on next...",
  "contents": [
    {
      "category": "Features",
      "items": [
        {
          "title": "Privacy Pledge",
          "body":
              "We DO NOT monitor, collect, or store your browsing and application use data."
        },
        {
          "title": "Linksys Cognitive™ Mesh",
          "body":
              "Set up your reliable whole home mesh system in a matter of minutes."
        },
        {
          "title": "Linksys Cognitive™ Experience",
          "body":
              "Make your connectivity issues disappear like magic with the Linksys support team."
        },
        {
          "title": "Safe Browsing",
          "body": "Block adult content with a single tap."
        }
      ]
    },
    {
      "category": "Products",
      "items": [
        {
          "title": "New WiFi 6e Routers",
          "body":
              "Blazing fast and reliable connectivity with the latest WiFi 6e laptops, tablets and smartphones."
        }
      ]
    }
  ]
};

class CloudLinkUpModel extends Equatable {
  final String locale;
  final String subject;
  final List<CloudLinkupContent> contents;
  const CloudLinkUpModel({
    required this.locale,
    required this.subject,
    required this.contents,
  });

  CloudLinkUpModel copyWith({
    String? locale,
    String? subject,
    List<CloudLinkupContent>? contents,
  }) {
    return CloudLinkUpModel(
      locale: locale ?? this.locale,
      subject: subject ?? this.subject,
      contents: contents ?? this.contents,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'locale': locale,
      'data': {
        'subject': subject,
        'contents': contents.map((x) => x.toMap()).toList(),
      },
    };
  }

  factory CloudLinkUpModel.fromMap(Map<String, dynamic> map) {
    return CloudLinkUpModel(
      locale: map['locale'] as String,
      subject: map['data']['subject'] as String,
      contents: List<CloudLinkupContent>.from(
        map['data']['contents'].map<CloudLinkupContent>(
          (x) => CloudLinkupContent.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudLinkUpModel.fromJson(String source) =>
      CloudLinkUpModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [locale, subject, contents];
}

class CloudLinkupContent extends Equatable {
  final String category;
  final List<CloudLinkupItem> items;
  const CloudLinkupContent({
    required this.category,
    required this.items,
  });

  CloudLinkupContent copyWith({
    String? category,
    List<CloudLinkupItem>? items,
  }) {
    return CloudLinkupContent(
      category: category ?? this.category,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'category': category,
      'items': items.map((x) => x.toMap()).toList(),
    };
  }

  factory CloudLinkupContent.fromMap(Map<String, dynamic> map) {
    return CloudLinkupContent(
      category: map['category'] as String,
      items: List<CloudLinkupItem>.from(
        map['items'].map<CloudLinkupItem>(
          (x) => CloudLinkupItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudLinkupContent.fromJson(String source) =>
      CloudLinkupContent.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [category, items];
}

class CloudLinkupItem extends Equatable {
  final String title;
  final String body;
  const CloudLinkupItem({
    required this.title,
    required this.body,
  });

  CloudLinkupItem copyWith({
    String? title,
    String? body,
  }) {
    return CloudLinkupItem(
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
    };
  }

  factory CloudLinkupItem.fromMap(Map<String, dynamic> map) {
    return CloudLinkupItem(
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudLinkupItem.fromJson(String source) =>
      CloudLinkupItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [title, body];
}
