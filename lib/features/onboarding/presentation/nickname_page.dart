import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/pixel_theme.dart';
import '../../pet/application/pet_providers.dart';
import '../../community/data/user_directory.dart';
import '../data/nickname_service.dart';
import 'widgets/back_step_bar.dart';

/// 온보딩 마지막 단계: 주인(사람)의 닉네임.
///
/// 커뮤니티에서 나를 가리키는 이름이라 **중복을 허용하지 않는다**.
/// 강아지 이름([InfoPage])은 중복을 허용한다 — 같은 이름의 강아지는 흔하다.
class NicknamePage extends ConsumerStatefulWidget {
  const NicknamePage({super.key});

  @override
  ConsumerState<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends ConsumerState<NicknamePage> {
  final _ctrl = TextEditingController();

  Timer? _debounce;
  String? _error; // 보여줄 오류(중복·형식). 없으면 null.
  bool _checking = false; // 서버 확인 중
  bool _ok = false; // 형식·중복 모두 통과
  bool _saving = false; // 완성 처리 중(중복 탭 방지)

  @override
  void initState() {
    super.initState();
    _ctrl.text = ref.read(onboardingProvider).ownerNickname;
    _ctrl.addListener(_onChanged);
    if (_ctrl.text.trim().isNotEmpty) _scheduleCheck();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _ok = false;
      _error = null;
    });
    _scheduleCheck();
  }

  /// 타이핑이 멈추면(400ms) 형식·중복을 검사한다.
  void _scheduleCheck() {
    _debounce?.cancel();
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() {
        _checking = false;
        _ok = false;
        _error = null;
      });
      return;
    }
    // 형식 오류는 즉시.
    final fmt = NicknameService.formatError(name);
    if (fmt != null) {
      setState(() {
        _checking = false;
        _ok = false;
        _error = fmt;
      });
      return;
    }
    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final svc = ref.read(nicknameServiceProvider);
      bool taken = false;
      try {
        taken = await svc.isTaken(name);
      } catch (_) {
        taken = false; // 검사 실패 시 통과(온보딩 안 막음)
      }
      if (!mounted || _ctrl.text.trim() != name) return;
      setState(() {
        _checking = false;
        _ok = !taken;
        _error = taken ? '이미 사용중인 닉네임입니다' : null;
      });
    });
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    final name = _ctrl.text.trim();
    final svc = ref.read(nicknameServiceProvider);

    // 완성 직전 한 번 더 중복 확인(디바운스 사이에 남이 선점했을 수 있음).
    bool taken = false;
    try {
      taken = await svc.isTaken(name);
    } catch (_) {
      taken = false;
    }
    if (!mounted) return;
    if (taken) {
      setState(() {
        _saving = false;
        _ok = false;
        _error = '이미 사용중인 닉네임입니다';
      });
      return;
    }
    await svc.reserve(name); // 닉네임 예약(등록)

    final ctrl = ref.read(onboardingProvider.notifier);
    ctrl.update((d) => d.ownerNickname = name);
    final pet = await ctrl.complete();
    // 가입자 명부에 올린다(이웃 목록의 "최근 가입"과 닉네임 검색이 이걸 본다).
    try {
      await ref.read(userDirectoryProvider).upsertMe(
            nickname: name,
            petName: pet.name,
          );
    } catch (_) {
      // 명부 등록에 실패해도 앱 진입은 막지 않는다.
    }
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
                    const SizedBox(height: 60),
                    Center(
                      child: Text(
                        '희희호호를 시작하기 전에,\n닉네임을 알려주세요!',
                        textAlign: TextAlign.center,
                        style: AppText.pixel(size: 22, height: 1.7),
                      ),
                    ),
                    const SizedBox(height: 56),
                    Text('닉네임',
                        style:
                            AppText.body(size: 15, weight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    _PillField(
                      controller: _ctrl,
                      hint: 'ex) 뭉지언니',
                      error: _error != null,
                    ),
                    // 중복·형식 오류 / 확인 중 안내.
                    if (_error != null || _checking) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _error ?? '확인 중...',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: _error != null
                                ? AppColors.coral
                                : AppColors.subtle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_ok)
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

/// 정보입력 화면과 같은 알약 입력칸.
class _PillField extends StatelessWidget {
  const _PillField({
    required this.controller,
    required this.hint,
    this.error = false,
  });

  final TextEditingController controller;
  final String hint;

  /// true면 테두리를 빨갛게(중복·형식 오류).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final normal = error ? AppColors.coral : AppColors.line;
    final focused = error ? AppColors.coral : AppColors.primary;
    return TextField(
      controller: controller,
      maxLength: 8,
      textAlign: TextAlign.center,
      style: AppText.body(size: 15, color: AppColors.ink),
      decoration: InputDecoration(
        counterText: '', // 8자 카운터 숨김
        hintText: hint,
        hintStyle: AppText.body(size: 15, color: AppColors.subtle),
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
