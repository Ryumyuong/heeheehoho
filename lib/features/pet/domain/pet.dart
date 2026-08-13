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
    this.paws = 0,
    this.bones = 0,
    this.happiness = 70, // 행복도
    this.hunger = 60, // 배고픔(포만도)
    this.fatigue = 40, // 피로도
    this.equippedItems = const [],
    this.placements = const {},
    this.placementScales = const {},
    this.ownedItems = const [],
    this.ownerNickname = '',
    this.statsAt,
  });

  final String name;
  final Gender gender;
  final DateTime birthday;
  final BodyShape bodyShape;
  final int furColorValue; // Color.toARGB32() 저장 (Hive 직렬화 용이)
  final EyeStyle eyeStyle;
  final NoseStyle noseStyle;
  final MouthStyle mouthStyle;

  /// 발자국: 미니룸 아이템(가구·코스튬)을 사는 데 쓰는 화폐. 돌보기로 모은다.
  final int paws;

  /// 뼈다귀: 마켓에서 실제 물품을 사는 데 쓰는 화폐.
  final int bones;

  final int happiness;
  final int hunger;
  final int fatigue;

  /// 장착/배치된 아이템 id 목록.
  final List<String> equippedItems;

  /// 배치된 가구의 정규화 좌표(0~1) : id -> 화면 비율 위치.
  final Map<String, Offset> placements;

  /// 배치된 가구의 크기 배율 : id -> scale(기본 1.0). 없으면 1.0으로 처리.
  final Map<String, double> placementScales;

  /// 스토어에서 구매해 보유한 아이템 id 목록. 홈 아이템창의 잠금 해제 기준.
  final List<String> ownedItems;

  /// 상태값(애정도·포만감·피로도)을 마지막으로 계산한 시각.
  /// 앱을 껐다 켜도 그동안 흐른 시간만큼 변화를 반영하려고 들고 있는다.
  /// 예전 저장본에는 없어서 null이면 "지금"으로 보고 시작한다.
  final DateTime? statsAt;

  /// 주인(사람)의 닉네임. 커뮤니티에서 나를 가리키는 이름이라 **중복 불가**로
  /// 온보딩에서 검사·예약한다. 강아지 이름([name])은 중복을 허용한다.
  final String ownerNickname;

  Color get furColor => Color(furColorValue);

  Pet copyWith({
    String? name,
    int? paws,
    int? bones,
    int? happiness,
    int? hunger,
    int? fatigue,
    List<String>? equippedItems,
    Map<String, Offset>? placements,
    Map<String, double>? placementScales,
    List<String>? ownedItems,
    String? ownerNickname,
    DateTime? statsAt,
  }) =>
      Pet(
        name: name ?? this.name,
        ownerNickname: ownerNickname ?? this.ownerNickname,
        statsAt: statsAt ?? this.statsAt,
        gender: gender,
        birthday: birthday,
        bodyShape: bodyShape,
        furColorValue: furColorValue,
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
        paws: paws ?? this.paws,
        bones: bones ?? this.bones,
        happiness: (happiness ?? this.happiness).clamp(0, 100),
        hunger: (hunger ?? this.hunger).clamp(0, 100),
        fatigue: (fatigue ?? this.fatigue).clamp(0, 100),
        equippedItems: equippedItems ?? this.equippedItems,
        placements: placements ?? this.placements,
        placementScales: placementScales ?? this.placementScales,
        ownedItems: ownedItems ?? this.ownedItems,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerNickname': ownerNickname,
        'statsAt': statsAt?.millisecondsSinceEpoch,
        'gender': gender.index,
        'birthday': birthday.millisecondsSinceEpoch,
        'bodyShape': bodyShape.index,
        'furColorValue': furColorValue,
        'eyeStyle': eyeStyle.index,
        'noseStyle': noseStyle.index,
        'mouthStyle': mouthStyle.index,
        'paws': paws,
        'bones': bones,
        'happiness': happiness,
        'hunger': hunger,
        'fatigue': fatigue,
        'equippedItems': equippedItems,
        'placements':
            placements.map((k, v) => MapEntry(k, [v.dx, v.dy])),
        'placementScales': placementScales,
        'ownedItems': ownedItems,
      };

  factory Pet.fromMap(Map<dynamic, dynamic> m) {
    final equipped =
        (m['equippedItems'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final placements = _placementsFromMap(m['placements']);
    // ownedItems가 없는 구버전 저장본은 이미 쓰던 아이템을 보유로 이관.
    final owned = m.containsKey('ownedItems')
        ? ((m['ownedItems'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[])
        : {...equipped, ...placements.keys}.toList();
    return Pet(
      name: m['name'] as String? ?? '몽치',
      // 닉네임이 없던 구버전 저장본은 빈 값 → 프로필에서 강아지 이름으로 대체한다.
      ownerNickname: m['ownerNickname'] as String? ?? '',
      statsAt: (m['statsAt'] as num?) == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((m['statsAt'] as num).toInt()),
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
      // 'points'는 발자국·뼈다귀로 나뉘기 전의 옛 키. 구버전 저장본은 발자국으로 이관.
      paws: (m['paws'] as num?)?.toInt() ??
          (m['points'] as num?)?.toInt() ??
          0,
      bones: (m['bones'] as num?)?.toInt() ?? 0,
      happiness: (m['happiness'] as num?)?.toInt() ?? 70,
      hunger: (m['hunger'] as num?)?.toInt() ?? 60,
      fatigue: (m['fatigue'] as num?)?.toInt() ?? 40,
      equippedItems: equipped,
      placements: placements,
      placementScales: _scalesFromMap(m['placementScales']),
      ownedItems: owned,
    );
  }

  static Map<String, Offset> _placementsFromMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, Offset>{};
    raw.forEach((k, v) {
      if (v is List && v.length >= 2) {
        out[k.toString()] = Offset(
          (v[0] as num).toDouble(),
          (v[1] as num).toDouble(),
        );
      }
    });
    return out;
  }

  static Map<String, double> _scalesFromMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, double>{};
    raw.forEach((k, v) {
      if (v is num) out[k.toString()] = v.toDouble();
    });
    return out;
  }
}

/// 온보딩 동안 단계별로 채워지는 가변 초안.
class PetDraft {
  PetDraft({
    this.hasExistingPet,
    this.photoPath,
    this.fromPhoto = false,
    this.bodyShape = BodyShape.round,
    this.furColorValue,
    this.eyeStyle = EyeStyle.round,
    this.noseStyle = NoseStyle.triangle,
    this.mouthStyle = MouthStyle.smile,
    this.name = '',
    this.gender,
    this.birthday,
    this.ownerNickname = '',
  });

  bool? hasExistingPet;
  String? photoPath;

  /// 아래 외형 값들이 사진 분석으로 미리 채워졌는지. 커스터마이즈 화면에서
  /// "사진에서 찾은 특징" 안내를 띄울지 판단하는 데만 쓴다.
  bool fromPhoto;

  BodyShape bodyShape;
  int? furColorValue;
  EyeStyle eyeStyle;
  NoseStyle noseStyle;
  MouthStyle mouthStyle;
  String name;
  Gender? gender;
  DateTime? birthday;

  /// 주인(사람) 닉네임. 강아지 정보 다음 단계에서 받는다.
  String ownerNickname;

  PetDraft copy() => PetDraft(
        hasExistingPet: hasExistingPet,
        photoPath: photoPath,
        fromPhoto: fromPhoto,
        bodyShape: bodyShape,
        furColorValue: furColorValue,
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
        name: name,
        gender: gender,
        birthday: birthday,
        ownerNickname: ownerNickname,
      );

  Pet finalize() => Pet(
        name: name.isEmpty ? '몽치' : name,
        ownerNickname: ownerNickname,
        gender: gender ?? Gender.princess,
        birthday: birthday ?? DateTime.now(),
        bodyShape: bodyShape,
        furColorValue: furColorValue ?? AppColors.furColors[0].toARGB32(),
        eyeStyle: eyeStyle,
        noseStyle: noseStyle,
        mouthStyle: mouthStyle,
      );
}
