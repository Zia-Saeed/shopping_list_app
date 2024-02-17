import 'package:flutter/material.dart';

import 'package:shopping_list_app/data/dummy_items.dart';
// import 'package:forms/models/category.dart';
// import 'package:forms/data/categories.dart';
// import 'package:forms/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});
  // due to stateless widget context is not provided to provide context use BuildContext context as parameter
  // void _addItem(BuildContext context){
  //   Navigator.of(context).push(route)
  // }

  @override
  State<GroceryList> createState() {
    return _GroceryListState();
  }
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  var _isLoading = true;
  String? _error;
  // String _deleted = "item deleted successfully";
  var _isDeleted = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      "flutter-prep-d8c7e-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      // setState(
      //   () {
      //     _error = "Failed to fetch data. Please try again later.";
      //   },
      // );
    }
    if (response.body == "null") {
      _error = "No Items are added";
    }
    if (response.statusCode < 300) {
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItem = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
              (element) => element.value.name == item.value["category"],
            )
            .value;
        loadedItem.add(
          GroceryItem(
            name: item.value["name"],
            id: item.key,
            quantity: item.value["quantity"],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = loadedItem;
        _isLoading = false;
      });
    }

    // print(response.statusCode);
  }

  void _removerGrocery(GroceryItem item) async {
    // final item = _groceryItems.indexOf(item);
    final idx = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
      "flutter-prep-d8c7e-default-rtdb.firebaseio.com",
      "shopping-list/${item.id}.json",
    );

    final response = await http.delete(url);

    final snackBar = SnackBar(
      content: Text(
        _isDeleted
            ? "item deleted successfully"
            : "unable to delete item try it later.",
      ),
      duration: const Duration(
        seconds: 2,
      ),
    );
    if (response.statusCode >= 400) {
      _isDeleted = false;
      setState(() {
        _groceryItems.insert(idx, item);
        // _deleted = "Unable to delete the item  because : ${response.body}";
        // _isDeleted = false;
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }

    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _addItem() async {
    // after poping from the next screen the data will be saved in newItem variable
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
    _loadItems();
  }
  // for null condition if the user press the backbutton or back the screen using scaffold

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("There is no Grocery Item."),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, item) {
          return Dismissible(
            background: Container(
              color: Colors.red,
            ),
            onDismissed: (direction) {
              _removerGrocery(_groceryItems[item]);
            },
            key: ValueKey(_groceryItems[item]),
            child: ListTile(
              leading: Container(
                color: _groceryItems[item].category.color,
                width: 24,
                height: 24,
              ),
              title: Text(
                _groceryItems[item].name,
              ),
              trailing: Text(
                _groceryItems[item].quantity.toString(),
              ),
            ),
          );
        },
      );
    }
    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: () {
              _addItem();
            },
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: content,
    );
  }
}
