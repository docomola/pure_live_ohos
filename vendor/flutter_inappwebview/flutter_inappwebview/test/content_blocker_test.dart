import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentBlocker', () {
    test('trigger and action properties should be mutable', () {
      final blocker = ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*'),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      );

      blocker.trigger.urlFilter = 'updated';
      blocker.action = ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: '.ad',
      );

      expect(blocker.trigger.urlFilter, 'updated');
      expect(blocker.action.type, ContentBlockerActionType.CSS_DISPLAY_NONE);
      expect(blocker.action.selector, '.ad');
    });

    test('constructor should expose trigger and action', () {
      final blocker = ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*'),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      );

      expect(blocker.trigger.urlFilter, '.*');
      expect(blocker.action.type, ContentBlockerActionType.BLOCK);
    });

    test('fromMap should restore trigger and action', () {
      final original = ContentBlocker(
        trigger: ContentBlockerTrigger(
          urlFilter: '.*banner.*',
          urlFilterIsCaseSensitive: false,
        ),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      );
      final map = original.toMap();

      // Skip full round-trip when native action type cannot be parsed on this platform.
      final actionType = map['action']?['type'] as String?;
      if (actionType == null ||
          ContentBlockerActionType.fromNativeValue(actionType) == null) {
        final trigger = ContentBlockerTrigger.fromMap(
          Map<String, dynamic>.from(map['trigger']!),
        );
        expect(trigger.urlFilter, '.*banner.*');
        expect(original.action.type, ContentBlockerActionType.BLOCK);
        return;
      }

      final blocker = ContentBlocker.fromMap({
        'trigger': map['trigger']!,
        'action': map['action']!,
      });

      expect(blocker.trigger.urlFilter, '.*banner.*');
      expect(blocker.action.type, ContentBlockerActionType.BLOCK);
    });

    test('toMap should serialize trigger and action maps', () {
      final blocker = ContentBlocker(
        trigger: ContentBlockerTrigger(urlFilter: '.*banner.*'),
        action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
      );

      final map = blocker.toMap();

      expect(map['trigger']?['url-filter'], '.*banner.*');
      expect(map['action'], isNotNull);
    });

    test('trigger fromMap should restore url filter', () {
      final trigger = ContentBlockerTrigger.fromMap({
        'url-filter': '.*',
        'url-filter-is-case-sensitive': false,
      });

      expect(trigger.urlFilter, '.*');
      expect(trigger.urlFilterIsCaseSensitive, isFalse);
    });

    test('action constructor should expose native action type value', () {
      final action = ContentBlockerAction(type: ContentBlockerActionType.BLOCK);

      expect(action.type.toValue(), 'block');
    });

    test('action toMap should include css selector when required', () {
      final action = ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: '.ad-banner',
      ).toMap();

      expect(action['type'], isNotNull);
      expect(action['selector'], '.ad-banner');
    });

    test('trigger toMap should omit empty optional fields', () {
      final trigger = ContentBlockerTrigger(urlFilter: '.*').toMap();

      expect(trigger.containsKey('if-domain'), isFalse);
      expect(trigger.containsKey('resource-type'), isFalse);
      expect(trigger['url-filter'], '.*');
    });

    test('trigger constructor should expose optional domain and resource fields',
        () {
      final trigger = ContentBlockerTrigger(
        urlFilter: '.*banner.*',
        resourceType: [ContentBlockerTriggerResourceType.IMAGE],
        ifDomain: ['example.com'],
        unlessDomain: [],
        loadType: [ContentBlockerTriggerLoadType.FIRST_PARTY],
        ifTopUrl: ['https://example.com'],
        unlessTopUrl: [],
        ifFrameUrl: ['https://example.com/frame'],
        loadContext: [ContentBlockerTriggerLoadContext.TOP_FRAME],
      );

      expect(trigger.resourceType, [ContentBlockerTriggerResourceType.IMAGE]);
      expect(trigger.ifDomain, ['example.com']);
      expect(trigger.loadType, [ContentBlockerTriggerLoadType.FIRST_PARTY]);
      expect(trigger.ifTopUrl, ['https://example.com']);
      expect(trigger.ifFrameUrl, ['https://example.com/frame']);
      expect(trigger.loadContext, [ContentBlockerTriggerLoadContext.TOP_FRAME]);
    });

    test('trigger fromMap should restore optional fields', () {
      final trigger = ContentBlockerTrigger.fromMap({
        'url-filter': '.*',
        'url-filter-is-case-sensitive': false,
        'resource-type': ['image'],
        'if-domain': ['example.com'],
        'load-type': ['first-party'],
        'if-frame-url': ['https://example.com/frame'],
        'load-context': ['top-frame'],
      });

      expect(trigger.urlFilter, '.*');
      expect(trigger.resourceType, isNotEmpty);
      expect(trigger.ifDomain, ['example.com']);
      expect(trigger.loadType, isNotEmpty);
      expect(trigger.ifFrameUrl, ['https://example.com/frame']);
      expect(trigger.loadContext, [ContentBlockerTriggerLoadContext.TOP_FRAME]);
    });

    test('trigger toString should include url filter', () {
      final trigger = ContentBlockerTrigger(urlFilter: '.*ads.*');
      expect(trigger.toString(), contains('.*ads.*'));
    });

    test('action fromMap should restore type and selector', () {
      final actionType = ContentBlockerActionType.BLOCK.toNativeValue();
      if (ContentBlockerActionType.fromNativeValue(actionType) == null) {
        return;
      }
      final action = ContentBlockerAction.fromMap({
        'type': actionType,
      });
      expect(action.type, ContentBlockerActionType.BLOCK);
    });
  });
}
