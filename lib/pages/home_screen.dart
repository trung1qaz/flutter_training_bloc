import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../cubit/product_model.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..fetchProducts(),
      child: HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  void _showAddProductDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final coverCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<HomeCubit>(),
        child: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state is HomeLoaded) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thêm sản phẩm thành công')),
              );
            } else if (state is HomeError) {
              if (state.isUnauthorized) {
                Navigator.pop(dialogContext);
                _handleUnauthorized(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi thêm sản phẩm: ${state.message}')),
                );
              }
            }
          },
          builder: (context, state) {
            final isSubmitting = state is ProductAdding;

            return AlertDialog(
              title: Text('Thêm sản phẩm'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: 'Tên sản phẩm'),
                        enabled: !isSubmitting,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Bắt buộc' : null,
                      ),
                      TextFormField(
                        controller: priceCtrl,
                        decoration: InputDecoration(labelText: 'Giá (vnđ)'),
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        validator: (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Phải là số'
                            : null,
                      ),
                      TextFormField(
                        controller: quantityCtrl,
                        decoration: InputDecoration(labelText: 'Số lượng'),
                        keyboardType: TextInputType.number,
                        enabled: !isSubmitting,
                        validator: (value) =>
                        value == null || int.tryParse(value) == null
                            ? 'Phải là số'
                            : null,
                      ),
                      TextFormField(
                        controller: coverCtrl,
                        decoration: InputDecoration(labelText: 'URL hình ảnh'),
                        enabled: !isSubmitting,
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Bắt buộc' : null,
                      ),
                      if (isSubmitting)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () {
                    if (_formKey.currentState!.validate()) {
                      context.read<HomeCubit>().addProduct(
                        name: nameCtrl.text,
                        price: int.parse(priceCtrl.text),
                        quantity: int.parse(quantityCtrl.text),
                        cover: coverCtrl.text,
                      );
                    }
                  },
                  child: Text('Thêm'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleUnauthorized(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Phiên đăng nhập hết hạn'),
        content: Text('Vui lòng đăng nhập lại'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeCubit>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
            child: Text('Đăng nhập lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteProduct(BuildContext context, int index, Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      context.read<HomeCubit>().deleteProduct(index);
    }
  }

  Widget _buildProductImage(String imageUrl) {
    return Image.network(
      imageUrl,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 60,
          height: 60,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey[300],
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[600],
            size: 30,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => context.read<HomeCubit>().fetchProducts(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<HomeCubit>().logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            if (state.isUnauthorized) {
              _handleUnauthorized(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi tải dữ liệu: ${state.message}'),
                  action: SnackBarAction(
                    label: 'Thử lại',
                    onPressed: () => context.read<HomeCubit>().fetchProducts(),
                  ),
                ),
              );
            }
          } else if (state is HomeLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Thao tác thành công')),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeLoading || state is HomeInitial) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is HomeError && state is! ProductAdding && state is! ProductDeleting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HomeCubit>().fetchProducts(),
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final products = _getProductsFromState(state);

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Chưa có sản phẩm nào."),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddProductDialog(context),
                    child: Text('Thêm sản phẩm đầu tiên'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<HomeCubit>().fetchProducts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isDeleting = state is ProductDeleting &&
                    state.deletingIndex == index;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildProductImage(product.cover),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepOrange,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Giá: ${product.price} đ\nSố lượng: ${product.quantity}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        isThreeLine: true,
                        onTap: isDeleting ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onLongPress: isDeleting ? null : () {
                          _confirmDeleteProduct(context, index, product);
                        },
                      ),
                      if (isDeleting)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_box_rounded),
                tooltip: 'Thêm sản phẩm',
                onPressed: () => _showAddProductDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Product> _getProductsFromState(HomeState state) {
    if (state is HomeLoaded) return state.products;
    if (state is ProductAdding) return state.products;
    if (state is ProductDeleting) return state.products;
    return [];
  }
}