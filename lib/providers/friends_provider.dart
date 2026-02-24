import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/friendship_model.dart';
import '../providers/auth_provider.dart';

/// Stream of all accepted friendships for the current user
final friendshipsStreamProvider = StreamProvider<List<FriendshipModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  // Query friendships where user is user1 and status is accepted
  final stream1 = firestore
      .collection('friendships')
      .where('user1Id', isEqualTo: userId)
      .where('status', isEqualTo: 'accepted')
      .snapshots();

  // Combine with friendships where user is user2
  return stream1.asyncMap((snapshot1) async {
    final snapshot2 = await firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    final friendships = <FriendshipModel>[];

    for (final doc in snapshot1.docs) {
      friendships.add(FriendshipModel.fromFirestore(doc));
    }
    for (final doc in snapshot2.docs) {
      friendships.add(FriendshipModel.fromFirestore(doc));
    }

    return friendships;
  });
});

/// Stream of pending friend requests received by the current user
final pendingRequestsStreamProvider =
    StreamProvider<List<FriendRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;

  // Query pending friendships where user is a participant but not the requester
  return firestore
      .collection('friendships')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snapshot) {
    final requests = <FriendRequest>[];

    for (final doc in snapshot.docs) {
      final friendship = FriendshipModel.fromFirestore(doc);
      // Only include if user is the recipient (not the requester)
      if (friendship.isRecipient(userId)) {
        requests.add(FriendRequest.fromFriendship(friendship));
      }
    }

    // Sort by most recent first
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  });
});

/// Stream of friends with their full profile information
final friendsWithProfilesProvider =
    StreamProvider<List<FriendWithProfile>>((ref) {
  final friendshipsAsync = ref.watch(friendshipsStreamProvider);
  final userId = ref.watch(currentUserIdProvider);

  return friendshipsAsync.when(
    data: (friendships) async* {
      if (userId == null || friendships.isEmpty) {
        yield [];
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // Fetch friend profiles
      final friendProfiles = <FriendWithProfile>[];

      for (final friendship in friendships) {
        final friendId = friendship.getFriendId(userId);
        final userDoc = await firestore.collection('users').doc(friendId).get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          friendProfiles.add(FriendWithProfile(
            odId: friendId,
            username: data['username'] ?? '',
            profilePictureUrl: data['profilePictureUrl'],
            level: data['level'] ?? 1,
            totalXp: data['totalXp'] ?? 0,
            friendshipId: friendship.id,
          ));
        }
      }

      // Sort by level (highest first)
      friendProfiles.sort((a, b) => b.level.compareTo(a.level));
      yield friendProfiles;
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Friends Leaderboard Provider
final friendsLeaderboardProvider =
    FutureProvider<List<FriendWithProfile>>((ref) async {
  final functions = FirebaseFunctions.instance;
  try {
    final result =
        await functions.httpsCallable('getFriendsLeaderboard').call();
    final entries = (result.data['entries'] as List);

    return entries.map((e) {
      final map = Map<String, dynamic>.from(e);
      return FriendWithProfile(
        odId: map['odUserId'] ?? '',
        username: map['username'] ?? '',
        profilePictureUrl: map['profilePictureUrl'],
        level: map['level'] ?? 1,
        totalXp: map['totalXp'] ?? 0,
        friendshipId:
            '', // Leaderboard entries don't need a specific friendship ID here
      );
    }).toList();
  } catch (e) {
    print('Failed to get friends leaderboard: $e');
    return [];
  }
});

/// Count of pending friend requests
final pendingRequestsCountProvider = Provider<int>((ref) {
  final requestsAsync = ref.watch(pendingRequestsStreamProvider);
  return requestsAsync.when(
    data: (requests) => requests.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Result from looking up a user by friend code
class FriendCodeLookupResult {
  final String odId;
  final String username;
  final String? profilePictureUrl;
  final int level;

  const FriendCodeLookupResult({
    required this.odId,
    required this.username,
    this.profilePictureUrl,
    required this.level,
  });

  factory FriendCodeLookupResult.fromMap(Map<String, dynamic> map) {
    return FriendCodeLookupResult(
      odId: map['odId'] ?? map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      level: map['level'] ?? 1,
    );
  }
}

/// State for friend operations
class FriendsState {
  final bool isLoading;
  final String? error;
  final List<UserSearchResult> searchResults;
  final bool isSearching;
  final String? myFriendCode;
  final bool isLoadingFriendCode;
  final FriendCodeLookupResult? friendCodeLookupResult;
  final bool isLookingUpFriendCode;

  const FriendsState({
    this.isLoading = false,
    this.error,
    this.searchResults = const [],
    this.isSearching = false,
    this.myFriendCode,
    this.isLoadingFriendCode = false,
    this.friendCodeLookupResult,
    this.isLookingUpFriendCode = false,
  });

  FriendsState copyWith({
    bool? isLoading,
    String? error,
    List<UserSearchResult>? searchResults,
    bool? isSearching,
    String? myFriendCode,
    bool? isLoadingFriendCode,
    FriendCodeLookupResult? friendCodeLookupResult,
    bool? isLookingUpFriendCode,
    bool clearFriendCodeLookup = false,
  }) {
    return FriendsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      myFriendCode: myFriendCode ?? this.myFriendCode,
      isLoadingFriendCode: isLoadingFriendCode ?? this.isLoadingFriendCode,
      friendCodeLookupResult: clearFriendCodeLookup
          ? null
          : (friendCodeLookupResult ?? this.friendCodeLookupResult),
      isLookingUpFriendCode:
          isLookingUpFriendCode ?? this.isLookingUpFriendCode,
    );
  }
}

/// Notifier for friend operations
class FriendsNotifier extends StateNotifier<FriendsState> {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  FriendsNotifier() : super(const FriendsState());

  /// Search for users by username
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true, error: null);

    try {
      final callable = _functions.httpsCallable('searchUsers');
      final result = await callable.call({'query': query, 'limit': 10});

      final users = (result.data['users'] as List)
          .map((u) => UserSearchResult.fromMap(Map<String, dynamic>.from(u)))
          .toList();

      state = state.copyWith(searchResults: users, isSearching: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search users: $e',
        isSearching: false,
      );
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: [], isSearching: false, error: null);
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(String toUserId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final callable = _functions.httpsCallable('sendFriendRequest');
      await callable.call({'toUserId': toUserId});

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to send friend request';
      if (e is FirebaseFunctionsException) {
        errorMessage = e.message ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  /// Respond to a friend request
  Future<bool> respondToFriendRequest(String friendshipId, bool accept) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final callable = _functions.httpsCallable('respondToFriendRequest');
      await callable.call({'friendshipId': friendshipId, 'accept': accept});

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      String errorMessage =
          accept ? 'Failed to accept request' : 'Failed to decline request';
      if (e is FirebaseFunctionsException) {
        errorMessage = e.message ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final callable = _functions.httpsCallable('removeFriend');
      await callable.call({'friendshipId': friendshipId});

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to remove friend: $e',
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get the current user's friend code
  Future<void> getMyFriendCode() async {
    if (state.myFriendCode != null) return; // Already loaded

    state = state.copyWith(isLoadingFriendCode: true, error: null);

    try {
      final callable = _functions.httpsCallable('getMyFriendCode');
      final result = await callable.call();

      final friendCode = result.data['friendCode'] as String?;
      state = state.copyWith(
        myFriendCode: friendCode,
        isLoadingFriendCode: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingFriendCode: false,
        error: 'Failed to get friend code: $e',
      );
    }
  }

  /// Look up a user by their friend code
  Future<void> lookupUserByFriendCode(String friendCode) async {
    if (friendCode.length != 8) {
      state = state.copyWith(
        error: 'Friend code must be 8 characters',
        isLookingUpFriendCode: false,
        clearFriendCodeLookup: true,
      );
      return;
    }

    state = state.copyWith(
      isLookingUpFriendCode: true,
      error: null,
      clearFriendCodeLookup: true,
    );

    try {
      final callable = _functions.httpsCallable('getUserByFriendCode');
      final result =
          await callable.call({'friendCode': friendCode.toUpperCase()});

      final userData = result.data;
      if (userData == null || userData['userId'] == null) {
        state = state.copyWith(
          isLookingUpFriendCode: false,
          error: 'No user found with this friend code',
          clearFriendCodeLookup: true,
        );
        return;
      }

      final lookupResult = FriendCodeLookupResult.fromMap(
        Map<String, dynamic>.from(userData),
      );

      state = state.copyWith(
        friendCodeLookupResult: lookupResult,
        isLookingUpFriendCode: false,
      );
    } catch (e) {
      String errorMessage = 'Failed to look up friend code';
      if (e is FirebaseFunctionsException) {
        errorMessage = e.message ?? errorMessage;
      }
      state = state.copyWith(
        isLookingUpFriendCode: false,
        error: errorMessage,
        clearFriendCodeLookup: true,
      );
    }
  }

  /// Send a friend request using a friend code
  Future<bool> sendFriendRequestByCode(String friendCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final callable = _functions.httpsCallable('sendFriendRequestByCode');
      await callable.call({'friendCode': friendCode.toUpperCase()});

      state = state.copyWith(isLoading: false, clearFriendCodeLookup: true);
      return true;
    } catch (e) {
      String errorMessage = 'Failed to send friend request';
      if (e is FirebaseFunctionsException) {
        errorMessage = e.message ?? errorMessage;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  /// Clear the friend code lookup result
  void clearFriendCodeLookup() {
    state = state.copyWith(clearFriendCodeLookup: true);
  }
}

/// Provider for friend operations
final friendsProvider =
    StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  return FriendsNotifier();
});
