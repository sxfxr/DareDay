import 'package:flutter/material.dart';
import '../models/dare_model.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0;
  DareModel? _activeGrindDare;
  final List<DareModel> _receivedChallenges = [];
  int _feedRefreshKey = 0;

  int get selectedIndex => _selectedIndex;
  DareModel? get activeGrindDare => _activeGrindDare;
  List<DareModel> get receivedChallenges => List.unmodifiable(_receivedChallenges);
  int get feedRefreshKey => _feedRefreshKey;

  void setTab(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void triggerFeedRefresh() {
    _feedRefreshKey++;
    notifyListeners();
  }

  void setGrindDare(DareModel? dare) {
    _activeGrindDare = dare;
    notifyListeners();
  }

  void clearGrindDare() {
    _activeGrindDare = null;
    notifyListeners();
  }

  void addChallenge(DareModel dare) {
    _receivedChallenges.insert(0, dare);
    notifyListeners();
  }

  void removeChallenge(String dareId) {
    _receivedChallenges.removeWhere((d) => d.id == dareId);
    notifyListeners();
  }
}
