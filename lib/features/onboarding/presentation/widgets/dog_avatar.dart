import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/pixel_theme.dart';
import '../../../pet/application/pet_providers.dart';
import '../../../pet/presentation/widgets/parts_dog.dart';

/// 온보딩 초안을 반영하는 원형 강아지 아바타(게임과 같은 파츠로 조립).
class DraftDogAvatar extends ConsumerWidget {
  const DraftDogAvatar({super.key, this.size = 160});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(onboardingProvider);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.creamPanel,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: PartsDog(
        furColor: Color(d.furColorValue ?? AppColors.furColors[0].toARGB32()),
        eyeStyle: d.eyeStyle,
        noseStyle: d.noseStyle,
        mouthStyle: d.mouthStyle,
        // 앉은 자세는 세로로 길어, 원 안에 여백이 남게 높이를 잡는다.
        height: size * 0.76,
      ),
    );
  }
}
