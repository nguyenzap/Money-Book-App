# MoneyBook Auto-Tracking: Development Plan (v6)

**Goal:** Add automatic transaction logging to MoneyBook (`nguyenzap/Money-Book-App`). It reads payment notifications from **the supported apps I turn on** (BIDV and Eximbank; MoMo is out of scope, see D15), parses them with **parsers I write and maintain in the source code**, creates transactions through the app's existing repository, and sorts them into categories **on the phone, by learning which receiver belongs to which category** from the entries I categorize myself.

**What changed from v1:** MoneyBook is a **Flutter / Dart** app (Drift + Riverpod), not native Kotlin. The only Kotlin file is `MainActivity.kt`. So:
- **Kotlin** is used only for the notification listener service, which Flutter can't provide.
- Everything else (parsing, matching, categorizing, UI) is **Dart**, following the app's conventions and its existing test suite.
- **Budget vs. actual and income are already built** (budgets, stats, free money, funds), so those phases are gone. The work is only the auto-tracking pipeline.

**What changed from v2 → v3:** apps to track became a user choice, and notifications were matched against user-written format templates.

**What changed from v3 → v4:**
- **Categorization runs entirely on the phone.** The cloud LLM option is gone, so the app still needs no `INTERNET` permission.
- A **receiver → category mapping** learned from my own categorizations does the labeling, helped by an editable keyword list (e.g. `CAFE`, `COFFEE` → "Ăn uống").
- First-time receivers land in **"Chưa phân loại"** and show up in a dedicated list, grouped by receiver. Categorizing one entry there creates the mapping and fills in the rest of that group. The mapping and keywords are editable in settings.

**What changed from v4 → v5:**
- **The in-app format editor is gone.** Each supported app has a **parser in the source code** (`lib/core/domain/autotrack/parsers/`), backed by real notification samples as test fixtures. When a bank changes its wording, I fix the parser, add the sample, and ship a new build (D10).
- **Choosing apps** now means turning supported apps on or off and mapping them to wallets. A separate **sample capture** mode records raw notifications from any app so I can write a parser for a new bank.
- Notifications a parser doesn't recognize are kept longer (30 days), and **re-parsed automatically after an update**, so nothing is lost while a fix is on its way.

**What changed from v5 → v6:** BIDV and Eximbank formats are now known from real samples (section 4a). **MoMo is dropped** (D15); transfer matching now pairs BIDV ↔ Eximbank.

**Device:** Xiaomi 17T, HyperOS 3. **Effort:** roughly 5–6 days over 2–3 weekends, plus about a week of collecting notification samples.

---

## 1. Rules from the repo that the feature must follow (`CLAUDE.md`)

| Rule | What it means for auto-tracking |
|---|---|
| Money is `int` VND; `amount` is always positive; the sign comes from `TxKind` | Parsers output an **unsigned amount and a direction**, then direction maps to `TxKind.expense` / `TxKind.income`. |
| One formula for wallet balances, based on `walletFromId` / `walletToId` | Expense → `walletFromId` = the mapped wallet. Income → `walletToId`. Never touch balances directly. |
| `tx_kind.dart` is the single source of truth | No new `TxKind`. Auto-logged entries are ordinary transactions plus metadata. |
| All queries live in `repository.dart` | All inserts go through `Repository.addTransaction(...)`. No SQL from the service or the UI. |
| `day_key` / `month_key` are computed in Dart, in local time | Use the transaction time printed in the notification (local time), falling back to `postTime` → `DateTime` (local) → `addTransaction` computes the keys itself. |
| Stats count only `income` / `expense` | Moving money between my own BIDV and Eximbank accounts becomes **one `TxKind.transfer`**, so it's automatically excluded from spending. |
| Editing `tables.dart` means running `build_runner`; migrations use the `if (from < n)` chain | Schema **v5 → v6**, plus a case in `migration_test.dart`. |
| The app is offline: no server, no account | Categorization is a deterministic Dart algorithm on the phone (D5). No `INTERNET` permission, nothing leaves the device. |
| A category belongs to one direction (`categories.flow` = `expense` / `income`); `categoryId = null` already displays as "Chưa phân loại" | "Uncategorized" is **`categoryId = null`, not a new category row**, matching how deleted categories already behave in stats and lists. A mapping only ever points a receiver at a category whose `flow` matches the transaction's direction. |
| Releases are built locally with `scripts/release.ps1` | A parser fix ships as a normal release. That's what makes code parsers cheap to maintain (D10). |

---

## 2. Architecture

```
Notification from any app
        │
        ▼
[Kotlin] NotificationListenerService
   package in the watched set?  ── no ──▶ dropped, content never read
   (enabled supported apps + apps in sample-capture mode)
        │ yes
   save title + text to a native "inbox" (small SQLite, Kotlin side)
        │  (works even when Flutter isn't running)
        ▼
[Kotlin ↔ Dart] MethodChannel "moneybook/autotrack"
   drainInbox() · isListenerEnabled() · openListenerSettings() · requestRebind()
   listLaunchableApps() · setWatchedPackages()
        │  called on app start / resume (+ EventChannel while the app is open)
        ▼
[Dart] Ingest pipeline (lib/features/autotrack/)
   NotificationEvent (Drift, raw text)
     → ParserRegistry.forPackage(pkg)
          no parser (capture mode) ──▶ status "captured", no transaction
          parser.parse(...):
            ignored  ──▶ status "unmatched" (OTP, promo, unknown wording)
            failed   ──▶ status "failed" (looked like a payment, bad amount)
            matched  ──▶ ParsedTxn (amount, direction, receiver, balance, …)
     → Categorizer, on-device (section 4b):
          receiver account rule → receiver name rule → similar name
          → keyword list → none: categoryId = null ("Chưa phân loại")
     → Repository.addTransaction(...)   ← the app's normal path
        │
        ▼
Existing screens: list, stats, budgets, free money
+ new: review screen ("Chưa phân loại" grouped by receiver + "Cần xem lại"),
  autotrack settings (supported apps + wallets, sample capture,
  receiver mapping, keywords), debug log
```

---

## 3. Design decisions

| # | Decision | Options | Choice and reasoning |
|---|---|---|---|
| D1 | How notifications reach Dart | **A. Kotlin service → native inbox; Dart drains it on resume**<br>**B. Flutter plugin (`notification_listener_service`, etc.) running a background isolate**<br>**C. Kotlin writes straight into the Drift DB** | **A.** It's the most robust option on HyperOS: no Flutter engine needed in the background, and nothing is lost while the app is closed. B depends on a third-party plugin and a background engine that Xiaomi likes to kill. C breaks the "only the repository writes" rule and couples Kotlin to the Drift schema. **Trade-off:** transactions appear when I open the app, not instantly. That's fine for a personal ledger. |
| D2 | Where parsing happens | **A. Dart**<br>**B. Kotlin** | **A.** Parsers are plain Dart tested with `flutter test` against real samples, like the rest of the codebase. Kotlin stays a thin layer that only filters by package and captures text. |
| D3 | Commit right away or hold for review | **A. Commit immediately, flagged `needsReview`**<br>**B. Hold in a pending queue; commit when I confirm** | **A.** Balances, budgets and free money stay correct immediately, which matches the "auto + my edits" choice. I review flagged items in the review screen, and soft delete (`deleted_at`) means undo already works. |
| D4 | Which wallet a notification belongs to | **A. Settings: each supported app has a default wallet, optionally overridden per account suffix**<br>**B. Guess from the wallet name** | **A.** It's explicit and set once. The parser extracts the account suffix when the bank shows it, so two BIDV accounts can map to two wallets. If no wallet is mapped, the event stays raw with status `unmapped`. |
| D5 | Categorization | **A. On-device: receiver → category mapping learned from my edits, plus a keyword list and similar-name matching**<br>**B. A cloud LLM for unknown receivers**<br>**C. An on-device ML model (e.g. a TFLite text classifier)** | **A.** It keeps the app offline, is predictable (every label can say *why* it was chosen) and is cheap to test. B would be the app's first network call and sends spending data off the phone. C needs training data I don't have and gives answers I can't explain. In practice a handful of receivers (the usual coffee shop, Grab, the supermarket) make up most transactions, so an exact mapping covers most of them after a couple of weeks. Details in section 4b. |
| D6 | Dedupe | Two layers: unique `dedupeHash = hash(package + text + postTime rounded to the minute)` on the raw event, then after parsing, skip if a transaction already exists for the same `parserId` + `reference` (or, with no reference, same time + signed amount + balance) | Apps post and update notifications repeatedly. The first layer catches exact repeats before parsing; the second catches the same transaction re-posted with slightly different text, or received twice. |
| D7 | Transfers | **A. Merge the pair into one `TxKind.transfer`**<br>**B. Two linked transactions with the same `groupId`**<br>**C. Don't match; log both sides as they come** | **C (decided 2026-11-23).** Each wallet's balance and the total are already right, because the expense and the income cancel out. Known side effect: monthly stats count the moved amount once as spending and once as income. If that becomes annoying, a manual fix is to change one side to a transfer and delete the other. ~~Was A:~~ That's how a manual transfer is recorded in MoneyBook, so balances and stats are correct without any special handling. Pairing rule: same amount, ≤ 10 min apart, `out` in one tracked wallet + `in` in a different tracked wallet (BIDV ↔ Eximbank). |
| D8 | Balance check (bonus) | Bank notifications include the balance ("SD: …") | If a parser extracts the balance, compare it with the app's computed wallet balance. If they differ, show a banner offering to fix it with an `adjust` transaction (the existing adjust-balance sheet). This catches missed notifications. |
| D9 | Which apps are tracked | **A. Supported apps (those with a parser) can be turned on/off in settings; any app can be put in temporary sample-capture mode**<br>**B. Pick any installed app and track it** | **A.** Tracking an app without a parser can't produce transactions anyway, so the choice that matters is "which of the supported apps do I use", plus their wallets. Sample capture covers the case of a new bank: turn it on for that app for 7 days, collect samples, write the parser. The watched set is **mirrored to native `SharedPreferences`** via `setWatchedPackages`, because the Kotlin service must filter while Flutter isn't running. The capture picker lists launchable apps via a `<queries>` intent filter for `MAIN`/`LAUNCHER`, so no `QUERY_ALL_PACKAGES`. |
| D10 | How notifications become transactions | **A. Hand-written Dart parser per app, in the source code**<br>**B. User-defined format templates edited in the app (v3/v4)** | **A.** I'm the only user and also the developer, banks reword their notifications a few times a year at most, and `release.ps1` ships a build in minutes. B needed a template compiler, an editor with live preview, guards against too-loose templates and a backup format for templates: about 1–1½ days of work plus permanent UI, for a task I'd do a handful of times. Code parsers can also handle oddities a template can't (two-line messages, amounts in the title, optional parts), and every change is covered by fixture tests in CI. **Cost:** a wording change needs a new build, and new notifications go to `unmatched` until then, but they're kept and re-parsed after the update (D11), so nothing is lost. **Revisit** if the app is ever shared with people who use other banks. |
| D11 | Notifications a parser doesn't recognize | **A. Keep as `unmatched` for 30 days; after an app update, re-parse every `unmatched` / `failed` event whose `parserVersion` is older than the current one**<br>**B. Drop immediately** | **A.** A supported app also posts OTPs, promos and login alerts, so most of them won't match, and that's intended. Keeping them gives me the exact text to fix a parser with, and the re-parse turns real payments that arrived before the fix into transactions with their original time. 30 days (not 7) because a fix now waits for a release. |
| D12 | Keeping the listener alive | **A. Plain `NotificationListenerService`, system-bound, no foreground service**<br>**B. Foreground service / periodic worker / wakelock** | **A.** The system binds the listener and calls it only when a notification is posted, so it costs nothing while idle. B adds a permanent notification, wakeups and battery drain for no gain. See section 8. |
| D13 | What "uncategorized" is | **A. `categoryId = null`**<br>**B. A real "Chưa phân loại" category row** | **A.** The app already shows `null` as "Chưa phân loại" in lists and stats. A real row would need one per direction, could be renamed or deleted, and would be counted like a real category in budgets. |
| D14 | When a mapping is created or changed | **A. Categorizing an uncategorized entry creates the mapping silently; changing an already-mapped entry asks "Only this one / Always for this receiver"**<br>**B. Every category change overwrites the mapping** | **A.** Filling in a blank is clearly "this is what this receiver is". Changing a mapped entry is often a one-off (a gift bought at the usual supermarket), and B would quietly break the mapping for every later entry. |
| D15 | MoMo | **A. Out of scope for this version**<br>**B. Parse its notifications** | **A.** MoMo's notifications have no consistent format, so a parser would be fragile, and I plan to stop using MoMo. The design doesn't depend on any particular app, so MoMo can be added later as another parser if needed. **Side effect:** a bank → MoMo top-up arrives as a plain bank expense, not a transfer. While MoMo is still in use, I re-label those as transfers by hand from the review screen (or delete them if I don't track the MoMo wallet). |

---

## 4. Schema changes (Drift v5 → v6)

**New tables**

| Table | Columns |
|---|---|
| `tracked_apps` | packageName (PK), mode (`track` / `capture`), enabled, defaultWalletId? (FK, set null on delete), captureUntil?, createdAt. A `track` row only exists for packages some parser supports. |
| `account_wallets` | id, packageName (FK → `tracked_apps`, cascade), accountSuffix, walletId (FK, cascade). Unique on (packageName, accountSuffix). |
| `notification_events` | id, packageName, title, text (big text if present), postedAt, `dedupeHash` (unique), status (`new` / `parsed` / `unmatched` / `failed` / `unmapped` / `captured`), parserId?, parserVersion?, transactionId? (FK, set null on delete), receiverName?, receiverAccount?, receiverKey? (normalized, indexed), categorySource? (`account` / `name` / `similar` / `keyword` / `user`), createdAt |
| `receiver_rules` | id, matchType (`account` / `name`), matchKey (normalized), flow (`expense` / `income`), displayName (as last seen), categoryId (FK, **cascade delete**), hitCount, lastUsedAt, createdAt, updatedAt. Unique on (matchType, matchKey, flow). |
| `category_keywords` | id, keyword (normalized), categoryId (FK, cascade delete), isBuiltIn, enabled, createdAt. Unique on (keyword, categoryId). |

Rules and keywords cascade on category delete because a rule pointing at nothing is useless; the transactions themselves still become "Chưa phân loại" as today. The same receiver can have one rule per `flow`, so a friend I both pay and get paid by maps to an expense category and an income category separately.

**`transactions` gets two nullable columns** (nothing in the balance or stats logic changes):
- `autoEventId` → `notification_events.id`: marks an entry as auto-logged and links it back to the raw text.
- `needsReview` bool, default false.

**Settings** (existing `settings_kv`): `autotrack.enabled`, `autotrack.unmatchedRetentionDays` (default 30), `autotrack.lastParsedBuild`, `autotrack.similarMatch.enabled` (default on), `autotrack.keywords.enabled` (default on).

**Backup:** bump `kBackupFormatVersion`. Include `tracked_apps` (`track` rows only), `account_wallets`, `receiver_rules`, `category_keywords` and the two new transaction columns. Wallets and categories are referenced by id, so they go through the same id remapping as transactions on import. **Exclude `notification_events`**, since the raw text contains account numbers and balances. Re-imported transactions keep `needsReview` but drop `autoEventId`.

### 4a. Parsers in the source code

```
lib/core/domain/autotrack/
  parsed_txn.dart          ParsedTxn, ParseResult (matched / ignored / failed)
  vnd_amount.dart          parseVndAmount(String) → int?
  parsers/
    notification_parser.dart   the interface + PatternParser base class
    bidv_parser.dart
    eximbank_parser.dart
    registry.dart              const list of all parsers, lookup by package
test/
  autotrack_parsers_test.dart
  fixtures/autotrack/{bidv,eximbank}/*.txt   real samples, masked
```

**Interface**

```dart
abstract class NotificationParser {
  String get id;              // 'bidv' — stored on each event
  int get version;            // bump on every behaviour change (triggers re-parse, D11)
  String get displayName;     // 'BIDV SmartBanking'
  Set<String> get packages;   // exact package names, taken from captured samples
  ParseResult parse(String title, String text);
}
```

`ParsedTxn` = amount (positive `int`), direction (`expense` / `income`), occurredAt?, receiver?, receiverAccount?, balanceAfter?, accountSuffix?, reference?. Both banks print the transaction time in the text, so `occurredAt` comes from the text (local time, minute precision) and falls back to the notification's `postTime` when the text has none or the two differ by more than 3 days (a sign of a misparse).

#### Known formats (from real samples, 2026-11)

Both banks send a **header line followed by `Label: value` lines**, with an explicit `+`/`-` sign, comma thousands separators and a balance. So the base class is a **labeled-lines parser**, not one big regex: it's more readable, and an extra or reordered line from the bank doesn't break it.

**BIDV**

```
BIDV xin thông báo tới Quý khách
Thời gian giao dịch: 18:57 21/11/2026
Tài khoản thanh toán: <account>
Số tiền GD: -80,000 VND
Số dư cuối: 2,702,202 VND
Nội dung giao dịch: <content>
Mã giao dịch: <reference>
```

**Eximbank**

```
Eximbank Mỹ Tho: 17/11/2026 20:25
Tài khoản: <account>
Giao dịch: -328,000 VND
Số dư: 7,284,762 VND
Nội dung: THANH TOAN
Số tham chiếu: <reference>
```

| Field | BIDV label | Eximbank label | Value format |
|---|---|---|---|
| header (required) | `BIDV xin thông báo tới Quý khách` | `Eximbank <branch>: dd/MM/yyyy HH:mm` (branch not hard-coded) | — |
| `occurredAt` | `Thời gian giao dịch` → `HH:mm dd/MM/yyyy` | in the header → `dd/MM/yyyy HH:mm` | note the opposite order |
| `accountSuffix` | `Tài khoản thanh toán` | `Tài khoản` | last 3–4 digits used for wallet mapping (D4) |
| sign + `amount` (required) | `Số tiền GD` | `Giao dịch` | `[+-]1,234,567 VND` |
| `balanceAfter` | `Số dư cuối` | `Số dư` | `1,234,567 VND` |
| `receiver` | `Nội dung giao dịch` | `Nội dung` | free text, may be empty |
| `reference` | `Mã giao dịch` | `Số tham chiếu` | used for dedupe (D6) |

```dart
abstract class LabeledLinesParser extends NotificationParser {
  RegExp get header;                 // must match the first non-empty line
  Map<String, Field> get labels;     // exact label text → field
  // parse(): join title + "\n" + text, skip lines until the header matches,
  // then split each later line at the FIRST ':' (times contain ':' too),
  // trim label and value, look the label up; unknown labels are ignored.
}

class BidvParser extends LabeledLinesParser {
  @override final id = 'bidv';
  @override final version = 1;
  @override final packages = {'<from captured samples>'};
  @override final header = RegExp(r'^BIDV xin thông báo tới Quý khách$');
  @override final labels = {
    'Thời gian giao dịch': Field.timeHmDmy,
    'Tài khoản thanh toán': Field.account,
    'Số tiền GD': Field.signedAmount,
    'Số dư cuối': Field.balance,
    'Nội dung giao dịch': Field.receiver,
    'Mã giao dịch': Field.reference,
  };
}
```

Eximbank is the same with its labels, plus a header regex `^Eximbank .+: (\d{2}/\d{2}/\d{4} \d{2}:\d{2})$` whose group is the time.

**Rules every parser follows**
- Text is NFC-normalized; each line is trimmed (trailing spaces after `Nội dung:` are common). Line breaks are kept: they're what separates the fields. **To confirm in Phase 1:** the listener stores `EXTRA_BIG_TEXT` with its line breaks. If an app only gives a single collapsed line, the parser splits on its known labels instead.
- The title is joined in front of the text, because some apps put the header line in the title and the rest in the body.
- A notification counts as a transaction only if **the header matches and the signed amount line is present**. Anything else (OTP, promo, login alert) → `ignored`. Unknown extra lines are skipped, so a new line added by the bank doesn't break parsing.
- `parseSignedVnd("-80,000 VND") → (expense, 80000)`: requires a leading `+`/`-`, accepts `,` or `.` as thousands separators only when every group after one has exactly 3 digits (so `80,00` is rejected, not read as 8000), strips `VND`/`đ`/`₫`, never uses `double`. Header and amount line present but the amount doesn't parse → `failed`, so it's visible instead of silently dropped.
- An empty value (`Nội dung giao dịch:` with nothing after it) means the field is absent: `receiver = null`, not `""`.
- Parsers are pure functions: no I/O, no clock, no settings.

**Fixtures as the spec.** Each fixture file holds one real notification (account numbers and names masked) under an expected-result header:

```
# expect: expense 80000 at=2026-11-21T18:57 balance=2702202 receiver="<content as sent>"
BIDV xin thông báo tới Quý khách
Thời gian giao dịch: 18:57 21/11/2026
Tài khoản thanh toán: xxxx345
Số tiền GD: -80,000 VND
Số dư cuối: 2,702,202 VND
Nội dung giao dịch: <content as sent>
Mã giao dịch: xxxx123
```

Fixtures mask account numbers and reference codes but **keep the content line as the bank sent it**, apart from personal names, which can be replaced by a stand-in name. The content is what the categorization tests run on.

`# expect: ignored` marks OTPs, promos and login alerts. One test walks every fixture folder, so adding a sample needs no new test code. Fixtures also run the receiver through `normalizeReceiver` and print the key, so I can see whether a pattern captures a useful receiver (R9).

**Fixing a parser when a bank changes its wording**
1. The format-health banner (Phase 6) or the debug log shows `unmatched` events from that app.
2. In the debug log, **"Sao chép đã che"** copies the event with digit runs masked (keeping the last 3 digits), ready to paste as a fixture.
3. Add the fixture, fix or add a pattern, bump `version`, run `flutter test`.
4. Ship with `.\scripts\release.ps1 vX.Y.Z`.
5. On the first start after the update, the app re-parses every `unmatched` / `failed` event whose `parserVersion` is older (D11). Recovered payments are created with their original time, flagged `needsReview`, and a snackbar says how many were recovered.

**Adding a new bank:** Settings → Tự động ghi → **Ghi mẫu** → pick the app → its notifications are stored as `captured` for 7 days (no transactions) → copy them masked into fixtures → write the parser → register it in `registry.dart` → release. After the update the app shows up under supported apps, and captured events from it are parsed like any other.

### 4b. On-device categorization

Pure Dart in `lib/core/domain/autotrack/categorizer.dart`, no I/O: it takes the parsed receiver plus the rules and keywords loaded by the repository, and returns `(categoryId?, source)`.

**Normalizing the receiver** (`normalizeReceiver`, unit-tested): NFC → remove Vietnamese diacritics (`đ` → `d`) → uppercase → every non-letter/digit becomes a space → drop reference-code tokens (pure digits, or mixed letters and digits with 4+ digits) → drop filler words banks add (`CT`, `TT`, `QR`, `CHUYEN TIEN`, `THANH TOAN`, `NAP TIEN`, `TU`, `DEN`…, a constant list) → collapse spaces. Example: `"GRAB*FOOD 8812 TT QR"` → `"GRAB FOOD"`, `"Cà phê Phúc Long - CN Q3"` → `"CA PHE PHUC LONG CN Q3"`. Account numbers are normalized to digits only.

**Lookup order**, first hit wins. Every step only considers categories whose `flow` matches the transaction direction:

| Step | Matches when | `categorySource` | `needsReview` |
|---|---|---|---|
| 1. Account rule | `receiverAccount` equals a rule's `matchKey` | `account` | false |
| 2. Name rule | normalized receiver equals a rule's `matchKey` | `name` | false |
| 3. Similar name (optional) | best rule with token-set similarity ≥ 0.75, or one key is a whole-token prefix of the other with ≥ 2 tokens (`"PHUC LONG"` vs `"PHUC LONG CN Q3"`) | `similar` | **true** |
| 4. Keyword (optional) | a keyword appears as whole token(s) in the normalized receiver; if keywords of several categories hit, the longest keyword wins, ties → no match | `keyword` | **true** |
| 5. Nothing | — | — | true, `categoryId = null` |

Exact rules (steps 1–2) are trusted and skip review, which is what keeps the review list short over time. Steps 3–4 are guesses: the category is filled in, but the entry stays in "Cần xem lại" with the reason shown ("giống *Phúc Long CN Q3*", "từ khoá *CAFE*"), and confirming it creates an exact rule.

**Built-in keywords** are seeded in the v6 migration against the app's seeded categories **by name** (skipped if I've renamed or deleted that category): e.g. `CAFE`, `CA PHE`, `COFFEE`, `TRA SUA`, `HIGHLANDS`, `PHUC LONG`, `GRABFOOD`, `SHOPEEFOOD` → Ăn uống; `GRAB`, `BE`, `XANH SM`, `PETROLIMEX` → Đi lại; `WINMART`, `BACH HOA XANH`, `CIRCLE K` → Mua sắm / Đi chợ. Exact names are fixed when writing the migration against the real seed list in `database.dart`. Keywords match whole tokens so `BE` doesn't fire inside `BEP`.

**Learning** (D14):
- Categorizing an entry that was `null` or a guess (steps 3–4) **upserts** a rule: an account rule if the event has `receiverAccount`, otherwise a name rule. Then every other uncategorized or guessed auto entry with the same key and direction gets the same category, with a snackbar "Đã phân loại thêm 6 giao dịch của *Phúc Long* · Hoàn tác".
- Changing the category of an entry that came from an exact rule asks **"Chỉ giao dịch này" / "Luôn dùng cho *Phúc Long*"**. Only the second updates the rule. Already-categorized past entries are never changed silently.
- Each hit bumps `hitCount` and `lastUsedAt` (shown in settings, and used to break ties in step 3).
- Manually entered transactions never create rules. They have no receiver key.

---

## 5. Phases

### Phase 0: Fork and safety (½ day)
- Fork the repo and create a branch `feat/autotrack`. Check that `flutter test` passes (304 tests) and `flutter analyze` is clean.
- **Export a JSON backup from the installed app before installing any build.** (See risk R1: the signing key.)
- Decide on the install strategy (R1), for example a debug build with a different `applicationIdSuffix` running next to the real app while developing.
- **Done when:** the fork builds and runs on the Xiaomi next to the current app.

### Phase 1: Native listener, sample capture and inbox (1 day, then **collect samples for about a week**)
- `android/.../autotrack/AutoTrackListenerService.kt`: `NotificationListenerService`. First line of `onNotificationPosted`: look up the package in an in-memory `Set` loaded from `SharedPreferences` (reloaded on change), return if absent. Otherwise read `EXTRA_TITLE` and `EXTRA_BIG_TEXT` → `EXTRA_TEXT`, hand the insert to a single background thread, write to the inbox (`SQLiteOpenHelper`, one table).
- Manifest: the service with `BIND_NOTIFICATION_LISTENER_SERVICE`; a `<queries>` block for launcher intents.
- `MainActivity.kt`: MethodChannel `moneybook/autotrack` with `drainInbox`, `isListenerEnabled`, `openListenerSettings`, `requestRebind`, `listLaunchableApps` (package, label, icon PNG), `setWatchedPackages`.
- Dart: `lib/features/autotrack/autotrack_channel.dart`; the **"Ghi mẫu" (sample capture) picker** (searchable list of installed apps); a **debug screen** listing raw events with "copy" and "copy masked".
- `tracked_apps` lands in schema v6 here (the rest in Phase 2). Changes call `setWatchedPackages`, and app start re-sends the set in case the native copy was cleared.
- HyperOS setup: autostart on, battery "No restrictions", app locked in recents.
- **Done when:** BIDV and Eximbank are in capture mode, their real notifications show up in the debug screen with their exact package names, and notifications from other apps don't.

> Collect a variety of samples: payments, money received, transfers between my BIDV and Eximbank accounts, withdrawals, refunds, promos and OTP messages. They become the test fixtures in Phase 2.

### Phase 2: Schema v6 and parsers (1 day)
- Finish `tables.dart` (account wallets, events, rules, keywords, transaction columns), add the migration `if (from < 6)` in `database.dart`, run `dart run build_runner build`, add a v5 → v6 case to `migration_test.dart`.
- `parsed_txn.dart`, `vnd_amount.dart`, `LabeledLinesParser`, `BidvParser`, `EximbankParser`, `registry.dart` (section 4a). Both formats are already known from samples.
- Tests: `test/autotrack_parsers_test.dart` walking `test/fixtures/autotrack/`, seeded with the four samples from 2026-11 (BIDV −80,000 / +500,000, Eximbank −328,000 / +5,000,000). Plus unit tests for `parseSignedVnd` (`,` and `.` separators, missing sign, `80,00` rejected, overflow), both time formats, empty values, trailing spaces, title/body split, an unknown extra line, and a registry test that no package belongs to two parsers.
- **Done when:** every collected payment sample parses to the expected result, and every OTP/promo sample is `ignored`.

### Phase 3: Ingest pipeline, settings and review (1 day)
- `AutoTrackService` (Dart): drain inbox → insert `notification_events` (dedupe) → `ParserRegistry` → `captured` / `unmatched` / `failed`, or matched → resolve wallet (account suffix → app default) → `Categorizer` (Phase 5; until then `categoryId = null`) → `Repository.addTransaction(kind, amount, occurredAt, walletFromId/walletToId, categoryId, note: receiver)` → set `autoEventId` and `needsReview`, store `parserId` / `parserVersion` / `receiverKey` / `categorySource` on the event.
- **Re-parse after update** (D11): on start, if the build number differs from `autotrack.lastParsedBuild`, re-run parsers over `unmatched` / `failed` / `captured` events whose parser is newer, then store the build number.
- Purge `unmatched` events older than `autotrack.unmatchedRetentionDays`, and `captured` events past `captureUntil`, during the same run.
- Run it on app start and on resume (the same hook `todayProvider` uses), and from the EventChannel while the app is open.
- UI:
  - A small "auto" icon on `tx_tile.dart` for auto-logged entries.
  - A **review screen** reached from a dashboard card ("12 giao dịch chưa phân loại"), with two tabs:
    - **"Chưa phân loại"**: auto entries with `categoryId = null`, **grouped by receiver** (name, count, total, latest date). Tapping a group's category chip opens a category picker filtered to the right `flow` and categorizes the whole group at once; expanding the group lets me categorize single entries instead.
    - **"Cần xem lại"**: other `needsReview` entries, including guessed categories with their reason and a one-tap ✓ to confirm.
    - Tapping a single entry opens the existing `tx_editor_screen.dart`; saving clears `needsReview`.
  - **Autotrack settings**: on/off, listener status, **supported apps** (one row per parser: toggle, default wallet, per-account wallets, "not installed" if the package is missing), **Ghi mẫu**, link to the debug log.
  - Debug log filters: `unmatched` / `failed` / `unmapped` / `captured`, with "copy masked", "create manually" and "re-parse".
- **Done when:** one real day of spending is logged correctly without typing anything, and that day's OTPs didn't create anything.

### Phase 4: Transfer matching — dropped
See D7. Both sides of a move between my own accounts are logged as they come.

### Phase 5: On-device categorization (1½ days)
- `lib/core/domain/autotrack/receiver_normalizer.dart` and `categorizer.dart` (section 4b), plugged into `AutoTrackService`.
- Repository: `upsertReceiverRule`, `applyRuleToUncategorized(key, flow, categoryId) → count`, `watchUncategorizedAutoGroups()`, `watchReceiverRules()`, `watchCategoryKeywords()`.
- Learning hooks in `tx_editor_screen.dart` and the review screen (D14), with undo.
- **Settings → Tự động ghi → Phân loại**, two lists:
  - **Người nhận**: every rule, showing the receiver as last seen, account/name badge, direction, category, hit count and last used. Search; tap to change the category; swipe to delete (future entries from that receiver go back to "Chưa phân loại"); "+" to add a rule by hand. Changing a rule offers to re-apply it to that receiver's past auto entries.
  - **Từ khoá**: built-in and my own keywords per category, each toggleable; add/remove; a master switch per layer (similar names, keywords).
- Tests: `test/autotrack_categorizer_test.dart`. Normalization (diacritics, `đ`, reference codes, filler words), lookup order, `flow` filtering, whole-token keywords (`BE` vs `BEP`), tie → no match, similarity threshold edges, learning creates an account rule when an account is present, "only this one" leaves the rule alone. Plus a repository test that deleting a category removes its rules.
- **Done when:** after about two weeks, most new entries arrive already categorized from exact rules, and the "Chưa phân loại" tab only holds genuinely new receivers.

### Phase 6: Hardening (½ day)
- **Balance check** (D8): compare the parsed `balanceAfter` with the computed wallet balance and show a banner offering an `adjust` if they differ.
- **Listener health:** show a warning if `isListenerEnabled` is false, or if no event has arrived from any enabled app in 48 hours. Call `requestRebind` on start.
- **Parser health:** if an enabled app has had `unmatched` events but no `parsed` ones for 3 days, show "BIDV có thể đã đổi mẫu thông báo" with a link to its unmatched events (R3).
- Update the backup format (section 4) and add a test to `backup_test.dart`.
- Add an "Auto-tracking" section to `CLAUDE.md` documenting the rules above, including the parser-fix workflow in section 4a.
- **Done when:** `flutter test` and `flutter analyze` are clean and the CI workflow passes.

---

## 6. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | **Signing key.** The installed app is signed with the friend's release key (`moneybook-release.jks`, not in the repo). My build can't install over it, and uninstalling the app **deletes all the data**. | Export a JSON backup first. Either (a) use my own `applicationId` / suffix and import the backup into it, or (b) ask him to build releases from the merged branch. **With code parsers this matters more:** every parser fix is a release, so I need to be able to ship builds myself. Settle this in Phase 0. |
| R2 | HyperOS kills the listener service | The Kotlin inbox means nothing is lost while Flutter is closed. Autostart, "No restrictions", health banner, `requestRebind`. If the *service itself* is dead, notifications are missed; the balance check (D8) catches that. |
| R3 | A bank changes its notification wording | Anchored patterns mean the new wording goes to `unmatched` instead of creating wrong transactions. The parser-health banner flags it; I fix the parser from the stored text and release. Events are kept 30 days and re-parsed after the update (D11), so payments in between are recovered with their original time. |
| R4 | Double counting (same notification posted twice; transfer pairs; re-parse) | `dedupeHash` unique index + `TransferMatcher`. Re-parse only touches events with no `transactionId`. |
| R5 | A wrong rule or keyword silently mislabels many entries (e.g. one shop name shared by a café and a bookshop) | Exact rules come only from my own choices; guesses (similar/keyword) always stay in "Cần xem lại" with their reason; every applied category records `categorySource`; bulk applies have undo; rules are editable in settings. Prefer account rules over name rules when the bank shows an account. |
| R6 | Conflicts with upstream changes | Keep autotrack code in `features/autotrack/` + `domain/autotrack/`; touch shared files (`tables.dart`, `database.dart`, `tx_tile.dart`, `backup_service.dart`) minimally; rebase often. |
| R7 | A loose pattern turns OTP codes or promo amounts into transactions | Anchored patterns; every parser's fixture folder must contain OTP/promo samples marked `ignored`, enforced in CI; every auto entry starts as `needsReview`. |
| R8 | OTPs, balances and account numbers from tracked apps sit in storage | Only watched apps are stored at all; `unmatched` events purged after 30 days, `captured` after 7; `notification_events` is never exported; fixtures committed to the repo are masked ("copy masked" + review before commit). |
| R9 | Receiver text is too poor to tell receivers apart (e.g. a card payment whose content is only `THANH TOAN`, as in one Eximbank sample, or truncated names) | Normalization drops filler words, so such entries end up with an empty key: they are never used to create rules and always go to "Chưa phân loại". Fixture tests print the normalized key, so I can see how often this happens. (The empty BIDV content in the 2026-11 samples was redacted for sharing, not empty in reality.) |

---

## 7. Files touched

**New**
- `android/app/src/main/kotlin/com/nguyenzap/moneybook/autotrack/AutoTrackListenerService.kt`, `AutoTrackInbox.kt`, `WatchedPackages.kt`
- `lib/features/autotrack/` (channel, service, settings screen, supported apps + wallets, sample capture picker, review screen, receiver mapping + keywords settings, debug screen)
- `lib/core/domain/autotrack/` (`parsed_txn.dart`, `vnd_amount.dart`, `parsers/`, transfer matcher, receiver normalizer, categorizer)
- `test/autotrack_*_test.dart`, `test/fixtures/autotrack/`

**Modified**
- `AndroidManifest.xml`: listener service, `<queries>` for launcher apps (no `INTERNET`)
- `MainActivity.kt`: MethodChannel / EventChannel
- `lib/core/db/tables.dart`, `database.dart` (v6), `repository.dart`: queries for tracked apps, account wallets, events, rules and review
- `lib/features/transactions/tx_tile.dart`, `tx_editor_screen.dart`: auto icon, clearing `needsReview`, learning rules
- `lib/features/backup/backup_service.dart`: format bump
- `test/migration_test.dart`, `test/backup_test.dart`
- `CLAUDE.md`: auto-tracking section

---

## 8. Performance and battery

The listener is **not a worker that runs all the time**. A `NotificationListenerService` is bound by Android itself and does nothing until the system calls `onNotificationPosted`. There is no loop, timer, wakelock or foreground notification (D12).

| Cost | Size | Why |
|---|---|---|
| CPU while idle | ~0 | No code runs between notifications. |
| CPU per notification, unwatched app | microseconds | A `Set.contains(packageName)` and return. Extras aren't read. |
| CPU per notification, watched app | ~1–5 ms | Read two strings, insert one row, on a background thread. Parsing happens later in Dart, when the app is open. |
| RAM | ~15–30 MB while the process is alive | The app's process is kept to host the service. The Flutter engine is **not** started in the background, which is where the real memory cost would be (100 MB+). Android can reclaim the process under memory pressure and rebinds the service later. |
| Battery | not measurable in practice | Notifications already wake the phone; the listener adds a few ms to wakeups that happen anyway. |
| Storage | a few KB/day | Only watched apps; unmatched events purged after 30 days. |
| Parsing + categorization | < 1 ms per entry | Runs in Dart only while the app is open: a few regexes per event, and a few hundred rules and keywords held in memory. Nothing runs in the background. |

**What to avoid** (each of these would cost real battery): a foreground service to "keep it alive", `WorkManager` polling, a wakelock, running the Flutter engine / a Dart isolate in the background, reading extras or touching disk before the package check, or doing the SQLite insert on the main thread.

The HyperOS settings ("No restrictions", autostart) only stop the OS from killing the process. They don't make it use more resources.

**How to verify:** after a few days, check Settings → Battery → MoneyBook (should be ~0% with the app unused), and `adb shell dumpsys batterystats --charged <package>` for wakelocks (should be none from the app).
