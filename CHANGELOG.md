# Changelog

## v0.5.0 - 2026-10-18

- Remove the portfolio tagline, local-storage badges, and quote/return footnotes from both portfolio views.
- Remove explanatory text below the dividend return chart and above the dividend payment table, preserving the charts, calculations, and filters.

## v0.4.0 - 2026-10-18

- Add an expandable Reports submenu with local XLSX/CSV upload, classification review, and report management.
- Import B3 negotiation and movement purchases and sales for stocks, FIIs, ETFs, BDRs, and Tesouro Direto, excluding derivatives and unsupported events with visible reasons.
- Classify BDR trading codes automatically, including alphanumeric roots, ETF-backed receipts, and fractional-market code normalization.
- Preserve broker attribution, fractional treasury quantities, original files, and duplicate-safe imports across overlapping periods.
- Store the database and reports in a portable Documents/InvestmentsWallet folder and migrate the previous support database without overwriting restored data.
- Build imported holdings from recorded trades and retain transaction prices until an optional quote refresh.
- Distinguish native file-selector startup failures from file-read errors and explain when a full development restart is required.
- Remove bundled demo data, automatic sample seeding, and demonstration notices so new installations start with an empty portfolio.

## v0.3.0 - 2026-10-18

- Add a Dividendos workspace with independent received, total-history, and payment-table period filters.
- Add monthly dividend bars and historical portfolio return lines with and without received dividends.
- Fit the total-dividends chart to the available width with two return lines and adaptive date labels.
- Add ten-row pagination, received/provisioned totals, per-share precision, entitlement dates, and dividend/JCP types.
- Migrate local dividend records without losing prior amounts and add clearly identified fictional history and provisions.

## v0.2.0 - 2026-10-18

- Add collapsible navigation between summary and detailed portfolio views.
- Add sortable asset attributes, portfolio weights, and returns including received dividends.
- Persist fictional demo dividend payments with an idempotent SQLite migration.
- Show positive returns in green, negative returns in red, and zero returns in the default text color.

## v0.1.0 - 2026-10-17

- Add a dark Flutter desktop portfolio with fictional B3 holdings and real quote snapshots.
- Persist positions and quotes locally with SQLite and seed the demo once.
- Add manual brapi quote synchronization with validation and offline error handling.
- Separate portfolio rules, quote providers, persistence, and presentation.
