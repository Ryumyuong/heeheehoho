import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../pet/application/pet_providers.dart';
import '../../pet/domain/pet.dart';
import '../data/nickname_service.dart';
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

  // 이름 중복/형식 검사 상태.
  Timer? _checkDebounce;
  String? _nameError; // 보여줄 오류(중복·형식). 없으면 null.
  bool _checking = false; // 서버 확인 중
  bool _nameOk = false; // 형식·중복 모두 통과

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingProvider);
    _nameCtrl.text = d.name;
    _gender = d.gender;
    _birthday = d.birthday;
    _nameCtrl.addListener(_onNameChanged);
    if (_nameCtrl.text.trim().isNotEmpty) _scheduleCheck();
  }

  @override
  void dispose() {
    _checkDebounce?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _nameOk = false;
      _nameError = null;
    });
    _scheduleCheck();
  }

  /// 타이핑이 멈추면(400ms) 형식·중복을 검사한다.
  void _scheduleCheck() {
    _checkDebounce?.cancel();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() {
        _checking = false;
        _nameOk = false;
        _nameError = null;
      });
      return;
    }
    // 형식 오류는 즉시.
    final fmt = NicknameService.formatError(name);
    if (fmt != null) {
      setState(() {
        _checking = false;
        _nameOk = false;
        _nameError = fmt;
      });
      return;
    }
    setState(() => _checking = true);
    _checkDebounce = Timer(const Duration(milliseconds: 400), () async {
      final svc = ref.read(nicknameServiceProvider);
      bool taken = false;
      try {
        taken = await svc.isTaken(name);
      } catch (_) {
        taken = false; // 검사 실패 시 통과(온보딩 안 막음)
      }
      if (!mounted || _nameCtrl.text.trim() != name) return;
      setState(() {
        _checking = false;
        _nameOk = !taken;
        _nameError = taken ? '이미 사용중인 닉네임입니다' : null;
      });
    });
  }

  bool get _hasGender => _gender != null;
  // 이름은 형식·중복 검사를 통과해야(_nameOk) 다음 단계로 넘어간다.
  bool get _canFinish => _nameOk && _hasGender && _birthday != null;

  int get _activeDot => !_nameOk ? 0 : (!_hasGender ? 1 : 2);

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
    final name = _nameCtrl.text.trim();
    // 완성 직전 한 번 더 중복 확인(디바운스 사이에 남이 선점했을 수 있음).
    final svc = ref.read(nicknameServiceProvider);
    if (await svc.isTaken(name)) {
      if (!mounted) return;
      setState(() {
        _nameOk = false;
        _nameError = '이미 사용중인 닉네임입니다';
      });
      return;
    }
    await svc.reserve(name); // 이름 예약(등록)

    final ctrl = ref.read(onboardingProvider.notifier);
    ctrl.update((d) {
      d.name = name;
      d.gender = _gender;
      d.birthday = _birthday;
    });
    await ctrl.complete();
    if (!mounted) return;
    // 비회원도 회원가입 없이 바로 앱으로 진입.
    context.go('/home');
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
                        '프로필에 사용할\n닉네임을 입력해주세요.',
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
                      error: _nameError != null,
                    ),
                    // 중복·형식 오류 / 확인 중 안내.
                    if (_nameError != null || _checking) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _nameError ?? '확인 중...',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: _nameError != null
                                ? AppColors.coral
                                : AppColors.subtle,
                          ),
                        ),
                      ),
                    ],

                    // 성별 (이름이 통과된 후 노출)
                    if (_nameOk) ...[
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
                    if (_nameOk && _hasGender) ...[
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
    this.error = false,
  });
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final ValueChanged<String>? onSubmitted;

  /// true면 테두리를 빨갛게(중복·형식 오류).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final normal = error ? AppColors.coral : AppColors.line;
    final focused = error ? AppColors.coral : AppColors.primary;
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      // 이름 필드(아이콘 없음)만 8자 제한. 생일 필드는 제한 없음.
      maxLength: icon == null ? 8 : null,
      textAlign: icon == null ? TextAlign.center : TextAlign.start,
      style: AppText.body(size: 15, color: AppColors.ink),
      decoration: InputDecoration(
        counterText: '', // 8자 카운터 숨김
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
          borderSide: BorderSide(color: normal, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: focused, width: 1.6),
        ),
      ),
    );
  }
}
