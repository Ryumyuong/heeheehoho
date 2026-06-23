import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/pet.dart';
import 'widgets/back_step_bar.dart';
import 'widgets/dog_avatar.dart';

class CustomizePage extends ConsumerWidget {
  const CustomizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingProvider);
    final ctrl = ref.read(onboardingProvider.notifier);
    final selectedColor = draft.furColorValue ?? AppColors.furColors[0].toARGB32();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: BackStepBar(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '네발 친구를 소개해 드릴게요!',
                            style: AppText.pixel(size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '나만의 네발 친구를 자유롭게 꾸며보세요',
                            style: AppText.body(size: 14, color: const Color(0xFF888888)),
                          ),
                          const SizedBox(height: 18),
                          const DraftDogAvatar(size: 150),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    _Section(
                      title: '몸 모양',
                      child: _ChipRow(
                        labels: BodyShape.values.map((e) => e.label).toList(),
                        selectedIndex: draft.bodyShape.index,
                        onSelect: (i) =>
                            ctrl.update((d) => d.bodyShape = BodyShape.values[i]),
                      ),
                    ),
                    _Section(
                      title: '색상',
                      child: Row(
                        children: [
                          for (final c in AppColors.furColors)
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: _ColorSwatch(
                                color: c,
                                selected: selectedColor == c.toARGB32(),
                                onTap: () =>
                                    ctrl.update((d) => d.furColorValue = c.toARGB32()),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _Section(
                      title: '눈',
                      child: _ChipRow(
                        labels: EyeStyle.values.map((e) => e.label).toList(),
                        selectedIndex: draft.eyeStyle.index,
                        onSelect: (i) =>
                            ctrl.update((d) => d.eyeStyle = EyeStyle.values[i]),
                      ),
                    ),
                    _Section(
                      title: '코',
                      child: _ChipRow(
                        labels: NoseStyle.values.map((e) => e.label).toList(),
                        selectedIndex: draft.noseStyle.index,
                        onSelect: (i) =>
                            ctrl.update((d) => d.noseStyle = NoseStyle.values[i]),
                      ),
                    ),
                    _Section(
                      title: '입',
                      child: _ChipRow(
                        labels: MouthStyle.values.map((e) => e.label).toList(),
                        selectedIndex: draft.mouthStyle.index,
                        onSelect: (i) =>
                            ctrl.update((d) => d.mouthStyle = MouthStyle.values[i]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '멋진 친구네요! 앞으로의 일상이 기대돼요',
                        style: AppText.body(size: 12, color: AppColors.subtle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 하단 고정 "다음으로" 바
            GestureDetector(
              onTap: () => context.push('/info'),
              child: Container(
                width: double.infinity,
                height: 64,
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '다음으로',
                      style: AppText.body(
                          size: 17, color: Colors.white, weight: FontWeight.w700),
                    ),
                    const Positioned(
                      right: 24,
                      child: Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.body(size: 15, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 10),
              child: SelectChip(
                label: labels[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
