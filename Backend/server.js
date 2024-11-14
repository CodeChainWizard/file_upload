// server.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 5000;

// MongoDB URI
const mongoURI = 'mongodb+srv://Shubham:shubham%24123@cluster0.gcpxv.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';

// Connect to MongoDB
mongoose.connect(mongoURI)
  .then(() => console.log('Connected to MongoDB Atlas'))
  .catch(error => console.error('Failed to connect to MongoDB Atlas:', error));

// Middleware
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// Product model
const productSchema = new mongoose.Schema({
  type: String,
  code: String,
  designNo: String,
  name: String,
  description: String,
  size: String,
  color: String,
  packing: String,
  rate: Number,
  image: String,
});
const Product = mongoose.model('Product', productSchema);

// Routes
app.get('/api/products', async (req, res) => {
  try {
    const products = await Product.find();
    res.json(products);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).send('Error fetching products');
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const product = new Product(req.body);
    const savedProduct = await product.save();
    res.status(201).json(savedProduct);
  } catch (error) {
    console.error('Error adding product:', error);
    res.status(500).json({ error: 'Failed to add product' });
  }
});

app.get('/api/download-products', async (req, res) => {
  try {
    const products = await Product.find();
    const formattedProducts = products.map(product => ({
      name: product.name,
      price: `${product.rate}/-`,
      length: `${product.size} Meters`,
      description: product.description,
      image: product.image,
    }));
    res.setHeader('Content-Disposition', 'attachment; filename="products.json"');
    res.setHeader('Content-Type', 'application/json');
    res.status(200).json(formattedProducts);
  } catch (error) {
    console.error('Error downloading products:', error);
    res.status(500).json({ error: 'Failed to download products' });
  }
});

app.get('/api/share-product/:id', async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ error: 'Product not found' });

    const whatsappMessage = `Check out this product:\n\nName: ${product.name}\nDescription: ${product.description}\nPrice: $${product.rate}\n\nView image: ${product.image}`;
    const whatsappLink = `https://api.whatsapp.com/send?text=${encodeURIComponent(whatsappMessage)}`;
    res.json({ whatsappLink });
  } catch (error) {
    console.error('Error sharing product on WhatsApp:', error);
    res.status(500).json({ error: 'Failed to share product on WhatsApp' });
  }
});

app.listen(port, () => console.log(`Server running on http://localhost:${port}`));
