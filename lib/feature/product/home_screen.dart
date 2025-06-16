import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/product_image.dart';
import '../../core/base_ui.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import 'product_cubit.dart';
import 'product_state.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý sản phẩm"),
        backgroundColor: BaseUI.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              context.read<ProductCubit>().refreshData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state.status == ProductStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: BaseUI.errorColor,
                action: SnackBarAction(
                  label: 'Thử lại',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<ProductCubit>().fetchData();
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == ProductStatus.loading) {
            return const BaseLoading(message: 'Đang tải dữ liệu...');
          }

          if (state.products.isEmpty && state.status != ProductStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Chưa có sản phẩm nào."),
                  const SizedBox(height: 16),
                  BaseButton(
                    text: 'Thêm sản phẩm đầu tiên',
                    onPressed: () => _showAddProductDialog(context),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ProductCubit>().refreshData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              itemBuilder: (context, index) {
                final product = state.products[index];
                return BaseCard(
                  onTap: () => _navigateToProductDetail(context, product),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProductImage(imageUrl: product.cover),
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(context, index, product.name),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(context),
        backgroundColor: BaseUI.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context, Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (newContext) => BlocProvider.value(
          value: context.read<ProductCubit>(),
          child: ProductDetailScreen(product: product),
        ),
      ),
    );

    // Refresh the list if product was modified or deleted
    if (result == true) {
      context.read<ProductCubit>().refreshData();
    }
  }

  void _showDeleteConfirmation(BuildContext context, int index, String productName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ProductCubit>().removeProduct(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final coverCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<ProductCubit>(),
        child: AlertDialog(
          title: const Text('Thêm sản phẩm'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Bắt buộc' : null,
                  ),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Giá (vnđ)'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'Phải là số'
                        : null,
                  ),
                  TextFormField(
                    controller: quantityCtrl,
                    decoration: const InputDecoration(labelText: 'Số lượng'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value == null || int.tryParse(value) == null
                        ? 'Phải là số'
                        : null,
                  ),
                  TextFormField(
                    controller: coverCtrl,
                    decoration: const InputDecoration(labelText: 'URL hình ảnh'),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Bắt buộc' : null,
                  ),
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, state) {
                      if (state.status == ProductStatus.submitting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                final isSubmitting = state.status == ProductStatus.submitting;
                return TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                );
              },
            ),
            BlocConsumer<ProductCubit, ProductState>(
              listener: (context, state) {
                if (state.status == ProductStatus.success) {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thêm sản phẩm thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Navigate to the newly created product's detail screen
                  final newProduct = state.products.last;
                  _navigateToProductDetail(context, newProduct);
                }
              },
              builder: (context, state) {
                final isSubmitting = state.status == ProductStatus.submitting;
                return ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                    if (formKey.currentState!.validate()) {
                      context.read<ProductCubit>().addProduct(
                        name: nameCtrl.text,
                        price: int.parse(priceCtrl.text),
                        quantity: int.parse(quantityCtrl.text),
                        cover: coverCtrl.text,
                      );
                    }
                  },
                  child: const Text('Thêm'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
