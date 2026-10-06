# 0001 — Framework boundary and SPM distribution

Date: 2026-10-06. Status: approved project direction; feasibility verification pending.

## Context

Igualada needs the full original Core functionality through Swift-compatible Objective-C APIs. Project 1 already supplies an ARM64 aggregate static archive and associated headers/provenance. The bridge must hide C++ implementation details and provide a simple SPM dependency.

## Decision

Use an Objective-C framework with private Objective-C++ adapters. Link Core into a dynamic AirDCObjC framework, package it as an XCFramework, and expose it through SPM. Build a native Swift/SwiftUI/AppKit example app in the same workspace, with a package-consumption validation mode.

## Alternatives

A static framework can also be distributed in an XCFramework, but requires explicit containment/aggregation and careful final-link ownership. A source SPM bridge could improve source debugging but introduces a different developer dependency/build boundary. Neither alternative is selected for the initial proof.

## Consequences

The app receives one public module and must not link another Core copy. Public headers hide C++. The framework needs an explicit embedding/signing/resource contract. Its dynamic-link containment, exports and system-library closure must be proven before expanding the API.

The existing Core archive is a baseline, not a reason to exclude disabled capabilities. Full parity requires a coverage ledger and separately approved Project 1 work when necessary.

If dynamic containment fails, stop and present evidence and a focused decision amendment. Do not silently switch to a different packaging model.
