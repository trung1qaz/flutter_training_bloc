import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sds_mobile_training_p2/cubit/product_model.dart';
import '../data/product_api.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  int _nextId = 21;
  final Box _authBox = Hive.box('authBox');

  Future<void> fetchProducts() async {
    emit(HomeLoading());

    try {
      final products = await fetchProductsFromApi();
      emit(HomeLoaded(products: products));
    } catch (e) {
      final isUnauthorized = e.toString().contains('Unauthorized');
      emit(HomeError(
        message: e.toString(),
        isUnauthorized: isUnauthorized,
      ));
    }
  }

  Future<void> addProduct({
    required String name,
    required int price,
    required int quantity,
    required String cover,
  }) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(ProductAdding(products: currentState.products));

    try {
      final newProduct = Product(
        id: _nextId++,
        name: name.trim(),
        price: price,
        quantity: quantity,
        cover: cover.trim(),
      );

      final addedProduct = await addProductToApi(newProduct);
      final updatedProducts = [...currentState.products, addedProduct];

      emit(HomeLoaded(products: updatedProducts));
    } catch (e) {
      final isUnauthorized = e.toString().contains('Unauthorized');
      emit(HomeError(
        message: e.toString(),
        isUnauthorized: isUnauthorized,
      ));
    }
  }

  Future<void> deleteProduct(int index) async {
    final currentState = state;
    if (currentState is! HomeLoaded) return;

    emit(ProductDeleting(
      products: currentState.products,
      deletingIndex: index,
    ));

    try {
      final product = currentState.products[index];
      await deleteProductFromApi(product.id);

      final updatedProducts = [...currentState.products];
      updatedProducts.removeAt(index);

      emit(HomeLoaded(products: updatedProducts));
    } catch (e) {
      final isUnauthorized = e.toString().contains('Unauthorized');
      emit(HomeError(
        message: e.toString(),
        isUnauthorized: isUnauthorized,
      ));
    }
  }

  void logout() {
    _authBox.delete('authToken');
    _authBox.delete('currentUser');
  }

  void retryFromError() {
    fetchProducts();
  }
}
