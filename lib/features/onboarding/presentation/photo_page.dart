import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import 'widgets/back_step_bar.dart';

class PhotoPage extends ConsumerWidget {
  const PhotoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> pick(ImageSource source) async {
      try {
        final XFile? file =
            await ImagePicker().pickImage(source: source, imageQuality: 85);
        if (file == null) return; // 사용자가 취소
        ref.read(onboardingProvider.notifier).update((d) => d.photoPath = file.path);
        if (context.mounted) context.push('/scan');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 불러오지 못했어요. 권한을 확인해 주세요.')),
          );
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const BackStepBar(),
              const Spacer(flex: 3),
              Text(
                '당신의 네발친구를\n소개해주세요',
                textAlign: TextAlign.center,
                style: AppText.pixel(size: 24, height: 1.6),
              ),
              const Spacer(flex: 2),
              FilledPillButton(
                label: '사진 촬영하기',
                iconAsset: 'assets/images/icon_camera.png',
                color: const Color(0xFFFC9340),
                onPressed: () => pick(ImageSource.camera),
              ),
              const SizedBox(height: 14),
              OutlinedPillButton(
                label: '갤러리에서 선택',
                iconAsset: 'assets/images/icon_gallery.png',
                textColor: const Color(0xCC000000), // #000 80%
                fontWeight: FontWeight.w500,
                borderColor: const Color(0xFFE9E9E9),
                borderWidth: 1.4,
                onPressed: () => pick(ImageSource.gallery),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
