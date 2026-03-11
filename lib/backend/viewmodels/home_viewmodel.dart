import 'package:flutter/material.dart';
import 'package:safarsync_mobileapp/backend/models/chat_models.dart'; // Apne project ka naam use karein
import 'package:safarsync_mobileapp/backend/models/gig_model.dart';
import 'package:safarsync_mobileapp/backend/models/notification_model.dart';
import 'package:safarsync_mobileapp/backend/utils/view_state.dart'; // Naya import

class HomeViewModel extends ChangeNotifier {
  // --- Chat Conversations State ---
  ViewState _conversationsState = ViewState.initial;
  ViewState get conversationsState => _conversationsState;
  List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;
  String? _conversationsError;
  String? get conversationsError => _conversationsError;

  // --- Gigs State ---
  ViewState _gigsState = ViewState.initial;
  ViewState get gigsState => _gigsState;
  List<GigModel> _gigs = [];
  List<GigModel> get gigs => _gigs;
  String? _gigsError;
  String? get gigsError => _gigsError;

  // --- Notifications State ---
  ViewState _notificationsState = ViewState.initial;
  ViewState get notificationsState => _notificationsState;
  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;
  String? _notificationsError;
  String? get notificationsError => _notificationsError;

  HomeViewModel() {
    // ViewModel banate hi saara data fetch karna shuru kar dein
    fetchConversations();
    getGigs();
    getNotifications();
  }

  // --- Chat Conversations Fetch Logic ---
  Future<void> fetchConversations() async {
    _conversationsState = ViewState.loading;
    notifyListeners();
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      // Replace with actual API call and JSON parsing
      _conversations = [
        ChatConversation(
          id: 1,
          userName: "John Doe",
          userImageUrl: "https://randomuser.me/api/portraits/men/1.jpg",
          lastMessage: "Hey! How are you?",
          timestamp: "10:30 AM",
          unreadCount: 2,
        ),
        ChatConversation(
          id: 2,
          userName: "Emma Watson",
          userImageUrl: "https://randomuser.me/api/portraits/women/2.jpg",
          lastMessage: "Let's meet tomorrow!",
          timestamp: "Yesterday",
          unreadCount: 0,
        ),
        ChatConversation(
          id: 3,
          userName: "David Beckham",
          userImageUrl: "https://randomuser.me/api/portraits/men/3.jpg",
          lastMessage: "Cool, send me the details.",
          timestamp: "9:15 PM",
          unreadCount: 5,
        ),
        ChatConversation(
          id: 4,
          userName: "Jennifer Aniston",
          userImageUrl: "https://randomuser.me/api/portraits/women/4.jpg",
          lastMessage: "Okay, sounds good!",
          timestamp: "11/10/24",
          unreadCount: 0,
        ),
      ];
      _conversationsState = _conversations.isEmpty
          ? ViewState.empty
          : ViewState.loaded;
    } catch (e) {
      _conversationsState = ViewState.error;
      _conversationsError = "Failed to load chats: ${e.toString()}";
    } finally {
      notifyListeners();
    }
  }

  // --- Gigs Fetch Logic (API se data laane ka function) ---
  Future<void> getGigs() async {
    _gigsState = ViewState.loading;
    notifyListeners();
    try {
      // API call ki jagah dummy delay
      await Future.delayed(const Duration(seconds: 1));
      // Actual API call:
      // final response = await http.get(Uri.parse("https://smacltd.com/api/gigs"));
      // if (response.statusCode == 200) {
      //   List<dynamic> data = json.decode(response.body);
      //   _gigs = data.map((json) => GigModel.fromJson(json)).toList(); // Agar fromJson method model mein hai
      // } else {
      //   throw Exception("Failed to load gigs from API");
      // }

      // Dummy data (real API se aayega)
      _gigs = [
        GigModel(
          id: 1,
          title: "Flutter Developer Needed",
          status: "Active",
          description: "Looking for experienced Flutter dev for a new project.",
        ),
        GigModel(
          id: 2,
          title: "UI/UX Designer for Web",
          status: "Pending",
          description: "Seeking creative designer for web app UI.",
        ),
        GigModel(
          id: 3,
          title: "Content Writer - Tech Niche",
          status: "Completed",
          description: "Need a writer for tech articles.",
        ),
      ];
      _gigsState = _gigs.isEmpty ? ViewState.empty : ViewState.loaded;
    } catch (e) {
      _gigsState = ViewState.error;
      _gigsError = "Failed to load gigs: ${e.toString()}";
    } finally {
      notifyListeners();
    }
  }

  // --- Notifications Fetch Logic (API se data laane ka function) ---
  Future<void> getNotifications() async {
    _notificationsState = ViewState.loading;
    notifyListeners();
    try {
      // API call ki jagah dummy delay
      await Future.delayed(const Duration(seconds: 1));
      // Actual API call:
      // final response = await http.get(Uri.parse("https://smacltd.com/api/notifications"));
      // if (response.statusCode == 200) {
      //   List<dynamic> data = json.decode(response.body);
      //   _notifications = data.map((json) => NotificationModel.fromJson(json)).toList(); // Agar fromJson method model mein hai
      // } else {
      //   throw Exception("Failed to load notifications from API");
      // }

      // Dummy data (real API se aayega)
      _notifications = [
        NotificationModel(
          id: 1,
          title: "New gig posted!",
          description: "A new gig 'Flutter Dev' is available.",
          time: "5 mins ago",
        ),
        NotificationModel(
          id: 2,
          title: "Chat message from John",
          description: "John Doe sent you a message.",
          time: "1 hour ago",
        ),
        NotificationModel(
          id: 3,
          title: "Profile updated",
          description: "Your profile information was updated.",
          time: "Yesterday",
        ),
      ];
      _notificationsState = _notifications.isEmpty
          ? ViewState.empty
          : ViewState.loaded;
    } catch (e) {
      _notificationsState = ViewState.error;
      _notificationsError = "Failed to load notifications: ${e.toString()}";
    } finally {
      notifyListeners();
    }
  }
}
