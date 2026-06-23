import 'package:flutter/material.dart';
import '../../../core/theme/pixel_theme.dart';

/// 강아지 외형/정체성. 온보딩에서 수집되어 홈에서 사용된다.
enum BodyShape { round, long, fluffy }

enum EyeStyle { round, sparkle, sleepy }

enum NoseStyle { triangle, round, heart }

enum MouthStyle { smile, tongue, grin }

enum Gender { princess, prince } // 공주님 / 왕자님

extension BodyShapeLabel on BodyShape {
  String get label => switch (this) {
        BodyShape.round => '둥근몸',
        BodyShape.long => '긴몸',
        BodyShape.fluffy => '복실복실',
      };
}

extension EyeStyleLabel on EyeStyle {
  String get label => switch (this) {
        EyeStyle.round => '둥근눈',
        EyeStyle.sparkle => '반짝눈',
        EyeStyle.sleepy => '졸린눈',
      };
}

extension NoseStyleLabel on NoseStyle {
  String get label => switch (this) {
        NoseStyle.triangle => '삼각코',
        NoseStyle.round => '둥근코',
        NoseStyle.heart => '하트코',
      };
}

extension MouthStyleLabel on MouthStyle {
  String get label => switch (this) {
        MouthStyle.smile => '미소',
        MouthStyle.tongue => '혀내밀기',
        MouthStyle.grin => '활짝웃음',
      };
}

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.princess => '공주님',
        Gender.prince => '왕자님',
      };
}

/// 완성된 펫.
class Pet {
  const Pet({
    required this.name,
    required this.gender,
    required this.birthday,
    required this.bodyShape,
    required this.furColorValue,
    required this.eyeStyle,
    required this.noseStyle,
    required this.mouthStyle,
    this.points = 1250,
    this.happiness = 70, // 행복도
    this.hunger = 60, // 배고픔(포만도)
    this.fatigue = 40, // 피로도
    this.equippedItems = const [],
  });

  final String name;
  final Gender gender;
  final DateTime birthday;
  final BodyShape bodyShape;
  final int furColorValue; // Color.toARGB32() 저장 (Hive 직렬화 용이)
  final EyeStyle eyeStyle;
  final NoseStyle noseStyle;
  final MouthStyle mouthStyle;
  final int points;
  final int happiness;
  final int hunger;
  final int fatigue;

  /// 장착/배치된 아이템 id 목록.
  final List<String> equippedItems;

  Color get furColor => Color(furColorValue);

  Pet copyWith({
    String? name,
    int? points,
    int? happiness,
    int? hunger,
    int? fatigue,
    List<String>? equippedItems,
  }) =>
      Pet(
        name: name ?? this.name,
        gender: gender,
        birthday: birthday,
        bodyShape: bodyShape,
        furColorValue: furColorValue,
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
        points: points ?? this.points,
        happiness: (happiness ?? this.happiness).clamp(0, 100),
        hunger: (hunger ?? this.hunger).clamp(0, 100),
        fatigue: (fatigue ?? this.fatigue).clamp(0, 100),
        equippedItems: equippedItems ?? this.equippedItems,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'gender': gender.index,
        'birthday': birthday.millisecondsSinceEpoch,
        'bodyShape': bodyShape.index,
        'furColorValue': furColorValue,
        'eyeStyle': eyeStyle.index,
        'noseStyle': noseStyle.index,
        'mouthStyle': mouthStyle.index,
        'points': points,
        'happiness': happiness,
        'hunger': hunger,
        'fatigue': fatigue,
        'equippedItems': equippedItems,
      };

  factory Pet.fromMap(Map<dynamic, dynamic> m) => Pet(
        name: m['name'] as String? ?? '몽치',
        gender: Gender.values[(m['gender'] as num?)?.toInt() ?? 0],
        birthday: DateTime.fromMillisecondsSinceEpoch(
          (m['birthday'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        bodyShape: BodyShape.values[(m['bodyShape'] as num?)?.toInt() ?? 0],
        furColorValue: (m['furColorValue'] as num?)?.toInt() ??
            AppColors.furColors[0].toARGB32(),
        eyeStyle: EyeStyle.values[(m['eyeStyle'] as num?)?.toInt() ?? 0],
        noseStyle: NoseStyle.values[(m['noseStyle'] as num?)?.toInt() ?? 0],
        mouthStyle: MouthStyle.values[(m['mouthStyle'] as num?)?.toInt() ?? 0],
        points: (m['points'] as num?)?.toInt() ?? 1250,
        happiness: (m['happiness'] as num?)?.toInt() ?? 70,
        hunger: (m['hunger'] as num?)?.toInt() ?? 60,
        fatigue: (m['fatigue'] as num?)?.toInt() ?? 40,
        equippedItems:
            (m['equippedItems'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
}

/// 온보딩 동안 단계별로 채워지는 가변 초안.
class PetDraft {
  PetDraft({
    this.hasExistingPet,
    this.photoPath,
    this.bodyShape = BodyShape.round,
    this.furColorValue,
    this.eyeStyle = EyeStyle.round,
    this.noseStyle = NoseStyle.triangle,
    this.mouthStyle = MouthStyle.smile,
    this.name = '',
    this.gender,
    this.birthday,
  });

  bool? hasExistingPet;
  String? photoPath;
  BodyShape bodyShape;
  int? furColorValue;
  EyeStyle eyeStyle;
  NoseStyle noseStyle;
  MouthStyle mouthStyle;
  String name;
  Gender? gender;
  DateTime? birthday;

  PetDraft copy() => PetDraft(
        hasExistingPet: hasExistingPet,
        photoPath: photoPath,
        bodyShape: bodyShape,
        furColorValue: furColorValue,
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
        name: name,
        gender: gender,
        birthday: birthday,
      );

  Pet finalize() => Pet(
        name: name.isEmpty ? '몽치' : name,
        gender: gender ?? Gender.princess,
        birthday: birthday ?? DateTime.now(),
        bodyShape: bodyShape,
        furColorValue: furColorValue ?? AppColors.furColors[0].toARGB32(),
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
      );
}
