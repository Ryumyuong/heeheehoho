import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/pet.dart';
import 'widgets/back_step_bar.dart';
import 'widgets/dog_avatar.dart';

class InfoPage extends ConsumerStatefulWidget {
  const InfoPage({super.key});

  @override
  ConsumerState<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends ConsumerState<InfoPage> {
  final _nameCtrl = TextEditingController();
  Gender? _gender;
  DateTime? _birthday;
  bool _today = false;

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingProvider);
    _nameCtrl.text = d.name;
    _gender = d.gender;
    _birthday = d.birthday;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _hasName => _nameCtrl.text.trim().isNotEmpty;
  bool get _hasGender => _gender != null;
  bool get _canFinish => _hasName && _hasGender && _birthday != null;

  int get _activeDot => !_hasName ? 0 : (!_hasGender ? 1 : 2);

  Future<void> _pickDate() async {
    final now = DateTime(2026, 6, 23);
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? now,
      firstDate: DateTime(2005),
      lastDate: now,
      helpText: '생일 선택',
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
        _today = false;
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  Future<void> _finish() async {
    final ctrl = ref.read(onboardingProvider.notifier);
    ctrl.update((d) {
      d.name = _nameCtrl.text.trim();
      d.gender = _gender;
      d.birthday = _birthday;
    });
    await ctrl.complete();
    if (!mounted) return;
    if (ctrl.isGuest) {
      context.push('/signup');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(height: 8),
                    StepDots(count: 3, active: _activeDot),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        '네발친구의\n정보를 입력해 주세요',
                        textAlign: TextAlign.center,
                        style: AppText.pixel(size: 24, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Center(child: DraftDogAvatar(size: 140)),
                    const SizedBox(height: 28),

                    // 이름
                    _Label('이름'),
                    const SizedBox(height: 10),
                    _PillField(
                      controller: _nameCtrl,
                      hint: 'ex) 뭉치',
                      onSubmitted: (_) {},
                    ),

                    // 성별 (이름 입력 후 노출)
                    if (_hasName) ...[
                      const SizedBox(height: 24),
                      _Label('성별'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SelectChip(
                              label: '공주님',
                              selected: _gender == Gender.princess,
                              onTap: () =>
                                  setState(() => _gender = Gender.princess),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SelectChip(
                              label: '왕자님',
                              selected: _gender == Gender.prince,
                              onTap: () =>
                                  setState(() => _gender = Gender.prince),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // 생일 (성별 선택 후 노출)
                    if (_hasName && _hasGender) ...[
                      const SizedBox(height: 24),
                      _Label('생일'),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _PillField(
                            controller: TextEditingController(
                              text: _birthday == null ? '' : _fmt(_birthday!),
                            ),
                            hint: 'ex) 2026.06.13',
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _today,
                              activeColor: AppColors.primary,
                              onChanged: (v) => setState(() {
                                _today = v ?? false;
                                if (_today) _birthday = DateTime(2026, 6, 23);
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('생일을 오늘로 선택할게요',
                              style: AppText.body(
                                  size: 13, color: AppColors.subtle)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_canFinish)
              GestureDetector(
                onTap: _finish,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text('완성하기',
                          style: AppText.body(
                              size: 17,
                              color: Colors.white,
                              weight: FontWeight.w700)),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.body(size: 15, weight: FontWeight.w800));
}

class _PillField extends StatelessWidget {
  const _PillField({
    required this.controller,
    required this.hint,
    this.icon,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textAlign: icon == null ? TextAlign.center : TextAlign.start,
      style: AppText.body(size: 15, color: AppColors.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(size: 15, color: AppColors.subtle),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: AppColors.subtle),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.line, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
