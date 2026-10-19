# Local Wallet

An offline-first Flutter desktop portfolio for Windows, macOS, and Linux.
The application uses a fictional B3 portfolio, real quote snapshots, an optional
manual quote refresh, and a dark interface. No app account or server is required.

## Portfolio views

The left navigation switches between the summary and detailed portfolio tables.
Use the menu button to collapse or expand the sidebar; narrow windows use the
compact icon menu automatically. Both views share the same positions and quotes.
Click any column heading to sort ascending, and click again to reverse the order.
Sorting uses underlying numeric values and timestamps, not formatted text.
The horizontal scrollbar exposes additional columns in narrow windows.

The detailed view adds invested capital, portfolio weight, received dividends,
and cumulative gains in BRL and percent. Each attribute, including company,
quote source, and quote time, has its own sortable column.

- Portfolio weight = asset market value / total portfolio market value.
- Price return = (market value - acquisition cost) / acquisition cost.
- Cumulative return = (market value - acquisition cost + received dividends) / acquisition cost.

Returns are simple, non-annualized, and exclude taxes and fees; dividends are not
automatically reinvested or compounded. Positive returns are green, negative
returns are red, and exact zero uses the default text color. Dividends are
fictional total cash payments for these example holdings, not real company
dividend data or per-share amounts. Only quote prices are fetched from brapi.

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

## Dividend workspace

The Dividendos navigation item opens three independently filtered sections:

- Received dividends: paid cash grouped by ticker on the left and monthly cash bars on the right.
- Total dividends: two cumulative portfolio return lines, with and without received dividends, fitted to the available screen width without horizontal scrolling or cash columns.
- All dividends: received and provisioned totals plus a table with at most ten rows per page, including ticker, status, kind, per-share amount, eligible quantity, total, cum date, ex date, and payment date.

Every section starts at inception. The received section and table offer rolling
1-, 3-, 6-, and 12-month windows; the total chart also offers 24 and 60 months.
Rolling windows end today and clamp the starting day to the target month's last
day when needed. Monthly bars can therefore contain partial first/last months.
Empty months are retained with zero cash. The table filters by payment date;
inception includes known future provisions, while other windows end today.
Changing the table filter resets pagination. Filters survive navigation between views.

Provisioned payments are never counted as received, and an elapsed payment date
does not automatically mark an unconfirmed provision as received. The historical
lines use recorded monthly market values and acquisition costs, with all received
cash up to each valuation date for the dividend-inclusive line. Selecting a
window displays that part of the inception-based return series; it does not
rebase the returns. Missing valuations break the lines rather than invent prices.
The received-dividend chart uses a BRL axis and retains horizontal scrolling for
long histories. The total-dividends chart uses only a percentage axis and scales
all monthly observations to its container width. Date labels become sparser for
long periods or narrow windows; the underlying monthly points are retained.
Bars and lines have mouse/touch tooltips. Charts have semantic
text equivalents. None of these screens makes internet requests.

All dividend events, entitlement dates, provisions, and monthly portfolio
valuations are fictional demonstration data. Historical values are not fetched
from brapi or reconstructed from today's price. Six decimal places are retained
for per-share amounts using integer micro-reais; cash totals remain integer cents.
JCP amounts in the demo are not tax calculations.

Schema version 3 migrates versions 1 and 2 transactionally, preserves existing
amounts and payment dates, and leaves unavailable entitlement/per-share fields
unknown for non-demo records. Fixture details are only applied to matching demo
records; sample portfolio valuations require the complete original demo holdings.
Reopening does not duplicate payments. Portfolio totals consume the same received
balances through the dividends persistence adapter's public contract.

## Offline portfolio data and prices

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
Price-only results are unrealized price differences excluding dividends;
cumulative results include the received cash dividends. Both exclude fees and taxes.

Dividend schema migrations do not replace existing holdings or saved quotes.

Data is not encrypted and is stored under the current operating system user.
Uninstall/reinstall recovery, backups, real portfolio editing, and brokerage note
import are future work. Data must not be assumed recoverable after app deletion.

## Context boundaries and technology changes

- `lib/portfolio/domain`: positions, totals, and the repository contract; pure Dart.
- `lib/portfolio/data`: SQLite schema migrations, one-time seeding, dividends, and atomic persistence.
- `lib/portfolio/presentation`: the portfolio controller and responsive widgets.
- `lib/quotes/domain`: provider contract and quote values; pure Dart.
- `lib/quotes/data`: validated brapi HTTP integration.
- `lib/dividends/domain`: payment contracts, periods, pagination, monthly cash, and historical returns.
- `lib/dividends/data`: dividend migrations, received balance reads, and local historical valuation reads.
- `lib/dividends/presentation`: independent filters, paginated events, cash bars, and width-constrained return lines.
- `lib/financial_display`: shared BRL and percentage formatting for portfolio and dividends.
- `lib/app`: composition, application lifecycle, and the dark theme.

SQLite operations run in worker isolates. Connections are scoped to operations;
the HTTP client and UI controllers are released with the application widgets.
There is no mandatory backend. The standard SQLite schema and JSON seed can be
reused after a technology change. Changing the quote source requires implementing
`QuoteProvider`. Replacing Flutter with another language still requires rewriting
the interface and porting Dart rules; this design reduces coupling, not migration cost to zero.

## Verification

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter build windows --release
```

Project test sources, the native macOS test target, synthetic examples, and
temporary verification artifacts were removed at the developer's request.
There is currently no automated test suite in this checkout. Verification uses
Dart formatting, static analysis, and a Windows build; runtime behavior is not
covered by automated regression tests.
Distribute the entire Release directory, including its DLLs and data folder,
rather than the executable alone. Build output is excluded from source control.
macOS and Linux builds require their respective host environments and have not
been executed here.

The theme is centralized in `lib/app/wallet_theme.dart`; the initial theme mode
is dark. A user-facing theme switch can be added later without changing portfolio
rules or storage.
