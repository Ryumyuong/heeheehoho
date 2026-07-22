import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/market_item.dart';

/// 이번 달 기부 캠페인의 현재 상태.
///
/// 진행률(%)·게이지·"N마리 구조 완료" 문구가 모두 이 하나의 값에서 나온다.
/// 참여하면 구조 마릿수가 올라가고, 셋이 함께 움직인다.
///
/// 아직 저장하지 않는다(앱을 다시 켜면 초기값으로 돌아간다). 실제 서비스에서는
/// 서버가 들고 있어야 할 값이라, 로컬에 저장해두면 오히려 서버 값과 어긋난다.
class CampaignController extends Notifier<DonationCampaign> {
  @override
  DonationCampaign build() => kCampaign;

  /// 뼈다귀로 캠페인에 참여 — 뼈다귀 1개당 1마리 구조로 반영한다.
  void join(int bones) {
    state = state.withRescued(state.rescued + bones);
  }
}

final campaignProvider = NotifierProvider<CampaignController, DonationCampaign>(
  CampaignController.new,
);

/// 스토어를 열 때 어떤 탭으로 시작할지 요청하는 값.
///
/// 스토어는 셸 안에서 계속 살아있어(indexedStack) 생성자로는 탭을 못 바꾼다.
/// 다른 화면에서 [StoreTabRequest.request]로 값을 남기고 `/store`로 이동하면,
/// 스토어가 그 값을 읽어 해당 탭을 열고 다시 [StoreTabRequest.consume]으로
/// 비운다(1회성).
enum StoreTab { miniroom, market }

class StoreTabRequest extends Notifier<StoreTab?> {
  @override
  StoreTab? build() => null;

  void request(StoreTab tab) => state = tab;
  void consume() => state = null;
}

final storeTabRequestProvider =
    NotifierProvider<StoreTabRequest, StoreTab?>(StoreTabRequest.new);
