import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/battle_model.dart';
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../services/cloud_fn.dart';
import '../services/firebase_service.dart';

enum BattlePhase { idle, matchmaking, found, playing, finished }

class BattleState {
  final BattlePhase phase;
  final BattleModel? battle;
  final QuestionModel? currentQuestion;
  final int? selectedAnswer;
  final int timeRemaining;
  final bool isSubmitting;
  final String? error;
  final int? myHealth;
  final int? opponentHealth;

  const BattleState({
    this.phase = BattlePhase.idle,
    this.battle,
    this.currentQuestion,
    this.selectedAnswer,
    this.timeRemaining = 30,
    this.isSubmitting = false,
    this.error,
    this.myHealth,
    this.opponentHealth,
  });

  BattleState copyWith({
    BattlePhase? phase,
    BattleModel? battle,
    QuestionModel? currentQuestion,
    int? selectedAnswer,
    int? timeRemaining,
    bool? isSubmitting,
    String? error,
    int? myHealth,
    int? opponentHealth,
  }) {
    return BattleState(
      phase: phase ?? this.phase,
      battle: battle ?? this.battle,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      selectedAnswer: selectedAnswer,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      myHealth: myHealth ?? this.myHealth,
      opponentHealth: opponentHealth ?? this.opponentHealth,
    );
  }
}

class BattleNotifier extends StateNotifier<BattleState> {
  final Ref _ref;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  StreamSubscription? _battleSubscription;
  Timer? _timer;

  BattleNotifier(this._ref) : super(const BattleState());

  // Join matchmaking queue
  Future<void> joinMatchmaking({required String testType}) async {
    state = state.copyWith(phase: BattlePhase.matchmaking, error: null);

    try {
      // Use direct HTTP call to bypass Firebase callable SDK's App Check blocker
      final result = await callFn('joinMatchmaking', {'testType': testType});

      final battleId = (result as Map<String, dynamic>?)?['battleId'] as String?;
      if (battleId != null) {
        _subscribeToBattle(battleId);
      }
    } on CloudFnException catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error: _friendlyError(e.code, e.message, 'join matchmaking'),
      );
    } catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error:
            'Failed to join matchmaking. Please check your connection and try again.',
      );
    }
  }

  // Start a battle with a friend
  Future<void> startFriendBattle(
      {required String friendId, String testType = 'SAT'}) async {
    state = state.copyWith(phase: BattlePhase.matchmaking, error: null);

    try {
      final result = await callFn('createFriendBattle', {
        'friendId': friendId,
        'testType': testType,
      });

      final battleId = (result as Map<String, dynamic>?)?['battleId'] as String?;
      if (battleId != null) {
        _subscribeToBattle(battleId);
      }
    } on CloudFnException catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error: _friendlyError(e.code, e.message, 'start friend battle'),
      );
    } catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error:
            'Failed to start friend battle. Please check your connection and try again.',
      );
    }
  }

  // Subscribe to battle updates
  void _subscribeToBattle(String battleId) {
    _battleSubscription?.cancel();

    final battleRef = _rtdb.ref('battles/$battleId');
    _battleSubscription = battleRef.onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final battle = BattleModel.fromRealtimeDb(battleId, data);

      _handleBattleUpdate(battle);
    });
  }

  void _handleBattleUpdate(BattleModel battle) async {
    final userId = _ref.read(currentUserIdProvider);

    // Check if battle has started
    if (battle.status == BattleStatus.waiting && battle.player2 != null) {
      state = state.copyWith(
        phase: BattlePhase.found,
        battle: battle,
      );
      return;
    }

    if (battle.status == BattleStatus.inProgress) {
      // Load current question if needed
      QuestionModel? question = state.currentQuestion;
      if (question == null ||
          battle.currentQuestionIndex != state.battle?.currentQuestionIndex) {
        question = await _loadQuestion(
            battle.questionIds[battle.currentQuestionIndex]);
        _startQuestionTimer();
      }

      // Derive health from the battle players
      final isPlayer1 = battle.player1.odId == userId;
      final myPlayer = isPlayer1 ? battle.player1 : battle.player2;
      final opponent = isPlayer1 ? battle.player2 : battle.player1;

      state = state.copyWith(
        phase: BattlePhase.playing,
        battle: battle,
        currentQuestion: question,
        myHealth: myPlayer?.health ?? 100,
        opponentHealth: opponent?.health ?? 100,
      );
      return;
    }

    if (battle.status == BattleStatus.completed) {
      _timer?.cancel();

      // Note: Battle stats and XP are updated server-side in submitBattleAnswer
      // to prevent double-counting. Client only updates UI state here.

      state = state.copyWith(
        phase: BattlePhase.finished,
        battle: battle,
      );
    }
  }

  Future<QuestionModel?> _loadQuestion(String questionId) async {
    final firebaseService = _ref.read(firebaseServiceProvider);
    return await firebaseService.getQuestion(questionId);
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    state = state.copyWith(timeRemaining: 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 1) {
        timer.cancel();
        // Auto-submit if time runs out
        if (state.selectedAnswer == null) {
          submitAnswer(-1); // -1 indicates no answer
        }
      } else {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      }
    });
  }

  // Select an answer
  void selectAnswer(int answer) {
    state = state.copyWith(selectedAnswer: answer);
  }

  // Submit answer
  // NOTE: Damage calculation now happens server-side for security
  Future<void> submitAnswer(int answer) async {
    if (state.battle == null || state.currentQuestion == null) return;
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      // Use direct HTTP call — bypasses Firebase callable SDK's App Check blocker
      await callFn('submitBattleAnswer', {
        'battleId': state.battle!.id,
        'questionIndex': state.battle!.currentQuestionIndex,
        'answer': answer,
      });
    } on CloudFnException catch (e) {
      state = state.copyWith(
          error: _friendlyError(e.code, e.message, 'submit answer'));
    } catch (e) {
      state =
          state.copyWith(error: 'Failed to submit answer. Please try again.');
    } finally {
      state = state.copyWith(isSubmitting: false, selectedAnswer: null);
    }
  }

  // Leave battle/matchmaking
  void leaveBattle() {
    _timer?.cancel();
    _battleSubscription?.cancel();
    state = const BattleState();
  }

  String _friendlyError(String code, String? message, String action) {
    switch (code) {
      case 'not_found':
      case 'not-found':
        return 'Game service unavailable. Please make sure the server is running.';
      case 'unauthenticated':
        return 'You must be signed in to $action.';
      case 'permission_denied':
      case 'permission-denied':
        return 'You do not have permission to $action.';
      case 'unavailable':
        return 'Game service is temporarily unavailable. Please try again later.';
      case 'deadline_exceeded':
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      default:
        return message ?? 'Failed to $action. Please try again.';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _battleSubscription?.cancel();
    super.dispose();
  }
}

final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>((ref) {
  return BattleNotifier(ref);
});
