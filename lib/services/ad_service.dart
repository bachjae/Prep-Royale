import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  /// Set to true once your AdMob account is approved and real ad unit IDs are in place.
  static const bool enabled = false;

  static const String _zenCountKey = 'zen_total_questions';
  static const int _adEvery = 20;

  // TODO: Replace with your real AdMob ad unit IDs before publishing to stores.
  // To get real IDs, create an AdMob account at https://admob.google.com
  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712'; // Google test ID
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910'; // Google test ID

  static String get _adUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosInterstitialId
          : _androidInterstitialId;

  InterstitialAd? _interstitialAd;

  /// Call once at app startup after Firebase.initializeApp().
  Future<void> initialize() async {
    if (!enabled) return;
    await MobileAds.instance.initialize();
    await _loadInterstitialAd();
  }

  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd(); // preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows the preloaded interstitial ad if one is ready.
  Future<void> showInterstitialAd() async {
    if (!enabled || _interstitialAd == null) return;
    await _interstitialAd!.show();
  }

  /// Call after each zen mode question is answered.
  /// Increments a persistent counter and shows an ad every [_adEvery] questions.
  Future<void> onZenQuestionAnswered() async {
    if (!enabled) return;
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_zenCountKey) ?? 0) + 1;
    await prefs.setInt(_zenCountKey, count);
    if (count % _adEvery == 0) {
      await showInterstitialAd();
    }
  }
}
