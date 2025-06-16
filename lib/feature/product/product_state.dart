import 'package:equatable/equatable.dart';

enum ProductStatus { initial, loading, success, error, submitting }

class Product extends Equatable {
  final int id;
  final String name;
  final int price;
  final int quantity;
  final String cover;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.cover,
  });

  Product copyWith({
    int? id,
    String? name,
    int? price,
    int? quantity,
    String? cover,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      cover: cover ?? this.cover,
    );
  }

  @override
  List<Object?> get props => [id, name, price, quantity, cover];
}

class ProductState extends Equatable {
  final ProductStatus status;
  final List<Product> products;
  final String? errorMessage;
  final int nextId;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.errorMessage,
    this.nextId = 21,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    String? errorMessage,
    int? nextId,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage ?? this.errorMessage,
      nextId: nextId ?? this.nextId,
    );
  }

  @override
  List<Object?> get props => [status, products, errorMessage, nextId];
}
