# Changelog

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
