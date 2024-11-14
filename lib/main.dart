import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> products = [];
  List<bool> isShared = [];
  List<GlobalKey> repaintBoundaryKeys = [];
  Uint8List? imageBytes;
  String searchQuery = "";

  final TextEditingController searchController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController designNoController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController packingController = TextEditingController();
  final TextEditingController rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/products'));
      // final response = await http.get(Uri.parse('http://app.pluserp.live/final/view/final/view/get'));

      if (response.statusCode == 200) {
        print("RES: $response");
        List<Map<String, dynamic>> fetchedProducts = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        setState(() {
          products = List<Map<String, dynamic>>.from(fetchedProducts);  // Make products list growable
          isShared = List<bool>.filled(products.length, false, growable: true);  // Growable
          repaintBoundaryKeys = List<GlobalKey>.generate(products.length, (_) => GlobalKey(), growable: true);  // Growable
        });
      } else {
        print('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _addProduct() async {
    final newProduct = {
      "type": typeController.text,
      "code": codeController.text,
      "designNo": designNoController.text,
      "name": nameController.text,
      "description": descriptionController.text,
      "size": sizeController.text,
      "color": colorController.text,
      "packing": packingController.text,
      "rate": rateController.text,
      "image": imageBytes != null ? base64Encode(imageBytes!) : null,
    };

    try {
      // Send the new product to the server
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/products'), // Adjust to your API endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newProduct),
      );

      if (response.statusCode == 200) {
        // If the response is 200, show the failure message.
        print('Failed to add product: 200');
        _showErrorMessage('Failed to add product');
      } else if (response.statusCode == 201) {
        // If the response is 201, the product was successfully added.
        setState(() {
          products.add(newProduct);
          isShared.add(false);
          repaintBoundaryKeys.add(GlobalKey());
        });

        Navigator.pop(context); // Close the dialog
      } else {
        // Handle other status codes as needed.
        _showErrorMessage('Unexpected error occurred');
      }
    } catch (e) {
      // In case of network or other errors
      print('Error adding product: $e');
      _showErrorMessage('Failed to add product: $e');
    }
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }



  Future<void> _openAddProductDialog() async {
    imageBytes = null;
    typeController.clear();
    codeController.clear();
    designNoController.clear();
    nameController.clear();
    descriptionController.clear();
    sizeController.clear();
    colorController.clear();
    packingController.clear();
    rateController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: typeController, decoration: InputDecoration(labelText: 'Type')),
                TextField(controller: codeController, decoration: InputDecoration(labelText: 'Code')),
                TextField(controller: designNoController, decoration: InputDecoration(labelText: 'Design No')),
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
                TextField(controller: sizeController, decoration: InputDecoration(labelText: 'Size')),
                TextField(controller: colorController, decoration: InputDecoration(labelText: 'Color')),
                TextField(controller: packingController, decoration: InputDecoration(labelText: 'Packing')),
                TextField(controller: rateController, decoration: InputDecoration(labelText: 'Rate')),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      imageBytes = await pickedFile.readAsBytes();
                    }
                  },
                  child: Text('Select Image'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: 'Search Product',
          border: OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                searchQuery = searchController.text;
              });
            },
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildProductCard(int index, Map<String, dynamic> product) {
    Uint8List? imageBytes;
    if (product['image'] != null) {
      imageBytes = base64Decode(product['image']);
    }

    return RepaintBoundary(
      key: repaintBoundaryKeys[index],
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Display the image of the product (if available)
            Expanded(
              child: imageBytes != null
                  ? Image.memory(imageBytes, fit: BoxFit.cover)
                  : Icon(Icons.image, size: 100),
            ),

            // Display the product details split into two parts
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // First column for the first set of details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${product['name'] ?? "Unnamed"}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Type: ${product['type'] ?? "N/A"}'),
                      Text('Code: ${product['code'] ?? "N/A"}'),
                      Text('Design No: ${product['designNo'] ?? "N/A"}'),
                    ],
                  ),
                  // Second column for the second set of details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description: ${product['description'] ?? "N/A"}'),
                      Text('Size: ${product['size'] ?? "N/A"}'),
                      Text('Color: ${product['color'] ?? "N/A"}'),
                      Text('Packing: ${product['packing'] ?? "N/A"}'),
                      Text('Rate: \$${product['rate'] ?? "N/A"}'),
                    ],
                  ),
                ],
              ),
            ),

            // The trailing icon to download or mark as shared
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Shared button (show check icon when shared)
                  isShared[index]
                      ? Icon(Icons.check, color: Colors.green) // Check icon if shared
                      : SizedBox.shrink(), // Empty widget when not shared

                  // Shared action button (only show if not shared)
                  !_hideSharedButton && !isShared[index]
                      ? IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => {_shareProductCard(index, product)}, // Handle share action
                  )
                      : SizedBox.shrink(), // Empty widget if already shared

                  // Download button (only show if not hidden and not shared)
                  !_hideDownloadButton && !isShared[index]
                      ? IconButton(
                    icon: Icon(Icons.download), // Download icon
                    onPressed: () => _downloadProduct(index, repaintBoundaryKeys[index]),
                  )
                      : SizedBox.shrink(), // Empty widget when hiding download button or when shared
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProductCard(int index, Map<String, dynamic> product) async {
    try {
      // Ensure the RepaintBoundary has been painted before capturing its image
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Capture the product card content as an image after the current frame
        RenderRepaintBoundary boundary = repaintBoundaryKeys[index].currentContext!.findRenderObject() as RenderRepaintBoundary;
        var image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Save the captured image to a temporary file
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/product_card_$index.png';
        final file = io.File(imagePath);
        await file.writeAsBytes(pngBytes);

        // Share the product card as an image along with product details
        String shareText = 'Check out this product:\n\n'
            'Name: ${product['name']}\n'
            'Description: ${product['description']}\n'
            'Rate: \$${product['rate']}\n';

        await Share.shareFiles([imagePath], text: shareText);

        setState(() {
          isShared[index] = true; // Mark as shared
        });
      });
    } catch (e) {
      print("Error sharing product card: $e");
    }
  }


  bool _hideDownloadButton = false;
  bool _hideSharedButton = false;
  Future<void> _downloadProduct(int index, GlobalKey key) async {
    try {
      setState(() {
        _hideDownloadButton = true;
        _hideSharedButton = true;// Hide the download button
      });

      await Future.delayed(Duration(milliseconds: 100)); // Slight delay to allow UI to update

      if (kIsWeb) {
        // Capture the product card content as an image on the web
        RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        var image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Initiate download on web
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        print("Downloading: $url");
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = 'product_card_$index.png';
        anchor.click();
        html.Url.revokeObjectUrl(url);

        setState(() {
          isShared[index] = true;
        });
      } else {
        // Capture the product card content as an image on mobile/desktop
        RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        var image = await boundary.toImage(pixelRatio: 2.0);
        ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Save the captured image to the device's temporary directory
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/product_card_$index.png';
        final file = io.File(imagePath);
        await file.writeAsBytes(pngBytes);

        print('Saved product card image to: $imagePath');

        setState(() {
          isShared[index] = true;
        });
      }
    } catch (e) {
      print("Error downloading product card: $e");
    } finally {
      setState(() {
        _hideDownloadButton = false;
        _hideSharedButton = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final filteredProducts = products.where((product) {
      return product['name'].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _openAddProductDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(index, filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}