// heeheehoho 위젯 스모크 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixel_pet/features/pet/domain/pet.dart';
import 'package:pixel_pet/features/pet/presentation/widgets/pixel_dog.dart';

void main() {
  testWidgets('픽셀 강아지 얼굴이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PixelDogFace(
              furColor: Color(0xFFF2F0EB),
              eyeStyle: EyeStyle.sparkle,
              noseStyle: NoseStyle.heart,
              mouthStyle: MouthStyle.grin,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PixelDogFace), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  test('PetDraft가 Pet으로 완성된다', () {
    final draft = PetDraft(name: '세미', gender: Gender.princess);
    final pet = draft.finalize();
    expect(pet.name, '세미');
    expect(pet.gender, Gender.princess);
  });
}
