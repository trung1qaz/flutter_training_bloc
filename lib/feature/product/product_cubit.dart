import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit() : super(const ProductState());

  Future<void> fetchData() async {
    try {
      emit(state.copyWith(status: ProductStatus.loading, errorMessage: null));

      final response = await ApiClient.get<Map<String, dynamic>>(
        '${AppConstants.productsEndpoint}?page=2&size=10',
            (data) => data as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final responseData = response.data!;
        final List productListData = responseData['data'] ?? [];

        final productList = productListData.map((item) {
          return Product(
            id: _parseToInt(item['id']),
            name: item['name']?.toString() ?? '',
            price: _parseToInt(item['price']),
            quantity: _parseToInt(item['quantity']),
            cover: item['cover']?.toString() ?? '',
          );
        }).toList();

        emit(state.copyWith(
          status: ProductStatus.success,
          products: productList,
        ));
      } else {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: response.error ?? 'Failed to load products',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Error loading products: ${e.toString()}',
      ));
    }
  }

  Future<void> addProduct({
    required String name,
    required int price,
    required int quantity,
    required String cover,
  }) async {
    try {
      emit(state.copyWith(status: ProductStatus.submitting));

      final newProduct = Product(
        id: state.nextId,
        name: name.trim(),
        price: price,
        quantity: quantity,
        cover: cover.trim(),
      );

      final response = await ApiClient.post<Product>(
        AppConstants.productsEndpoint,
            (data) => Product(
          id: data['id'] ?? newProduct.id,
          name: data['name'] ?? newProduct.name,
          price: data['price'] ?? newProduct.price,
          quantity: data['quantity'] ?? newProduct.quantity,
          cover: data['cover'] ?? newProduct.cover,
        ),
        data: jsonEncode({
          'name': newProduct.name,
          'price': newProduct.price,
          'quantity': newProduct.quantity,
          'cover': newProduct.cover,
        }),
      );

      if (response.success && response.data != null) {
        final updatedProducts = List<Product>.from(state.products);
        updatedProducts.add(response.data!);

        emit(state.copyWith(
          status: ProductStatus.success,
          products: updatedProducts,
          nextId: state.nextId + 1,
        ));
      } else {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: response.error ?? 'Failed to add product',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Lỗi thêm sản phẩm: $e',
      ));
    }
  }

  Future<void> removeProduct(int index) async {
    if (index < 0 || index >= state.products.length) return;

    final product = state.products[index];

    try {
      final response = await ApiClient.delete('${AppConstants.productsEndpoint}/${product.id}');

      if (response.success) {
        final updatedProducts = List<Product>.from(state.products);
        updatedProducts.removeAt(index);

        emit(state.copyWith(
          status: ProductStatus.success,
          products: updatedProducts,
        ));
      } else {
        emit(state.copyWith(
          status: ProductStatus.error,
          errorMessage: response.error ?? 'Failed to delete product',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Lỗi xóa sản phẩm: $e',
      ));
    }
  }

  Future<void> refreshData() async {
    await fetchData();
  }

  int _parseToInt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
