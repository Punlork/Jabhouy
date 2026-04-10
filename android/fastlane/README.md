fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android test

```sh
[bundle exec] fastlane android test
```

Run Flutter tests and build debug APK

### android build_dev

```sh
[bundle exec] fastlane android build_dev
```

Build development debug APK

### android build_dev_release

```sh
[bundle exec] fastlane android build_dev_release
```

Build development release APKs split per ABI

### android build_staging

```sh
[bundle exec] fastlane android build_staging
```

Build staging release APK (for internal testing)

### android build_release

```sh
[bundle exec] fastlane android build_release
```

Build production release APK

### android build_release_ci

```sh
[bundle exec] fastlane android build_release_ci
```

Build production release APK for CI/GitHub Releases

### android distribute_dev

```sh
[bundle exec] fastlane android distribute_dev
```

Distribute development arm64-v8a release APK to Firebase App Distribution

### android internal

```sh
[bundle exec] fastlane android internal
```

Deploy to internal testing track (Google Play)

### android beta

```sh
[bundle exec] fastlane android beta
```

Deploy to beta track (Google Play)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
