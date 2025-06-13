import 'package:equatable/equatable.dart';
import 'package:sds_mobile_training_p2/cubit/product_model.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Product> products;

  HomeLoaded({required this.products});

  @override
  List<Object?> get props => [products];
}

class HomeError extends HomeState {
  final String message;
  final bool isUnauthorized;

  HomeError({
    required this.message,
    this.isUnauthorized = false,
  });

  @override
  List<Object?> get props => [message, isUnauthorized];
}

class ProductAdding extends HomeState {
  final List<Product> products;

  ProductAdding({required this.products});

  @override
  List<Object?> get props => [products];
}

class ProductDeleting extends HomeState {
  final List<Product> products;
  final int deletingIndex;

  ProductDeleting({
    required this.products,
    required this.deletingIndex,
  });

  @override
  List<Object?> get props => [products, deletingIndex];
}