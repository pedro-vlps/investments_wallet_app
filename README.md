# Local Wallet

An offline-first Flutter desktop portfolio for Windows, macOS, and Linux.
The application imports B3 negotiation and movement reports, starts with an empty
portfolio, and offers optional quote refresh in a dark interface.
No app account or server is required.

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
returns are red, and exact zero uses the default text color. Only quote prices
are fetched from brapi; dividend data is not downloaded automatically.

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

When adding or updating native plugins (such as the report file selector), stop
the current `flutter run` session with `q` and start `run-dev.cmd` again. Hot
reload (`r`) and hot restart (`R`) do not rebuild or register new native plugins.
An unavailable file selector displays restart instructions rather than claiming
that an unselected file could not be read. Canceling the dialog is not an error.

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

Dividend events and monthly portfolio valuations are not created automatically.
Historical values are not fetched from brapi or reconstructed from today's price.
Six decimal places are retained for per-share amounts using integer micro-reais;
cash totals remain integer cents.

Schema version 3 migrates versions 1 and 2 transactionally, preserves existing
amounts and payment dates, and leaves unavailable entitlement/per-share fields
unknown when the original records do not contain those details.
Reopening does not duplicate payments. Portfolio totals consume the same received
balances through the dividends persistence adapter's public contract.

## Offline portfolio data and prices

On first launch, an empty `portfolio.sqlite3` is created inside `InvestmentsWallet`
in the user's Documents directory
provided by `path_provider`. Later launches reuse this directory and database
without network requests. The exact path is shown on both report screens.
SQLite is bundled with the application by the `sqlite3` package's native build hook.
The SDK/dependency download is a development/build requirement, not a runtime requirement.

No sample holdings, quote snapshots, or payments are bundled with the application.
Positions are populated by report imports. Times are displayed in the device's
local timezone.

The manual refresh requests the [brapi v2 quote endpoint](https://brapi.dev/docs)
once per symbol, using the publicly accessible demonstration symbols without a key.
Provider availability, timestamps, public access, and quotas may change. Prices
are not guaranteed to be real time. No credentials are embedded in the application.
The provider receives the requested tickers, not quantities or acquisition costs.
The application makes no automatic quote requests at startup.

All responses must be valid before an atomic SQLite update. Older quotes never
replace newer saved quotes. Network/provider failures retain existing saved data.
Money is stored and calculated in integer BRL cents; the HTTP boundary rounds
quotes to cents. Imported quantities use integer millionths, allowing fractional
Tesouro Direto holdings; listed shares and fund units must be whole units.
Price-only results are unrealized price differences excluding dividends;
cumulative results include the received cash dividends. Both exclude fees and taxes.

Dividend schema migrations do not replace existing holdings or saved quotes.

Data is not encrypted and is stored under the current operating system user.
Close the application and back up the entire `Documents/InvestmentsWallet` folder,
including `portfolio.sqlite3` and `reports/`. Restore that folder to Documents
before opening the app on a new computer or after reinstalling. Original report
paths in SQLite are relative, so the folder can move across computers and OSes.
Do not merge folders from different installations; restore a complete snapshot.
Application deletion is separate from this user-owned Documents folder, but
deleting the folder itself still deletes the local data. OS cleanup tools and
Documents synchronization remain outside the application's control.

If no new database exists, an existing database from the previous application
support directory is copied with SQLite `VACUUM INTO` and checked before use.
The legacy file remains untouched. An existing restored database takes priority
and is never replaced by the legacy copy. Schema version 4 adds reports and
imports without replacing existing positions, quotes, or dividend history.

The macOS desktop target runs outside App Sandbox so Documents remains a
user-owned backup folder rather than an application container. This configuration
targets direct desktop distribution; a future Mac App Store release will require
a sandbox-compatible user-selected folder and security-scoped access. macOS
native packaging and filesystem access still require verification on macOS.

## B3 reports

The Reports navigation item expands two submenu entries: Manage reports and Add
reports. Add reports opens the native local file picker and a review screen.
Manage reports lists imported files with expandable asset purchase/sale quantities,
duplicate counts, ignored-line reasons, and relative original-file paths.
The submenu also works as labeled tooltips when the sidebar is collapsed.

Supported inputs are B3 Investor Area **Negociação** and **Movimentação** XLSX
exports and CSV files with those column names. PDF, legacy XLS, brokerage notes,
position snapshots, corporate actions, transfers, and imported dividends are not
supported yet. Only explicit purchases and sales affect positions. Settlement
entries are ignored to avoid counting negotiation trades twice. Stocks, FIIs,
ETFs, BDRs, and Tesouro Direto are supported. Options, futures, and other products
are excluded with reasons shown in the review.

BDRs are classified automatically using suffixes 31 through 40 from the
[B3 trading manual](https://sistemasweb.b3.com.br/normativos/MPODENEGOCIACAO20260525.pdf).
Alphanumeric roots such as A1MD34 are accepted. Fractional-market suffix `F` is
normalized to the standard code. ETF-backed BDRs such as BIVB39 are recorded as
BDRs rather than domestic ETFs. Quantity, acquisition cost, purchases, sales,
broker attribution, and duplicate detection follow the existing import contracts.

Each imported trade records its institution/broker and asset class. Broker
balances and acquisition cost are maintained separately, then aggregated by asset
for the existing portfolio tables. An incomplete history with sales exceeding
available holdings is rejected atomically. Final `11` tickers require the user to
choose stock/unit, FII, ETF, or ignore when the file supplies no classification.
Imported cost excludes brokerage fees and taxes. Full daily exports are needed
to distinguish repeated identical fills consistently across overlapping files.

After the first successful import, portfolio views use only imported holdings;
older portfolio and dividend records are preserved in SQLite but hidden. Imported dividends and historical
return charts will need their own implementation. New positions initially show
the last transaction price and its date, explicitly labeled as a transaction
price. Quote refresh remains manual and available only for listed securities;
Tesouro Direto keeps its last transaction price. Provider access may restrict
non-demonstration tickers without a configured API subscription.

The original file is stored by SHA-256 under `reports/`. Import records, normalized
trades, and report membership are saved transactionally. Reimporting the same file
is rejected; overlapping content is deduplicated while preserving repeated identical
rows within a report. Processing and persistence run in worker isolates.

Import layouts were researched using [B3 instructional material](https://www.b3.com.br/data/files/15/64/1A/AD/CDD8F710C3D7B7F7AC094EA8/Material_IR22_Area_logada_v4.pdf)
and public anonymized structural examples. Synthetic upload examples and their
generator have been removed from the project. No authenticated current investor
export was available for validation.

## Context boundaries and technology changes

- `lib/portfolio/domain`: positions, totals, and the repository contract; pure Dart.
- `lib/portfolio/data`: SQLite schema migrations, imported holdings, dividends, and atomic persistence.
- `lib/portfolio/presentation`: the portfolio controller and responsive widgets.
- `lib/quotes/domain`: provider contract and quote values; pure Dart.
- `lib/quotes/data`: validated brapi HTTP integration.
- `lib/dividends/domain`: payment contracts, periods, pagination, monthly cash, and historical returns.
- `lib/dividends/data`: dividend migrations, received balance reads, and local historical valuation reads.
- `lib/dividends/presentation`: independent filters, paginated events, cash bars, and width-constrained return lines.
- `lib/financial_display`: shared BRL and percentage formatting for portfolio and dividends.
- `lib/reports/domain`: parsed trades, report contracts, classification, and broker-specific holding projection.
- `lib/reports/data`: B3 XLSX/CSV parsing, report schema, local archive, and transactional imports.
- `lib/reports/presentation`: upload/review, classifications, report list, and backup instructions.
- `lib/app_storage`: portable data directory preparation and legacy database migration.
- `lib/app`: composition, application lifecycle, and the dark theme.

SQLite operations run in worker isolates. Connections are scoped to operations;
the HTTP client and UI controllers are released with the application widgets.
There is no mandatory backend. The standard SQLite schema can be
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
