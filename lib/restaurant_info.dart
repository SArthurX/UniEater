import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class restaurant_info extends StatefulWidget {
  final String restaurantId;

  const restaurant_info({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  _RestaurantInfoState createState() => _RestaurantInfoState();
}

class _RestaurantInfoState extends State<restaurant_info> {
  late DocumentReference<Map<String, dynamic>> restaurantRef;
  Map<String, dynamic>? restaurantData;

  @override
  void initState() {
    super.initState();
    restaurantRef = FirebaseFirestore.instance
        .collection('university')
        .doc(widget.restaurantId); 
    _fetchRestaurantData(); 
  }

  Future<void> _fetchRestaurantData() async {
    final snapshot = await restaurantRef.get();
    if (snapshot.exists) {
      setState(() {
        restaurantData = snapshot.data();
      });
    } else {
      print('data not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (restaurantData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('餐廳資訊'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantData!['name'] ?? '餐廳資訊'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPhotoCarousel(),
            _buildRestaurantInfo(),
            const Divider(),
            _buildReviewsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCarousel() {
    List<dynamic> photos = restaurantData!['photos'] ?? [];

    if (photos.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Text('Pic not found')),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(height: 200.0, autoPlay: true),
      items: photos.map((photoUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Image.network(
              photoUrl,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            restaurantData!['description'] ?? 'data not found',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 8),
              Text(
                restaurantData!['address'] ?? 'address not found',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone),
              const SizedBox(width: 8),
              Text(
                restaurantData!['phone'] ?? 'phone num not found',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHoursInfo(),
        ],
      ),
    );
  }

  Widget _buildHoursInfo() {
    Map<String, dynamic> hours = restaurantData!['hours'] ?? {};

    if (hours.isEmpty) {
      return const Text('hours not found');
    }

    List<Widget> hoursWidgets = [];
    hours.forEach((day, time) {
      hoursWidgets.add(
        Row(
          children: [
            Text(
              '$day: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('$time'),
          ],
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: hoursWidgets,
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          'User Reviews',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        _buildReviewsList(),
        _buildAddReviewButton(),
      ],
    );
  }

  Widget _buildReviewsList() {
    CollectionReference reviewsRef = restaurantRef.collection('reviews');

    return StreamBuilder<QuerySnapshot>(
      stream: reviewsRef.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        List<DocumentSnapshot> reviews = snapshot.data!.docs;

        if (reviews.isEmpty) {
          return const Text('data not found');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> reviewData =
                reviews[index].data() as Map<String, dynamic>;

            DateTime timestamp = reviewData['timestamp'].toDate();
            String formattedDate =
                DateFormat('yyyy-MM-dd HH:mm').format(timestamp);

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(reviewData['user_id'] ?? 'User'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reviewData['content'] ?? ''),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  reviewData['rating'] ?? 0,
                  (index) => const Icon(Icons.star, color: Colors.amber),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddReviewButton() {
    return ElevatedButton(
      onPressed: () {
        _showAddReviewDialog();
      },
      child: const Text('add review'),
    );
  }

  void _showAddReviewDialog() {
    TextEditingController contentController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('add review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'review content'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Dialog: '),
                  Expanded(
                    child: Slider(
                      value: rating.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$rating',
                      onChanged: (value) {
                        setState(() {
                          rating = value.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('cancel'),
            ),
            TextButton(
              onPressed: () {
                _addReview(contentController.text, rating);
                Navigator.of(context).pop();
              },
              child: const Text('submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addReview(String content, int rating) async {
    CollectionReference reviewsRef = restaurantRef.collection('reviews');

    await reviewsRef.add({
      'user_id': 'User',
      'content': content,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
