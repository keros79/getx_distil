import 'package:flutter/material.dart';
import '../rx/rx_types.dart';
import 'obx.dart';

/// Immutable representation of the asynchronous state.
class RxStatus {
  final bool isLoading;
  final bool isSuccess;
  final bool isEmpty;
  final bool isError;
  final String? errorMessage;

  const RxStatus._({
    this.isLoading = false,
    this.isSuccess = false,
    this.isEmpty = false,
    this.isError = false,
    this.errorMessage,
  });

  factory RxStatus.loading() => const RxStatus._(isLoading: true);
  factory RxStatus.success() => const RxStatus._(isSuccess: true);
  factory RxStatus.empty() => const RxStatus._(isEmpty: true);
  factory RxStatus.error(String message) =>
      RxStatus._(isError: true, errorMessage: message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RxStatus &&
        other.isLoading == isLoading &&
        other.isSuccess == isSuccess &&
        other.isEmpty == isEmpty &&
        other.isError == isError &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
        isLoading,
        isSuccess,
        isEmpty,
        isError,
        errorMessage,
      );
}

/// A mixin that can be attached to any controller to manage and programmatically
/// branch an asynchronous data state.
mixin StateMixin<T> {
  final Rx<T?> _state = Rx<T?>(null);
  final Rx<RxStatus> _status = Rx<RxStatus>(RxStatus.loading());

  T? get state => _state.value;
  RxStatus get status => _status.value;

  /// Highly optimized atomic update interface.
  /// If status is passed, updates the status; if newState is passed, updates the state.
  void change(T? newState, {RxStatus? status}) {
    if (status != null) {
      _status.value = status;
    }
    _state.value = newState;
  }

  /// Branching view rendering driven by [Obx] and status tracking.
  Widget obx(
    Widget Function(T? state) onResponse, {
    Widget? onLoading,
    Widget Function(String? error)? onError,
    Widget? onEmpty,
  }) {
    return Obx(() {
      final currentStatus = _status.value;
      if (currentStatus.isLoading) {
        return onLoading ?? const Center(child: CircularProgressIndicator());
      } else if (currentStatus.isError) {
        return onError != null
            ? onError(currentStatus.errorMessage)
            : Center(
                child: Text(
                  currentStatus.errorMessage ?? 'An error occurred',
                ),
              );
      } else if (currentStatus.isEmpty) {
        return onEmpty ?? const SizedBox.shrink();
      } else {
        return onResponse(_state.value);
      }
    });
  }
}
