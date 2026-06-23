import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/pixel_theme.dart';
import '../../../pet/application/pet_providers.dart';
import '../../../pet/presentation/widgets/pixel_dog.dart';

/// 온보딩 초안을 반영하는 원형 강아지 얼굴 아바타.
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
      child: PixelDogFace(
        furColor: Color(d.furColorValue ?? AppColors.furColors[0].toARGB32()),
        eyeStyle: d.eyeStyle,
        noseStyle: d.noseStyle,
        mouthStyle: d.mouthStyle,
        size: size * 0.62,
      ),
    );
  }
}
