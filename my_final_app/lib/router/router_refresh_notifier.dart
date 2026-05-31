import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../presentation/providers/auth_notifier.dart';

part 'router_refresh_notifier.g.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authNotifierProvider, (prev, next) => notifyListeners());
  }
}

@Riverpod(keepAlive: true)
RouterRefreshNotifier routerRefreshNotifier(RouterRefreshNotifierRef ref) {
  return RouterRefreshNotifier(ref);
}
