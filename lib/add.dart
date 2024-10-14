import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:location/location.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({Key? key}) : super(key: key);

  @override
  _AddLocationPageState createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增地標'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '地標名稱'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: '地標描述'),
            ),
            TextField(
              controller: _hoursController,
              decoration: const InputDecoration(labelText: '營業時間'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: '地標地址'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _selectLocation,
              child: const Text('選擇位置'),
            ),
            const SizedBox(height: 16.0),
            if (_selectedLocation != null)
              Text(
                  '已選擇位置: ${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _saveLocation,
              child: const Text('保存地標'),
            ),
          ],
        ),
      ),
    );
  }

  void _selectLocation() async {
    LocationData locationData = await Location().getLocation();
    LatLng initialPosition =
        LatLng(locationData.latitude!, locationData.longitude!);
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectLocationPage(initialPosition: initialPosition),
      ),
    );
    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
    }
  }

  void _saveLocation() {
    if (_selectedLocation != null) {
      final GeoFirePoint geoFirePoint = GeoFirePoint(
        GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      );
      FirebaseFirestore.instance.collection('university').add({
        'geo': geoFirePoint.data,
        'name': _nameController.text,
        'description': _descriptionController.text,
        'hours': _hoursController.text,
        'address': _addressController.text,
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇位置')),
      );
    }
  }
}

class SelectLocationPage extends StatelessWidget {
  final LatLng initialPosition;
  const SelectLocationPage({required this.initialPosition, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇位置'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 14.0,
        ),
        onTap: (LatLng location) {
          Navigator.pop(context, location);
        },
      ),
    );
  }
}
