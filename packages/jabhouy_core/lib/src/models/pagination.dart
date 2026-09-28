// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:jabhouy_core/src/models/casts.dart';

part 'pagination.g.dart';

@CopyWith()
class Pagination {
  Pagination({
    this.total,
    this.page = 1,
    this.limit = 10,
    this.totalPage,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: tryCast<int>(json['total']) ?? 0,
      page: tryCast<int>(json['page']) ?? 1,
      limit: tryCast<int>(json['limit']) ?? 10,
      totalPage: tryCast<int>(json['totalPages']) ?? 1,
    );
  }
  final int? total;
  final int page;
  final int limit;
  final int? totalPage;

  bool get hasNext => page < (totalPage ?? 1);

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'page': page,
      'limit': limit,
      'totalPage': totalPage,
    };
  }

}

@CopyWith()
class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) itemParser) {
    final items = (json['data'] as List).map((item) => itemParser(item as Map<String, dynamic>)).toList();
    final pagination = Pagination.fromJson(json['pagination'] as Map<String, dynamic>);
    return PaginatedResponse<T>(
      items: items,
      pagination: pagination,
    );
  }
  final List<T> items;
  final Pagination pagination;

}
