import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_queue_service.dart';

final offlineQueueProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService();
});

class SyncState {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;

  const SyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.isSyncing = false,
  });

  SyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    bool? isSyncing,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  late StreamSubscription _subscription;
  Timer? _pollingTimer;

  @override
  SyncState build() {
    _init();
    return const SyncState();
  }

  void _init() {
    // Initial check
    _checkConnectivity();
    _updatePendingCount();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      state = state.copyWith(isOnline: isOnline);
      if (isOnline) {
        _syncNow();
      }
    });

    // Also poll every 30 seconds just in case
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isOnline) {
        _syncNow();
      }
    });

    ref.onDispose(() {
      _subscription.cancel();
      _pollingTimer?.cancel();
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOnline = !results.contains(ConnectivityResult.none);
    state = state.copyWith(isOnline: isOnline);
    if (isOnline) {
      _syncNow();
    }
  }

  Future<void> _updatePendingCount() async {
    final service = ref.read(offlineQueueProvider);
    final count = await service.getPendingOrdersCount();
    state = state.copyWith(pendingCount: count);
  }

  Future<void> _syncNow() async {
    if (state.isSyncing) return;
    
    // Check if there are any pending items before attempting sync
    await _updatePendingCount();
    if (state.pendingCount == 0) return;

    state = state.copyWith(isSyncing: true);
    final service = ref.read(offlineQueueProvider);
    
    try {
      await service.syncPendingOrders();
    } finally {
      await _updatePendingCount();
      state = state.copyWith(isSyncing: false);
    }
  }
  
  /// Called manually when a new order is added to the queue
  Future<void> notifyOrderAdded() async {
    await _updatePendingCount();
  }

}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
