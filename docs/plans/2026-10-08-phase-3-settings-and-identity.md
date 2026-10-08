# Phase 3 — Settings and Identity Scope Plan

> **For agentic workers:** The user authorized the entire phase without routine stops. This is durable scope/evidence state; public interfaces and executable tasks are defined after the accepted Phase 2 runtime interface. Do not treat a partial settings demo as phase completion.

**Goal:** Preserve compiled Core settings/default/persistence/change semantics, identity/certificate functionality, logs, favorite state and reserved slots through tested Foundation APIs and native example scenarios.

**Architecture:** Focused services operate within the accepted single-runtime coordinator. Immutable Foundation snapshots copy Core-owned values. Listener adapters copy payloads and defer client delivery outside Core locks; services do not reimplement Core algorithms.

**Spec:** [Roadmap](../roadmap.md), [API policy](../api-design.md), accepted [settings](../coverage/domains/settings.json), [crypto](../coverage/domains/crypto.json), [logs](../coverage/domains/logs.json), [favorites](../coverage/domains/favorites.json), identity portions of [hub](../coverage/domains/hub.json).

## Sequencing

- [ ] Accept and integrate Phase 2, then create a Phase 3 feature directly from develop.
- [ ] Define complete public units and imported Swift usage, mirrored tests and concrete acceptance for each service below.
- [ ] Execute each independently testable point with TDD, persistent ownership and independent review.
- [ ] Verify workspace and relocated XCFramework/SPM consumption, example scenarios and coverage rows, integrate/publish Phase 3 and stop before Phase 4.

## Settings and persisted state

### Point 1 — Pinned setting catalog

**Files:** Source/AirDCObjC/Public/Settings/ADCSettingDescriptor.h and ADCSettingsCatalog.h; mirrored Private/Settings implementations and Test/AirDCObjC/Private/Settings tests; scripts/generate-settings-catalog; config/settings-catalog.json and generated private enum-reference table. Public umbrella/module/export configuration follows the existing explicit policy. No runtime or settings mutation is needed for this point.

```objc
#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ADCSettingValueType) {
    ADCSettingValueTypeString = 0,
    ADCSettingValueTypeInteger = 1,
    ADCSettingValueTypeBoolean = 2,
    ADCSettingValueTypeInt64 = 3,
};
@interface ADCSettingDescriptor : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly) ADCSettingValueType valueType;
@property(nonatomic, readonly, getter=isAvailable) BOOL available;
@property(nonatomic, readonly, nullable, copy) NSString *unavailabilityReason;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCSettingDescriptor.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCSettingsCatalog : NSObject
@property(class, nonatomic, readonly, copy) NSArray<ADCSettingDescriptor *> *descriptors;
+ (nullable ADCSettingDescriptor *)descriptorForIdentifier:(NSString *)identifier;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

Descriptors are immutable process-independent values; copying may return self. Identifiers are exact case-sensitive source enum symbols. Unknown symbols return nil. Catalog order follows source declaration order and includes all 628 real keys exactly once. Numeric Core values remain private. Availability describes the accepted artifact, not hypothetical future builds.

The generator verifies the pinned commit/header digest, parses only the four setting-key enums with conditional provenance, excludes boundary markers and option enums, and emits reproducible JSON plus private C++ entries referencing actual compiled enum constants. Validate the 237 compiled references with the matching installed header/compiler; never infer numeric positions of conditional keys. Unavailable entries have no numeric value. A check mode compares generated output without rewriting it. Existing scratch evidence is input to this implementation, not a replacement for a tracked reproducible generator.

- [ ] TDD: exact total/type/availability counts, unique ordered identifiers, representative conditional/Int64 lookup, unknown/case mismatch, immutable copies and value lifetime independent of runtime.
- [ ] Generator check: pinned header drift, unexpected enum shape, duplicate or missing key, sentinel inclusion and compiled-table mismatch fail clearly.
- [ ] Native and root/relocated package tests, Foundation-only Objective-C/Swift imports, explicit exports and independent review PASS before committing the point.

Point 1 received independent design PASS on 2026-10-08. Implementation waits for the Phase 3 feature branch from accepted Phase 2 develop integration.

### Point 2 — Typed values and change application (contract to finalize)

Use immutable ADCSettingValue units with distinct string, signed 32-bit integer, Boolean and signed 64-bit constructors. Do not accept an untyped NSNumber setter that silently truncates floating-point or unsigned values. ADCSettingSnapshot copies identifier, effective/raw/default typed values, explicit-set and default-equality flags. No snapshot retains a manager or pointer.

ADCSettingsService binds to an ADCRuntime and accepts stable catalog identifiers. Unknown identifiers, unavailable settings and value-type mismatches reject before Core array access. An accepted command validates its full mutation list before changing any setting. Operations represent set, force-set, unset, default mutation and original string-backed conversion separately; setting behavior remains Core-owned. A validated command is not a rollback transaction: document any partial effects from a later upstream error.

Change application constructs the original SettingHolder before the first mutation, then calls apply after mutations on the dedicated Core thread, copying its diagnostics for deferred client delivery. Plain mutations can intentionally omit apply. Handler order and final myInfoUpdated semantics are tested against actual Core, including the no-change case. Int64 never passes through getSettingValue or SettingHolder's unsupported generic variant; typed counter mutation/read still works.

Before implementation, add complete public headers, exact mutation/result/event types and concrete tests for admission/drain/lifetime, all 237 readable default types, representative original setter normalization, every mutation operation, invalid-type/range/unavailable rejection, String conversion and apply ordering. Profile/history/HubSettings/XML/log/favorite/identity/crypto points are separate and cannot be replaced by this initial typed-value proof.

Proposed complete public header units for this point (independent design review still required):

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCSettingDescriptor.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCSettingValue : NSObject <NSCopying>
@property(nonatomic, readonly) ADCSettingValueType valueType;
@property(nonatomic, readonly, nullable, copy) NSString *stringValue;
@property(nonatomic, readonly) int32_t integerValue;
@property(nonatomic, readonly) BOOL booleanValue;
@property(nonatomic, readonly) int64_t int64Value;
+ (instancetype)valueWithString:(NSString *)value;
+ (instancetype)valueWithInteger:(int32_t)value;
+ (instancetype)valueWithBoolean:(BOOL)value;
+ (instancetype)valueWithInt64:(int64_t)value;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCSettingValue.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCSettingSnapshot : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly, copy) ADCSettingValue *effectiveValue;
@property(nonatomic, readonly, copy) ADCSettingValue *rawValue;
@property(nonatomic, readonly, copy) ADCSettingValue *defaultValue;
@property(nonatomic, readonly, getter=isExplicitlySet) BOOL explicitlySet;
@property(nonatomic, readonly, getter=isDefaultValue) BOOL defaultValueEqual;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCSettingValue.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSInteger, ADCSettingMutationOperation) {
    ADCSettingMutationSet = 0,
    ADCSettingMutationForceSet = 1,
    ADCSettingMutationUnset = 2,
    ADCSettingMutationSetDefault = 3,
    ADCSettingMutationSetFromString = 4,
};
@interface ADCSettingMutation : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSString *identifier;
@property(nonatomic, readonly) ADCSettingMutationOperation operation;
@property(nonatomic, readonly, nullable, copy) ADCSettingValue *value;
+ (instancetype)setIdentifier:(NSString *)identifier value:(ADCSettingValue *)value force:(BOOL)force;
+ (instancetype)unsetIdentifier:(NSString *)identifier;
+ (instancetype)setDefaultForIdentifier:(NSString *)identifier value:(ADCSettingValue *)value;
+ (instancetype)setIdentifier:(NSString *)identifier fromString:(NSString *)value;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

```objc
#import <Foundation/Foundation.h>
#import <AirDCObjC/ADCRuntime.h>
#import <AirDCObjC/ADCSettingSnapshot.h>
#import <AirDCObjC/ADCSettingMutation.h>
NS_ASSUME_NONNULL_BEGIN
@interface ADCSettingsMutationResult : NSObject <NSCopying>
@property(nonatomic, readonly, copy) NSArray<ADCSettingSnapshot *> *snapshots;
@property(nonatomic, readonly, copy) NSArray<NSString *> *diagnostics;
@property(nonatomic, readonly) BOOL changesApplied;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
@interface ADCSettingsService : NSObject
- (instancetype)initWithRuntime:(ADCRuntime *)runtime NS_DESIGNATED_INITIALIZER;
- (void)readSettings:(NSArray<NSString *> *)identifiers
          completion:(void (^)(NSArray<ADCSettingSnapshot *> * _Nullable snapshots,
                                NSError * _Nullable error))completion;
- (void)mutateSettings:(NSArray<ADCSettingMutation *> *)mutations
         applyChanges:(BOOL)applyChanges
           completion:(void (^)(ADCSettingsMutationResult * _Nullable result,
                                 NSError * _Nullable error))completion;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END
```

Only the matching typed value property is meaningful; other numeric properties are zero and stringValue is nil for numeric values. Values implement equality/hash by type plus original logical value. Snapshots/results are immutable copies. A read returns requested order, including repeated identifiers; an empty read succeeds with an empty array when running. A mutation result returns one final snapshot per first-seen affected identifier, in first-seen order, plus original handler diagnostics. `changesApplied` says whether SettingHolder.apply was invoked, not whether values changed or persisted. Empty mutations with applyChanges=true still invoke the original no-change apply path. SetFromString uses Core's exact bool/int/Int64 string conversions; string settings use their ordinary string setter. Validation errors contain no partial mutations. No change-handler callback runs client code.

Point 2 received independent design review with no material blockers on 2026-10-08. Accepted read/mutation commands execute and complete in runtime queue-admission order; ordering between genuinely concurrent callers is unspecified. Immediate rejected commands can complete before earlier accepted work finishes. Copy input arrays and identifier/string values before asynchronous submission, so later caller mutation cannot change an admitted command. Test this boundary explicitly.

The pinned source has 628 real keys: 145 strings, 218 integers, 263 Booleans and 2 Int64. The accepted non-GUI macOS artifact compiles 237: 46 strings, 91 integers, 98 Booleans and 2 Int64. Another 391 keys require conditional Windows GUI functionality; they must have explicit unavailable descriptors/gaps, never a no-op setter or verified status. This phase does not silently turn platform absence into completed full parity.

Public identifiers use source enum symbols, not numeric enum values that shift by build. Generate a pinned-symbol/type/availability catalog against the matching header and verify every real key/sentinel/condition. Do not access private settingTags or arrays.

Required operations: typed effective/raw/default values; explicit/default/set-state; set/forceSet/unset/default mutation; string-backed conversion semantics; XML load/save/backup and mutable XML listener support; profile defaults/overrides/conflicts/reset; histories; HubSettings merge/load/save; option/profile models; change application via the original SettingHolder.

Core generic getSettingValue has no Int64 path; use original typed accessors for the two counters. SettingHolder snapshots registered handlers, applies once per changed key in registration order, then invokes ClientManager.myInfoUpdated once even when no keys changed. Plain setters do not invoke handlers. Keep holder lifetime inside stable manager/handler lifetime and invoke outside listener/adapter locks.

Services use the private runtime operation seam: admission only while Running, execution on the dedicated Core thread, copied result/error completion on serial client delivery, and accepted stop drains previously admitted operations. Values remain usable after stop; services reject Core-dependent work then. Where initial-load events are required, private lifecycle participation installs listeners during Core's module-init hook before settings load and removes/drains them before manager destruction. This is private orchestration, not an exported C++ API. Exact participant ownership and registration/start races require review and tests in the service point.

### XML boundary evidence

Core Load/Save listeners receive mutable SimpleXML under Speaker's listener lock. Client code cannot execute there. SimpleXML has no generic fragment import/clone or child/attribute enumeration API; its serializer does not preserve arbitrary mixed-content XML. Therefore a raw-fragment merge promise is unsupported by the accepted artifact.

The extension API will publish immutable validated tree data ahead of save, with private adapters constructing it using original SimpleXML operations. Load copies XML before returning and delivers immutable data outside the Core lock. A reserved extension subtree is a candidate boundary, not yet an accepted replacement for every mutable-listener capability. Before this point is executable, classify original externally useful XML operations and specify supported names, attributes, leaf data, duplicate/version rules, cursor restoration, initial-load timing and limits. Any omitted capability remains an explicit gap; read-only notices alone cannot close the mutable-extension requirement. Low-level setting-file helpers retain their original backup/recovery Boolean and diagnostics rather than pretending SettingsManager.save supplies a success result.

Tests cover every compiled key's catalog/type/default readability; safe representative mutation for each type; exact 64-bit values/range rejection; force/default XML behavior; primary/backup/missing/malformed files and event order; profile conflict/reset; history; per-key callback sequencing/error forwarding; HubSettings copying only defined values. Platform-unavailable keys reject with explicit reasons.

Formatter correction from exact source inspection: SettingItem.cpp:75–80 passes the integer **value**, not its stored setting key, to getEnumStrings, then indexes the returned map with that value. This contradicts the earlier key-based formatter assumption. Bridge display methods must call the original formatter and preserve its actual result; direct option enumeration remains the separate original getEnumStrings(key, validateCurrentValue) API. No silent Core bug fix is part of this project. ProfileSettingItem.setProfileToDefault supports string/int/bool by exact boost variant type; a mismatched variant inside its noexcept method can terminate. Validate custom profile items before invoking it; Int64 is not supported by that original model. The three compiled profile definitions use supported bool/int values.

The original SettingItem.getDefaultValue also calls current/effective get for integer and Boolean keys, while strings use getDefault. Preserve that model helper separately from ADCSettingSnapshot.defaultValue, which delegates to the actual SettingsManager typed getDefault methods. Do not silently normalize these different original APIs into the same result.

## Identity and certificates

Phase 3 owns CID/identity value models and persistent favorite-user identity. Copy all supported Core fields and flag semantics; preserve HintedUser equality's deliberate omission of the hub hint and process-independent snapshot lifetime. Live per-hub user indexing, NMDC registry/online transitions and transport events belong to Phase 4.

Source validation anchors: CID::SIZE is 192/8 (24 bytes), yielding 39 Base32 characters. Original Encoder accepts upper/lowercase letters and digits 2–7; encoding produces uppercase. Do not assume a 160-bit CID or reject lowercase that Core recognizes. The permissive decoder skips unrecognized characters and truncates after its destination fills; a typed public CID constructor must define strict validated logical-value input separately from any intentionally exposed permissive decoding operation. Binary payload construction requires exactly 24 copied bytes. Equality/order/hash delegate to the original CID; no raw pointer is exported.

Expose copied certificate/keyprint/TLS state and original generate/load/check operations, lock-to-key/extended-lock semantics where publicly useful. Keep SSL_CTX/OpenSSL pointers and private key bytes private. Do not interpret TLSOk as proving a connection's trust, and do not waive pin mismatch through allowUntrusted.

Tests use controlled missing/invalid/expired certificate resources and verify copied nonempty keyprints, exact generated certificate properties, safe identity encoding/validation and post-stop snapshot lifetime. Network SSLSocket trust/pin behavior needs controlled peer tests in its connection phase; preserve that gap instead of claiming certificate metadata proves it.

## Logs

Preserve CHAT/PM/DOWNLOAD/UPLOAD/SYSTEM/STATUS areas; Core path/template formatting; append versus overwrite; asynchronous writes; CID-grouped private paths/cache; exact BOM/CRLF/bare-LF/trailing-delimiter/max-lines tail semantics; read/clear transition events and NOTIFY/INFO differences. Do not invent a synchronous flush/completion guarantee that Core lacks.

Tests use isolated paths and original executor barriers or observable file completion. Copy cached LogMessage payloads before returning and cover read/clear notifications, event ordering and unsubscribe/lifetime barriers.

## Favorites and reserved slots

Expose all favorite hub entry fields and inherited HubSettings; groups/directories; add/update/remove/find/order/duplicate semantics; XML persistence and dirty/no-op behavior; favorite CID/nick/hub/last-seen/description/flags; grantslot/superuser metadata and reservation duration/expiry. Favorite auto-connect policy can be configured/read here, but live connection execution depends on Phase 4.

Tests cover case-insensitive duplicate servers, missing tokens, exact mutation/event order, group→entry settings merge, XML round trips, CID/self/duplicate rules, value lifetime, second→millisecond reservation conversion and expiry callbacks after Core unlock. Some upstream favorite-field mutations use read locks; do not claim the bridge serial queue repairs Core's internal locking.

## Scope and evidence limits

The original source and accepted distribution remain authoritative. New artifact requirements or unsupported platform substitutions must be explicit decisions, not hidden bridge algorithms. GeoIP/provider/trust resources and optional modules remain named prerequisite gaps where outside this phase. Gates require real Core behavior and errors, not copied declarations or successful packaging alone.
