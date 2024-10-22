import 'package:flutter/material.dart';

class SearchResultsPage extends StatelessWidget {
  final List<Map<String, dynamic>> searchedProducts;
  final List<Map<String, dynamic>> searchedAccessories;

  const SearchResultsPage({
    Key? key,
    required this.searchedProducts,
    required this.searchedAccessories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Search Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchedProducts.isEmpty && searchedAccessories.isEmpty)
              const Center(child: Text('No products or accessories found.')),
            if (searchedProducts.isNotEmpty)
              const Text('Products:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...searchedProducts.map((product) => ListTile(
              title: Text(product['name']),
              subtitle: Text('\$${product['price']}'),
            )),
            if (searchedAccessories.isNotEmpty)
              const Text('Accessories:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...searchedAccessories.map((accessory) => ListTile(
              title: Text(accessory['name']),
              subtitle: Text('\$${accessory['price']}'),
            )),
          ],
        ),
      ),
    );
  }
}