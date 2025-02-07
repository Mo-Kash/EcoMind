import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brew.dart';
import 'brew_tile.dart';

class BrewList extends StatefulWidget {
  const BrewList({super.key});

  @override
  State<BrewList> createState() => _BrewListState();
}

class _BrewListState extends State<BrewList> {
  @override
  Widget build(BuildContext context) {
    final brews = Provider.of<List<Brew>?>(context) ?? [];

    // Flatten the list of products from all brews
    final allProducts = brews
        .expand((brew) => brew.productdetails ?? [])
        .toList();

    return GridView.builder(
      shrinkWrap: true,  // Ensures that the GridView only takes the necessary space
      physics: NeverScrollableScrollPhysics(),  // Disables scrolling for the GridView itself
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,  // Two items per row
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 3, // Adjust the child aspect ratio to make it fit well
      ),
      itemCount: allProducts.length,  // Use the length of the flattened list
      itemBuilder: (context, productIndex) {
        final product = allProducts[productIndex];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text("Price: \$${product['price']}"),
              ],
            ),
          ),
        );
      },
    );
  }
}
