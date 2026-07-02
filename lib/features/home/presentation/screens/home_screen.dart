import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ecommerce_app_api_26/features/home/presentation/widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  late CollectionReference<Map<String, dynamic>> productsReference;
  void initState() {
    // TODO: implement initState
    super.initState();
    getProducts();
  }

  void getProducts() {
    productsReference = FirebaseFirestore.instance.collection("products");
  }

  Future<void> addToCart(
    String productId,
    String title,
    double price,
    String description,
    String? image,
  ) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    CollectionReference cartReference = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cart');
    DocumentReference productReference = cartReference.doc(productId);
    DocumentSnapshot productSnapshot = await productReference.get();

    if (productSnapshot.exists) {
      int quantity = productSnapshot['quantity'];
      await productReference.update({'quantity': quantity + 1});
    } else {
      await productReference.set({
        'name': title,
        'description': description,
        'price': price,
        'image_url': image,
        'quantity': 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _nameController = TextEditingController(),
        _descriptionController = TextEditingController(),
        _priceController = TextEditingController(),
        _imageUrlController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (BuildContext) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                    ),
                    TextField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(labelText: 'Image Url'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await productsReference.add({
                          'name': _nameController.text,
                          'description': _descriptionController.text,
                          'price': double.parse(_priceController.text),
                          'image_url': _imageUrlController.text,
                        });
                      },
                      child: Text("Add Product"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome,',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const Text(
                  'Our Shop',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.blue),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.blue),
                  ),
                ),
              ),
            ),
            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['All', 'Shoes', 'Shirts', 'Tech', 'Home'].map((cat) {
                  bool isAll = cat == 'All';
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isAll ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        if (!isAll)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                      ],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isAll ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Products Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder(
                future: productsReference.get(),
                builder: (context, asyncSnapshot) {
                  if (!asyncSnapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: asyncSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final product = asyncSnapshot.data!.docs[index].data();
                      return ProductCard(
                        productId: asyncSnapshot.data!.docs[index].id,
                        title: product['name'],
                        price: product['price'],
                        description: product['description'],
                        image: product['image_url'],
                        onAdd: () {
                          addToCart(
                            asyncSnapshot.data!.docs[index].id,
                            product['name'],
                            product['price'],
                            product['description'],
                            product['image_url'],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
