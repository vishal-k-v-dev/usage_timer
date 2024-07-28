import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdUnits{
  static const String bannerAdUnit  = "ca-app-pub-7284288989154980/7784509993";
  static const String nativeAdUnit  = "ca-app-pub-7284288989154980/1027529955";
  static const String interestitialAdUnit = "ca-app-pub-7284288989154980/9107547564";
}

class BannerAdWidget extends StatefulWidget {
  @override
  _BannerAdExampleState createState() => _BannerAdExampleState();
}

class _BannerAdExampleState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool adLoaded = false;
  bool adError = false;

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: AdUnits.bannerAdUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      size: AdSize.banner, //AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          adLoaded = true;
          setState(() {});
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          setState((){adError = true;});
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (adLoaded) ?
    Padding(
      padding: const EdgeInsets.only(left : 12.0, right: 16.0),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white, width: 2.5),
          color: Colors.white,
        ),
        width: MediaQuery.of(context).size.width,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),  
        ),
    ) : 
    Visibility(
      visible: !adError,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 12.0),
        child: Container(
          height: _bannerAd!.size.height.toDouble(),
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color.fromARGB(255, 42, 42, 42), width: 2.5),
            color: const Color.fromARGB(255, 42, 42, 42),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: 1/1,
              child: CircularProgressIndicator(color: Colors.green)
            ),
          ),
        ),      
      ),
    );
  }
}


class NativeAdWidget extends StatefulWidget {
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _adFailedToLoad = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: AdUnits.nativeAdUnit,     
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _adFailedToLoad = true;
          });
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        callToActionTextStyle: NativeTemplateTextStyle(
          backgroundColor: Colors.green, 
          textColor: Colors.white,
        )
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return _isAdLoaded
    ? Visibility(
      visible: !_adFailedToLoad,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 12),
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          height: 100,
          child: AdWidget(ad: _nativeAd!)
        ),
      ),
      replacement: BannerAdWidget(),
    )
    : Visibility(
      visible: !_adFailedToLoad,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width,
          height: 99,
          color: const Color.fromARGB(255, 42, 42, 42),
          child: const CircularProgressIndicator(color: Colors.green)
        ),
      ),
      replacement: BannerAdWidget(),
    );
  }
}

class AdManager {
  // AdMob InterstitialAd instance
  InterstitialAd? _interstitialAd;

  // Method to initialize and load the interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdUnits.interestitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          // Handle the error
        },
      ),
    );
  }

  // Method to show the interstitial ad
  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (Ad ad) {
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
          ad.dispose();
        },
      );
      _interstitialAd!.show();
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _interstitialAd?.dispose();
  }
}

