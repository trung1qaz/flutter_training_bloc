import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/product_image.dart';
import 'product_cubit.dart';
import 'product_state.dart';

// Helper functions
int _safeParseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  if (value is double) return value.toInt();
  return 0;
}

String _safeParseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

// API functions
Future<Product> updateProductInApi(Product product) async {
  try {
    final response = await ApiClient.put<Map<String, dynamic>>(
      '${AppConstants.productsEndpoint}/${product.id}',
          (data) => data as Map<String, dynamic>,
      data: jsonEncode({
        'name': product.name,
        'price': product.price,
        'quantity': product.quantity,
        'cover': product.cover,
      }),
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      return Product(
        id: _safeParseInt(data['id']) != 0 ? _safeParseInt(data['id']) : product.id,
        name: _safeParseString(data['name']).isNotEmpty ? _safeParseString(data['name']) : product.name,
        price: _safeParseInt(data['price']) != 0 ? _safeParseInt(data['price']) : product.price,
        quantity: _safeParseInt(data['quantity']) != 0 ? _safeParseInt(data['quantity']) : product.quantity,
        cover: _safeParseString(data['cover']).isNotEmpty ? _safeParseString(data['cover']) : product.cover,
      );
    } else {
      throw Exception(response.error ?? 'Failed to update product');
    }
  } catch (e) {
    throw Exception('Failed to update product: $e');
  }
}

Future<bool> deleteProductFromApi(int productId) async {
  try {
    final response = await ApiClient.delete('${AppConstants.productsEndpoint}/$productId');
    if (response.success) {
      return true;
    } else {
      throw Exception(response.error ?? 'Failed to delete product');
    }
  } catch (e) {
    throw Exception('Failed to delete product: $e');
  }
}

Future<Product> getProductDetails(int productId) async {
  try {
    final response = await ApiClient.get<Map<String, dynamic>>(
      '${AppConstants.productsEndpoint}/$productId',
          (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final data = response.data!;
      final productData = data['data'] ?? data;

      return Product(
        id: _safeParseInt(productData['id']) != 0 ? _safeParseInt(productData['id']) : productId,
        name: _safeParseString(productData['name']),
        price: _safeParseInt(productData['price']),
        quantity: _safeParseInt(productData['quantity']),
        cover: _safeParseString(productData['cover']),
      );
    } else {
      throw Exception(response.error ?? 'Failed to load product details');
    }
  } catch (e) {
    throw Exception('Failed to load product details: $e');
  }
}

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product currentProduct;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    currentProduct = widget.product;
    loadProductDetails();
  }

  void loadProductDetails() async {
    setState(() => isLoading = true);
    try {
      final updatedProduct = await getProductDetails(widget.product.id);
      setState(() {
        currentProduct = updatedProduct;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      if (e.toString().contains('Unauthorized')) {
        _handleUnauthorized();
      }
    }
    setState(() => isLoading = false);
  }

  void _handleUnauthorized() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Phiên đăng nhập hết hạn'),
      content: const Text('Vui lòng đăng nhập lại'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          child: const Text('Đăng nhập lại'),
        ),
      ],
    ),
  );

  void _showEditDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentProduct.name);
    final priceCtrl = TextEditingController(text: currentProduct.price.toString());
    final quantityCtrl = TextEditingController(text: currentProduct.quantity.toString());
    final coverCtrl = TextEditingController(text: currentProduct.cover);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh sửa sản phẩm'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                _inputField(nameCtrl, 'Tên sản phẩm'),
                _inputField(priceCtrl, 'Giá (vnđ)', isNumber: true),
                _inputField(quantityCtrl, 'Số lượng', isNumber: true),
                _inputField(coverCtrl, 'URL hình ảnh'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final updatedProduct = Product(
                    id: currentProduct.id,
                    name: nameCtrl.text.trim(),
                    price: int.tryParse(priceCtrl.text) ?? 0,
                    quantity: int.tryParse(quantityCtrl.text) ?? 0,
                    cover: coverCtrl.text.trim(),
                  );

                  final result = await updateProductInApi(updatedProduct);
                  setState(() => currentProduct = result);

                  // Update the cubit state as well
                  if (mounted) {
                    context.read<ProductCubit>().refreshData();
                  }

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật sản phẩm thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (e.toString().contains('Unauthorized')) {
                    Navigator.pop(dialogContext);
                    _handleUnauthorized();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi cập nhật: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${currentProduct.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        await deleteProductFromApi(currentProduct.id);

        // Refresh the product list
        if (mounted) {
          context.read<ProductCubit>().refreshData();
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa sản phẩm thành công')),
        );
      } catch (e) {
        setState(() => isLoading = false);
        if (e.toString().contains('Unauthorized')) {
          _handleUnauthorized();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi xóa sản phẩm: $e')),
          );
        }
      }
    }
  }

  Widget _inputField(
      TextEditingController ctrl,
      String label, {
        bool isNumber = false,
      }) =>
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: isNumber ? TextInputType.number : null,
        validator: (v) =>
        v == null || v.isEmpty || (isNumber && int.tryParse(v) == null)
            ? 'Bắt buộc${isNumber ? ' & phải là số' : ''}'
            : null,
      );

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: isUrl
                    ? const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                )
                    : null,
              ),
            ),
          ],
        ),
      );

  Widget _buildProductImage() => SizedBox(
    height: 300,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ProductImage(imageUrl: currentProduct.cover),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(currentProduct.name.isNotEmpty ? currentProduct.name : 'Product Details'),
      backgroundColor: Colors.orange,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isLoading ? null : loadProductDetails,
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: isLoading ? null : _showEditDialog,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: isLoading ? null : _deleteProduct,
        ),
      ],
    ),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : errorMessage != null
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 8),
          const Text(
            'Có lỗi xảy ra',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loadProductDetails,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    )
        : SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductImage(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentProduct.name.isNotEmpty ? currentProduct.name : 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_money),
                    Text('${currentProduct.price} đ'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory),
                    Text(' Số lượng: ${currentProduct.quantity}'),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin chi tiết',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        _buildInfoRow('ID sản phẩm', currentProduct.id.toString()),
                        _buildInfoRow('Tên sản phẩm', currentProduct.name),
                        _buildInfoRow('Giá bán', '${currentProduct.price} đ'),
                        _buildInfoRow('Số lượng tồn kho', '${currentProduct.quantity}'),
                        _buildInfoRow('URL hình ảnh', currentProduct.cover, isUrl: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: !isLoading
        ? BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deleteProduct,
                icon: const Icon(Icons.delete),
                label: const Text('Xóa'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    )
        : null,
  );
}
