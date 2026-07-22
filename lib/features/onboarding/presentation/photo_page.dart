import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/utils/photo_analysis.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import 'widgets/back_step_bar.dart';

class PhotoPage extends ConsumerStatefulWidget {
  const PhotoPage({super.key});

  @override
  ConsumerState<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends ConsumerState<PhotoPage> {
  bool _analyzing = false;

  Future<void> _pick(ImageSource source) async {
    try {
      final XFile? file =
          await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (file == null) return; // 사용자가 취소

      setState(() => _analyzing = true);
      final bytes = await File(file.path).readAsBytes();
      final guess = await analyzeDogPhoto(bytes);

      ref.read(onboardingProvider.notifier).update((d) {
        d.photoPath = file.path;
        if (guess != null) {
          d.fromPhoto = true;
          d.furColorValue = guess.furColorValue;
          d.bodyShape = guess.bodyShape;
          d.mouthStyle = guess.mouthStyle;
        }
      });

      if (!mounted) return;
      // 분석에 성공하면 스캔 결과를 먼저 보여주고(마음에 들면 그대로 진행,
      // 아니면 '조금 더 다듬기'로 커스터마이즈), 실패했으면 보여줄 결과가 없으니
      // 기본 외형인 채로 커스터마이즈로 바로 보낸다.
      context.push(guess == null ? '/customize' : '/scan');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 불러오지 못했어요. 권한을 확인해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                  const SizedBox(height: 12),
                  Text(
                    '사진 속 털색과 몸 모양을 찾아 미리 꾸며드려요',
                    textAlign: TextAlign.center,
                    style:
                        AppText.body(size: 13, color: const Color(0xFF888888)),
                  ),
                  const Spacer(flex: 2),
                  FilledPillButton(
                    label: '사진 촬영하기',
                    iconAsset: 'assets/images/icon_camera.png',
                    color: const Color(0xFFFC9340),
                    onPressed:
                        _analyzing ? null : () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 14),
                  OutlinedPillButton(
                    label: '갤러리에서 선택',
                    iconAsset: 'assets/images/icon_gallery.png',
                    textColor: const Color(0xCC000000), // #000 80%
                    fontWeight: FontWeight.w500,
                    borderColor: const Color(0xFFE9E9E9),
                    borderWidth: 1.4,
                    onPressed:
                        _analyzing ? null : () => _pick(ImageSource.gallery),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
            if (_analyzing)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xCCFFFFFF),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text('사진을 살펴보는 중…', style: AppText.body(size: 14)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
