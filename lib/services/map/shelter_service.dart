import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/shelter_model.dart';

class ShelterService {
  List<ShelterModel> _shelters = [];

  List<ShelterModel> get shelters => _shelters;

  Future<List<ShelterModel>> loadShelters() async {
    final jsonString = await rootBundle.loadString('assets/shelters/tokyo_shelters.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    _shelters = jsonList.map((j) => ShelterModel.fromJson(j)).toList();
    return _shelters;
  }
}
