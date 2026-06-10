import 'package:getx_distil/get.dart';

/// Controller demonstrating paged usage of [RxSList] with [addAll] + [hasMore].
class RxSListPagingController extends GetxController {
  final pagedList = RxSList<String>();

  int _currentPage = 0;
  static const int _totalPages = 5;

  void loadFirstPage() {
    _currentPage = 0;
    final pageData = _fetchPage(_currentPage);
    pagedList.assignAll(pageData);
    pagedList.hasMore = _currentPage + 1 < _totalPages;
  }

  void loadNextPage() {
    if (!pagedList.hasMore) return;

    _currentPage++;
    final pageData = _fetchPage(_currentPage);
    pagedList.addAll(pageData);
    pagedList.hasMore = _currentPage + 1 < _totalPages;
  }

  void simulatePagingError() {
    pagedList.error = 'Network connection failed';
    pagedList.status = RxListStatus.error;
  }

  void resetPagedList() {
    _currentPage = 0;
    pagedList.clear();
    pagedList.status = RxListStatus.loading;
    pagedList.hasMore = true;
    pagedList.error = null;
  }

  List<String> _fetchPage(int page) {
    final start = page * 5 + 1;
    return List.generate(5, (i) => 'Page ${page + 1} - Item #${start + i}');
  }
}
