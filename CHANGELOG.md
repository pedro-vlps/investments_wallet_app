# Changelog

## v0.7.0 - 2026-10-20

- Authenticate optional brapi quote requests using a per-device API key in the Authorization header.
- Store quote credentials in operating-system secure storage, separately from portfolio backups and application source.
- Add masked quote-key configuration, replacement and removal from portfolio views.
- Distinguish invalid/missing authentication from plan restrictions while preserving saved portfolio data on failures.

## v0.6.1 - 2026-10-20

- Import B3 Movimentação Transferência - Liquidação credits as purchases and debits as sales instead of silently ignoring them.
- Recognize explicit FII/ETF product descriptions and preserve the original movement label and settlement date basis in database schema v5.
- Reject mixed negotiation/settlement histories for the same asset and broker to prevent duplicate holdings without guessing trade dates.
- Identify settlement records in upload review, report management, price captions and auxiliary fiscal exports.
- Validate the importer against an actual developer-supplied B3 XLSX without including personal financial data in the repository.

## v0.6.0 - 2026-10-19

- Add an Income Tax workspace before Reports with monthly assisted assessments, hypothetical planning, and seasonal auxiliary annual reports.
- Persist reviewed monthly net results, opening tax losses, IRRF credits, and manually recorded DARF principal payments in the local backup database.
- Separate common, day-trade, and FII tax groups, apply the eligible stock-sales exemption, and carry subminimum DARF amounts without treating missing months as zero.
- Monitor eight official Receita Federal sources with six-month full checks, manual refresh, offline/change warnings, and more frequent filing-deadline checks during preparation season.
- Export local HTML reconciliation reports for closed years during the annual preparation window; distinguish these files from complete declarations, PGD imports, and official transmissions.
- Document unsupported automatic fiscal inputs, source-withheld products, income-specific rules, and the need for reviewed application updates when legislation changes.

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
