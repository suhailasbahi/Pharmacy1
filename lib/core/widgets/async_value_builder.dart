// lib/core/widgets/async_value_builder.dart
import 'package:flutter/material.dart';
import 'state_widgets.dart';

/// واجهة موحدة لعرض البيانات غير المتزامنة
class AsyncValueBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) onLoaded;
  final Widget Function(String error)? onError;
  final Widget Function()? onLoading;
  final Widget Function()? onEmpty;
  final bool Function(T data)? isEmptyChecker;
  final VoidCallback? onRetry;

  const AsyncValueBuilder({
    Key? key,
    required this.future,
    required this.onLoaded,
    this.onError,
    this.onLoading,
    this.onEmpty,
    this.isEmptyChecker,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return onLoading?.call() ?? 
              const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return onError?.call(snapshot.error.toString()) ??
              ErrorWidget(
                message: snapshot.error.toString(),
                onRetry: onRetry ?? () {},
              );
        }
        
        final data = snapshot.data!;
        
        if (isEmptyChecker != null && isEmptyChecker!(data)) {
          return onEmpty?.call() ??
              const EmptyWidget(title: 'لا توجد بيانات');
        }
        
        return onLoaded(data);
      },
    );
  }
}

/// نسخة مع Stream
class StreamValueBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(T data) onLoaded;
  final Widget Function(String error)? onError;
  final Widget Function()? onLoading;
  final Widget Function()? onEmpty;
  final bool Function(T data)? isEmptyChecker;

  const StreamValueBuilder({
    Key? key,
    required this.stream,
    required this.onLoaded,
    this.onError,
    this.onLoading,
    this.onEmpty,
    this.isEmptyChecker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return onLoading?.call() ?? 
              const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return onError?.call(snapshot.error.toString()) ??
              ErrorWidget(
                message: snapshot.error.toString(),
                onRetry: () {},
              );
        }
        
        if (!snapshot.hasData) {
          return onEmpty?.call() ??
              const EmptyWidget(title: 'لا توجد بيانات');
        }
        
        final data = snapshot.data!;
        
        if (isEmptyChecker != null && isEmptyChecker!(data)) {
          return onEmpty?.call() ??
              const EmptyWidget(title: 'لا توجد بيانات');
        }
        
        return onLoaded(data);
      },
    );
  }
}