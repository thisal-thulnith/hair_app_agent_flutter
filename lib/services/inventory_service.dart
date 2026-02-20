import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InventoryService {
  // Backend URL for Beauty AI API via ngrok
  static const String _baseUrl = 'https://4ee5-222-165-182-230.ngrok-free.app';

  final AuthService _authService = AuthService();

  /// Get all inventory products (public)
  Future<List<Map<String, dynamic>>> getProducts({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/inventory/products?skip=$skip&limit=$limit'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('products')) {
          return List<Map<String, dynamic>>.from(data['products']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get products: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get admin's salon-specific inventory products (requires auth)
  Future<List<Map<String, dynamic>>> getAdminProducts({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/inventory/products?skip=$skip&limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('products')) {
          return List<Map<String, dynamic>>.from(data['products']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired');
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication')) {
        rethrow;
      }
      print('Failed to get admin products: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Create a new product (public)
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String sku,
    String? description,
    String category = 'general',
    int quantity = 0,
    int minQuantity = 10,
    double unitPrice = 0.0,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/inventory/products'),
      );

      request.headers['ngrok-skip-browser-warning'] = 'true';

      request.fields['name'] = name;
      request.fields['sku'] = sku;
      if (description != null) request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['quantity'] = quantity.toString();
      request.fields['min_quantity'] = minQuantity.toString();
      request.fields['unit_price'] = unitPrice.toString();

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to create product: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Create admin product (requires auth)
  Future<Map<String, dynamic>> createAdminProduct({
    required String name,
    required String sku,
    required String description,
    required int initialQuantity,
    String category = 'beauty_product',
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/inventory/products'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'ngrok-skip-browser-warning': 'true',
        },
        body: {
          'name': name,
          'sku': sku,
          'description': description,
          'initial_quantity': initialQuantity.toString(),
          'category': category,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired');
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication')) {
        rethrow;
      }
      print('Failed to create admin product: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Update product quantity or details
  Future<Map<String, dynamic>> updateProduct({
    required String productId,
    int? quantityChange,
    String? name,
    int? minQuantity,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/api/inventory/products/$productId'),
      );

      request.headers['ngrok-skip-browser-warning'] = 'true';

      if (quantityChange != null) {
        request.fields['quantity_change'] = quantityChange.toString();
      }
      if (name != null) request.fields['name'] = name;
      if (minQuantity != null) {
        request.fields['min_quantity'] = minQuantity.toString();
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to update product: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get products with low stock
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/inventory/low-stock'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('products')) {
          return List<Map<String, dynamic>>.from(data['products']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception('Failed to load low stock products: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get low stock products: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get inventory statistics
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/inventory/stats'),
        headers: {
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load inventory stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to get inventory stats: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  /// Get admin dashboard statistics (requires auth)
  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/dashboard/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired');
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication')) {
        rethrow;
      }
      print('Failed to get admin dashboard stats: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }
}
