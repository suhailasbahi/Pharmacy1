// lib/core/widgets/paginated_list.dart
import 'package:flutter/material.dart';
import 'loading_overlay.dart';
import 'state_widgets.dart';

/// قائمة مع تحميل تدريجي (Pagination)
class PaginatedList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) fetchData;
  final Widget Function(T item, int index) itemBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function(String error)? errorBuilder;
  final Widget Function()? loadingBuilder;
  final int pageSize;
  final ScrollController? scrollController;
  final bool reverse;
  final EdgeInsets padding;
  final double spacing;
  
  const PaginatedList({
    Key? key,
    required this.fetchData,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingBuilder,
    this.pageSize = 20,
    this.scrollController,
    this.reverse = false,
    this.padding = const EdgeInsets.all(0),
    this.spacing = 0,
  }) : super(key: key);

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.fetchData(_currentPage, widget.pageSize);
      setState(() {
        if (newItems.length < widget.pageSize) {
          _hasMore = false;
        }
        _items.addAll(newItems);
        _currentPage++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    _items.clear();
    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return widget.loadingBuilder?.call() ?? 
          const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty && _error != null) {
      return widget.errorBuilder?.call(_error!) ??
          ErrorWidget(
            message: _error!,
            onRetry: refresh,
          );
    }

    if (_items.isEmpty) {
      return widget.emptyBuilder?.call() ??
          const EmptyWidget(title: 'لا توجد بيانات');
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        controller: _scrollController,
        reverse: widget.reverse,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => SizedBox(height: widget.spacing),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return widget.itemBuilder(_items[index], index);
        },
      ),
    );
  }
}