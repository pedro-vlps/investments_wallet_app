# Local Wallet

An offline-first Flutter desktop portfolio for Windows, macOS, and Linux.
The first iteration uses a fictional B3 portfolio, real quote snapshots, an
optional manual quote refresh, and a dark interface. No app account or server is required.

## Run

Install the stable Flutter SDK and the build tools required by your target OS.
This iteration was developed with Flutter 3.47.7 and Dart 3.13.5.
Run `flutter doctor` to check the environment, then:

```sh
flutter pub get
flutter run -d windows
# On macOS: flutter run -d macos
# On Linux: flutter run -d linux
```

Build on each target OS with `flutter build windows`, `flutter build macos`, or
`flutter build linux`. The macOS build requires macOS and Xcode. The Windows
build requires Visual Studio with the Desktop development with C++ workload.
The application is desktop-only for now; mobile platform projects are not generated.

For Windows development, double-click `run-dev.cmd` in the project root, or run
this single command in PowerShell:

```powershell
.\run-dev.cmd
```

The launcher prepares dependencies and starts the Windows app in debug mode.
It uses `.tools/flutter` and a project-local package cache when the workspace SDK
is available; otherwise it uses Flutter from PATH. It works regardless of the
terminal's current directory. Keep its terminal open while developing: press `r`
for hot reload, `R` for a hot restart, or `q` to stop the app. The window pauses
after exit so dependency and build errors remain readable. The launcher requires
the Windows build tools described above and may use the network for dependencies.

For normal use without a development terminal, open
`build/windows/x64/runner/Release/investments_wallet.exe` directly, or create a
Windows shortcut to it. Keep the executable alongside its DLLs and data folder.
This runs the last release build; code changes require a new build or the
development launcher.

If using the workspace SDK on Windows manually:

```powershell
$env:PUB_CACHE = Join-Path (Get-Location) '.tools/pub-cache'
& .\.tools\flutter\bin\flutter.bat pub get
& .\.tools\flutter\bin\flutter.bat run -d windows
```

## Offline data and prices

On first launch, the bundled `assets/demo_portfolio.json` is seeded once into
`portfolio.sqlite3` inside the OS application support directory provided by
`path_provider`. Later launches read this database without network requests.
SQLite is bundled with the application by the `sqlite3` package's native build hook.
The SDK/dependency download is a development/build requirement, not a runtime requirement.

The sample contains PETR4, VALE3, and ITUB4. Holdings and cost bases are fictional;
BRL prices and market timestamps are snapshots returned by brapi and retain their
source URLs in the bundled JSON. The interface identifies seed prices as initial
snapshots. Times are displayed in the device's local timezone.

The manual refresh requests the [brapi v2 quote endpoint](https://brapi.dev/docs)
once per symbol, using the publicly accessible demonstration symbols without a key.
Provider availability, timestamps, public access, and quotas may change. Prices
are not guaranteed to be real time. No credentials are embedded in the application.
The provider receives the requested tickers, not quantities or acquisition costs.
The application makes no automatic quote requests at startup.

All responses must be valid before an atomic SQLite update. Older quotes never
replace newer saved quotes. Network/provider failures retain existing saved data.
Money is stored and calculated in integer BRL cents; the HTTP boundary rounds
quotes to cents. Quantities are positive whole shares in this first iteration.
Results are unrealized price differences, excluding fees, taxes, and dividends.

Data is not encrypted and is stored under the current operating system user.
Uninstall/reinstall recovery, backups, real portfolio editing, and brokerage note
import are future work. Data must not be assumed recoverable after app deletion.

## Context boundaries and technology changes

- `lib/portfolio/domain`: positions, totals, and the repository contract; pure Dart.
- `lib/portfolio/data`: SQLite schema, one-time seeding, and atomic persistence.
- `lib/portfolio/presentation`: the portfolio controller and responsive widgets.
- `lib/quotes/domain`: provider contract and quote values; pure Dart.
- `lib/quotes/data`: validated brapi HTTP integration.
- `lib/app`: composition, application lifecycle, and the dark theme.

SQLite operations run in worker isolates. Connections are scoped to operations;
the HTTP client and UI controllers are released with the application widgets.
There is no mandatory backend. The standard SQLite schema and JSON seed can be
reused after a technology change. Changing the quote source requires implementing
`QuoteProvider`. Replacing Flutter with another language still requires rewriting
the interface and porting Dart rules; this design reduces coupling, not migration cost to zero.

## Verification

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests cover exact monetary totals, persistence after reopening, seed idempotency,
atomic rollback, stale quotes, offline refresh, duplicate refresh prevention,
provider response validation, and desktop/narrow layouts.

Validated on Windows on 2026-10-18: all 15 tests passed, static analysis and
formatting checks passed, and `flutter build windows --release --no-pub`
produced `build/windows/x64/runner/Release/investments_wallet.exe`.
Distribute the entire Release directory, including its DLLs and data folder,
rather than the executable alone. Build output is excluded from source control.
macOS and Linux builds require their respective host environments and have not
been executed here.

The theme is centralized in `lib/app/wallet_theme.dart`; the initial theme mode
is dark. A user-facing theme switch can be added later without changing portfolio
rules or storage.
