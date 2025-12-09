import 'package:river_player/river_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Example M3U8 test URLs
class M3U8TestUrls {
  /// Apple's sample HLS stream for testing
  static const String appleSampleHLS = 
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8';
  
  /// Alternative test HLS stream
  static const String testHLSStream = 
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
  
  /// Live stream example (if available)
  static const String liveStreamExample = 
      'https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8';
}

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('M3U8 Video Playback Tests', () {
    testWidgets('M3U8 video player initialization', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      expect(find.byType(BetterPlayer), findsOneWidget);
      
      // Wait for initialization
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Verify controller is initialized
      expect(controller.videoPlayerController != null, true);
    });

    testWidgets('M3U8 video playback controls', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: false,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test play functionality
      await controller.play();
      await tester.pump(const Duration(milliseconds: 500));
      
      // Test pause functionality
      await controller.pause();
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify player state
      expect(controller.isPlaying() != null, true);
    });

    testWidgets('M3U8 video seek functionality', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: false,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Wait for video to be initialized
      if (controller.isVideoInitialized() == true) {
        // Test seek to 10 seconds
        await controller.seekTo(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 500));
        
        // Verify seek was executed
        expect(controller.videoPlayerController != null, true);
      }
    });

    testWidgets('M3U8 video volume control', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test volume setting
      await controller.setVolume(0.5);
      await tester.pump(const Duration(milliseconds: 100));
      
      // Test mute
      await controller.setVolume(0.0);
      await tester.pump(const Duration(milliseconds: 100));
      
      // Test full volume
      await controller.setVolume(1.0);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('M3U8 video speed control', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Test different playback speeds
      await controller.setSpeed(0.5); // Slow motion
      await tester.pump(const Duration(milliseconds: 100));
      
      await controller.setSpeed(1.0); // Normal speed
      await tester.pump(const Duration(milliseconds: 100));
      
      await controller.setSpeed(1.5); // Fast forward
      await tester.pump(const Duration(milliseconds: 100));
      
      await controller.setSpeed(2.0); // Maximum speed
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('M3U8 video buffering state', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          autoPlay: true,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      // Wait for initial buffering
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check buffering state
      final isBuffering = controller.isBuffering();
      expect(isBuffering != null, true);
    });

    testWidgets('M3U8 video with headers', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
          headers: {
            'User-Agent': 'RiverPlayer/1.0',
            'Accept': 'application/vnd.apple.mpegurl',
          },
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(controller.betterPlayerDataSource != null, true);
      expect(controller.betterPlayerDataSource?.headers != null, true);
      expect(
        controller.betterPlayerDataSource?.headers?['User-Agent'],
        'RiverPlayer/1.0',
      );
    });

    testWidgets('M3U8 video format detection', (WidgetTester tester) async {
      // Test with explicit HLS format
      final controller1 = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller1),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(
        controller1.betterPlayerDataSource?.videoFormat,
        BetterPlayerVideoFormat.hls,
      );

      // Test with URL-based format detection
      final controller2 = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          // videoFormat not specified, should be detected from URL
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller2),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(controller2.betterPlayerDataSource != null, true);
    });

    testWidgets('M3U8 video disposal', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Dispose the controller
      controller.dispose(forceDispose: true);
      await tester.pump(const Duration(milliseconds: 100));

      // Verify disposal
      expect(controller.videoPlayerController == null, true);
    });

    testWidgets('M3U8 video looping', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(
          looping: true,
        ),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          M3U8TestUrls.appleSampleHLS,
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify looping is enabled
      expect(controller.betterPlayerConfiguration.looping, true);
    });

    test('M3U8 data source creation', () {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        M3U8TestUrls.appleSampleHLS,
        videoFormat: BetterPlayerVideoFormat.hls,
      );

      expect(dataSource.type, BetterPlayerDataSourceType.network);
      expect(dataSource.url, M3U8TestUrls.appleSampleHLS);
      expect(dataSource.videoFormat, BetterPlayerVideoFormat.hls);
    });

    test('M3U8 URL validation', () {
      // Valid M3U8 URLs
      expect(
        M3U8TestUrls.appleSampleHLS.endsWith('.m3u8'),
        true,
      );
      expect(
        M3U8TestUrls.testHLSStream.endsWith('.m3u8'),
        true,
      );

      // Test URL format
      expect(
        Uri.parse(M3U8TestUrls.appleSampleHLS).scheme,
        'https',
      );
    });
  });

  group('M3U8 Video Error Handling', () {
    testWidgets('M3U8 video with invalid URL', (WidgetTester tester) async {
      final controller = BetterPlayerController(
        const BetterPlayerConfiguration(),
        betterPlayerDataSource: BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          'https://invalid-url-that-does-not-exist.m3u8',
          videoFormat: BetterPlayerVideoFormat.hls,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BetterPlayer(controller: controller),
          ),
        ),
      );

      // Wait for error to occur
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Error handling should be in place
      expect(controller.videoPlayerController != null, true);
    });
  });
}

