import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fixtures.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/strings.dart';

class SessionState {
  final DemoUser? user;
  final bool arabic;
  final String dataMode;
  final String streamId;

  const SessionState({
    this.user,
    this.arabic = true,
    this.dataMode = 'demo',
    this.streamId = 'demo-main',
  });

  bool get authenticated => user != null;
  WebRole? get role => user?.role;
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  void login(DemoUser user) {
    state = SessionState(
      user: user,
      arabic: state.arabic,
      dataMode: state.dataMode,
      streamId: state.streamId,
    );
  }

  void logout() {
    state = SessionState(arabic: state.arabic);
  }

  void setArabic(bool value) {
    state = SessionState(
      user: state.user,
      arabic: value,
      dataMode: state.dataMode,
      streamId: state.streamId,
    );
  }

  void switchRole(WebRole role) {
    DemoUser? match;
    for (final u in Fixtures.demoUsers) {
      if (u.role == role) {
        match = u;
        break;
      }
    }
    if (match == null || state.user == null) return;
    state = SessionState(
      user: match,
      arabic: state.arabic,
      dataMode: state.dataMode,
      streamId: state.streamId,
    );
  }

  void setDataMode(String mode) {
    state = SessionState(
      user: state.user,
      arabic: state.arabic,
      dataMode: mode,
      streamId: state.streamId,
    );
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
);

final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(arabic: ref.watch(sessionProvider).arabic);
});

final currentUserProvider = Provider<DemoUser?>((ref) {
  return ref.watch(sessionProvider).user;
});
