import 'package:getx_distil/get.dart';

/// Controller demonstrating paged usage of [RxSList] with [addAll] + [hasMore].
class RxSListPagingController extends GetxController {
  final pagedList = RxSList<String>();
  final isNextPageLoading = false.obs;

  int _currentPage = 0;
  static const int _totalPages = 5;

  Future<void> loadFirstPage() async {
    _currentPage = 0;
    isNextPageLoading.value = false;
    pagedList.setLoading();
    await Future.delayed(const Duration(seconds: 3));
    final pageData = _fetchPage(_currentPage);
    pagedList.assignAll(pageData);
    pagedList.hasMore = _currentPage + 1 < _totalPages;
  }

  Future<void> loadNextPage() async {
    if (!pagedList.hasMore || isNextPageLoading.value) return;

    isNextPageLoading.value = true;
    await Future.delayed(const Duration(seconds: 3));
    _currentPage++;
    final pageData = _fetchPage(_currentPage);
    pagedList.addAll(pageData);
    pagedList.hasMore = _currentPage + 1 < _totalPages;
    isNextPageLoading.value = false;
  }

  void simulatePagingError() {
    isNextPageLoading.value = false;
    pagedList.setError('Network connection failed');
  }

  void resetPagedList() {
    _currentPage = 0;
    pagedList.clear();
    pagedList.setIdle();
    pagedList.hasMore = true;
    pagedList.error = null;
    isNextPageLoading.value = false;
  }

  List<String> _fetchPage(int page) {
    final start = page * 5 + 1;
    return List.generate(5, (i) => 'Page ${page + 1} - Item #${start + i}');
  }
}
