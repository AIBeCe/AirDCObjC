# Core functional coverage

## Requirement and authority

ALL original Core functionality is the goal. The original repository at commit `55d51ceb817ec006d4ec844d9e3788e1b0ccc352` is the behavioral authority. Scope is functional parity, not a mechanical Objective-C translation of every C++ helper or dependency header.

A platform-specific implementation does not automatically justify removing its capability. Record an equivalent implementation proposal or a user-approved resolution. Disabled upstream features are explicit gaps; their completion can require separate Core project work.

## Discovery baseline

[Header inventory](core-header-inventory.csv) lists all 263 `.h` files under the pinned `airdcpp` source tree, their SHA-256, directory domain hint, and installed-header presence. Of these, 245 are installed under the inspected distribution's `include/airdcpp`; all 245 have matching source bytes. The 18 absent headers are 17 optional-module headers and `core/io/compress/ZipFile.h`.

A header's presence is not proof of an exported operation, compiled implementation, or working feature. A directory hint is not a reviewed classification. Every row intentionally starts unclassified with operation inventory pending; no framework implementation or test is claimed.

Do not count this file as complete method-level coverage. Phase 0 expands it using source/API/event/settings inspection, effective build configuration, and symbols/behavior before the relevant implementation point.

## Functional domains and source anchors

Paths below are relative to the original Core's `airdcpp` directory. Each family includes its related models, child APIs and listener interfaces; the manager name alone is not the complete domain.

| Capability family | Source anchors | Initial coverage status |
|---|---|---|
| Lifecycle, startup hooks and teardown | `DCPlusPlus.h`, `core/` | Not implemented |
| Settings/defaults/persistence | `settings/SettingsManager.h` | Not implemented |
| Logs and diagnostics | `events/LogManager.h` | Not implemented |
| Crypto, certificates and TLS integration | `core/crypto/CryptoManager.h` | Not implemented |
| GeoIP and geographic information | `core/geo/GeoManager.h` | Not implemented; runtime data requirements to inspect |
| Connections and throttling | `connection/ConnectionManager.h`, `connection/ThrottleManager.h` | Not implemented |
| Connectivity, active/passive modes and mapping | `connectivity/ConnectivityManager.h`, `connectivity/MappingManager.h` | Not implemented; NAT-PMP gap |
| Hub clients, users, identities and hub messages | `hub/ClientManager.h`, `hub/`, `user/`, `message/` | Not implemented |
| Protocol commands | `protocol/ProtocolCommandManager.h`, `protocol/` | Not implemented |
| Search, instances and results | `search/SearchManager.h`, `search/` | Not implemented |
| Private chat | `private_chat/PrivateChatManager.h` | Not implemented |
| Queue items, bundles, priorities and sources | `queue/QueueManager.h`, `queue/` | Not implemented |
| Downloads | `transfer/download/DownloadManager.h` | Not implemented |
| Uploads, slots and transfer limits | `transfer/upload/UploadManager.h` | Not implemented |
| Transfer information and events | `transfer/TransferInfoManager.h` | Not implemented |
| File lists and directory browsing | `filelist/DirectoryListingManager.h`, `filelist/` | Not implemented |
| Hashing, trees and hash database | `hash/HashManager.h`, `hash/` | Not implemented |
| Shares, refresh and indexes | `share/ShareManager.h` | Not implemented |
| Share profiles and temporary shares | `share/profiles/ShareProfileManager.h`, `share/temp_share/TempShareManager.h` | Not implemented |
| Favorites, favorite users and reserved slots | `favorites/FavoriteManager.h`, `favorites/FavoriteUserManager.h`, `favorites/ReservedSlotManager.h` | Not implemented |
| Ignore rules and recent state | `user/ignore/IgnoreManager.h`, `recents/RecentManager.h` | Not implemented |
| Viewed files | `viewed_files/ViewFileManager.h` | Not implemented |
| User commands and activity | `hub/user_command/UserCommandManager.h`, `hub/activity/ActivityManager.h` | Not implemented |
| Automatic/ADL/direct/listing search | `modules/AutoSearchManager.h`, `modules/ADLSearch.h`, `modules/DirectSearch.h`, `modules/DirectoryListingSearch.h` | Optional-module gap |
| Finished transfer history | `modules/FinishedManager.h` | Optional-module gap |
| Highlighting | `modules/HighlightManager.h`, `modules/ColorSettings.h` | Optional-module gap |
| Hub lists | `modules/HublistManager.h` | Optional-module gap |
| Preview application integration | `modules/PreviewAppManager.h` | Optional-module gap |
| RSS | `modules/RSSManager.h` | Optional-module gap |
| Update-related functionality | `core/update/` | Updater implementation omitted on macOS; precise capability resolution required |
| Utilities and platform facilities | `util/`, remaining `core/` headers | Classification required; ZIP/Windows mapper availability needs capability review |

## Operation ledger schema

Each expanded row must record:

- Stable capability/operation/event/setting ID and owning domain.
- Exact upstream symbol, file/line and pinned source identity.
- Classification: public functionality, event, setting, internal helper, dependency detail, or platform-specific implementation, with rationale.
- Availability: source, installed declaration, effective build flags, linked implementation and runtime prerequisites.
- Core behavior: inputs, defaults, side effects, errors, completion and cancellation.
- Objective-C API and Swift-imported surface, linking to the approved proposal.
- Ownership/threading/event ordering and persistence/resource requirements.
- Automated tests, real Core evidence and example scenario.
- Status: inventoried, proposed, approved, implemented, verified, or blocked.
- Gap resolution, decision owner and any explicit user-approved scope decision.

Do not use blank rows, an umbrella manager wrapper, or a successful demo connection as evidence of full coverage.

## Parity gates

1. Classify every source header and explain source/distribution differences.
2. Enumerate and review every externally meaningful operation, setting, event and optional capability.
3. Map each row to approved bridge API, tests and example exercise.
4. Verify behavior against real Core, including failure and cancellation paths.
5. Resolve every functional gap explicitly. Never count a disabled feature as implemented.
6. Review cross-domain workflows and upstream diff at final acceptance.

Snapshot/command/event representations may differ from C++ signatures, but their capabilities and meanings must not be lost. API availability and runtime verification are separate evidence fields.
