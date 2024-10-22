import 'dart:convert';
import 'dart:io';
import 'package:entrylevel_app/search_results_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'additems_page.dart';
import 'main.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> productList = [];
  List<Map<String, dynamic>> accessoryList = [];
  List<Map<String, dynamic>> filteredProductList = [];
  List<Map<String, dynamic>> filteredAccessoryList = [];
  bool isLoading = true;
  bool showAllProducts = false;
  bool showAllAccessories = false;

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadAccessories();
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? productsString = prefs.getString('products');
      if (productsString != null) {
        productList = List<Map<String, dynamic>>.from(jsonDecode(productsString));
        filteredProductList = productList;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load products')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadAccessories() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accessoriesString = prefs.getString('accessories');
      if (accessoriesString != null) {
        accessoryList = List<Map<String, dynamic>>.from(jsonDecode(accessoriesString));
        filteredAccessoryList = accessoryList;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accessories')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> items) {
    final uniqueNames = <String>{};
    return items.where((item) {
      final name = item['name'].toLowerCase();
      if (uniqueNames.contains(name)) {
        return false; // Duplicate, exclude it
      } else {
        uniqueNames.add(name); // Add to set and keep
        return true;
      }
    }).toList();
  }


  void deleteItem(List<Map<String, dynamic>> list, int index, bool isAccessory) async {
    setState(() {
      list.removeAt(index);
      if (isAccessory) {
        filteredAccessoryList = accessoryList;
      } else {
        filteredProductList = productList;
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final key = isAccessory ? 'accessories' : 'products';
    await prefs.setString(key, jsonEncode(list));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${isAccessory ? "Accessory" : "Product"} deleted successfully')),
    );
  }

  void searchItems(String query) {
    // Filter products and accessories
    List<Map<String, dynamic>> searchedProducts = productList.where((product) {
      return product['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    List<Map<String, dynamic>> searchedAccessories = accessoryList.where((accessory) {
      return accessory['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    // Navigate to the Search Results page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchedProducts: searchedProducts,
          searchedAccessories: searchedAccessories,
        ),
      ),
    );
  }
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();  // Clear user data.

      // Ensure we navigate to LoginPage properly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayProducts = showAllProducts ? filteredProductList : filteredProductList.take(2).toList();
    final displayAccessories = showAllAccessories ? filteredAccessoryList : filteredAccessoryList.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: _confirmLogout,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              String? searchTerm = await showSearchDialog();
              if (searchTerm != null) {
                searchItems(searchTerm);
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Hi-Fi Shop & Service",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Audio shop on Rustaveli Ave 57.",
                    style: TextStyle(fontSize: 17, color: Colors.grey),
                  ),
                  Text(
                    "This shop offers both products and services.",
                    style: TextStyle(fontSize: 16,color: Colors.grey),
                  ),
                ],
              ),
            ),
            _buildSectionHeader(
              title: "Products (${filteredProductList.length})",
              onTap: () => setState(() => showAllProducts = !showAllProducts),
              showAll: showAllProducts,
            ),
            _buildGridView(displayProducts, false),
            _buildSectionHeader(
              title: "Accessories (${filteredAccessoryList.length})",
              onTap: () => setState(() => showAllAccessories = !showAllAccessories),
              showAll: showAllAccessories,
            ),
            _buildGridView(displayAccessories, true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddItemPage()),
          );
          if (result == true) {
            loadProducts();
            loadAccessories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }

  Future<String?> showSearchDialog() async {
    String searchTerm = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search'),
          content: TextField(
            onChanged: (value) {
              searchTerm = value;
            },
            decoration: const InputDecoration(hintText: 'Enter search term'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(searchTerm),
              child: const Text('Search'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onTap, required bool showAll}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              showAll ? "Show less" : "Show all",
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> items, bool isAccessory) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          isAccessory ? 'Add accessories to click Add Button' : 'Add products to click Add Button',
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, isAccessory);
      },
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, bool isAccessory) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4, // Add elevation for shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_forever_outlined),
                onPressed: () => deleteItem(isAccessory ? accessoryList : productList, isAccessory ? filteredAccessoryList.indexOf(item) : filteredProductList.indexOf(item), isAccessory),
              ),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                  ? Image.file(
                File(item['imageUrl']),
                fit: BoxFit.cover,
                width: double.infinity,
              )
                  : Image.network(
                'https://via.placeholder.com/150',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          if (isAccessory)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                item['availability'],
                style: TextStyle(
                  color: item['availability'] == 'Available' ? Colors.green : Colors.red,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('\$${item['price']}'),
          ),
        ],
      ),
    );
  }
}