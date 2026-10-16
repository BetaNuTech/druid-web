# OpenAI Model Migration: gpt-4o-mini → gpt-6-luna

OpenAI retires GPT-4o, GPT-4o mini, GPT-4.1 and GPT-4.1 mini on **14 January 2027**.
BlueSky's only AI call is `OpenaiClient#analyze_email`, which classifies every
CloudMailin email and extracts the lead's details (`ProcessCloudmailinEmailJob`).
It ran on `gpt-4o-mini`. It now defaults to **`gpt-6-luna` with
`reasoning_effort: none`**, which is OpenAI's recommended GPT-4.x replacement.

## Evaluation (16 Oct 2026)

We replayed 240 real CloudMailin emails (Jun 2025 to Feb 2026, from a production
copy) through each candidate, using the exact production prompt. The sample was
stratified by the original classification, so rare types (spam, vendor, tour
booking, Lea handoff) are over-represented. The reference answer is
`gpt-6.1-sol` at medium reasoning effort. Category accuracy is scored against
the classification agents later gave the lead (158 emails had one).

| | gpt-4o-mini (old) | **gpt-6-luna · none** | gpt-6-luna · low | gpt-5.6-luna · low | gpt-6-sol · none |
|---|---|---|---|---|---|
| Price in / out per 1M tokens | $0.15 / $0.60 | **$0.10 / $0.50** | $0.10 / $0.50 | $0.20 / $1.20 | $2.00 / $10.00 |
| Cost per 1,000 emails | $0.50 | **$0.31** | $0.34 | $0.75 | $6.21 |
| Latency p50 / p90 | 2.8s / 5.1s | **3.0s / 4.3s** | 3.7s / 5.7s | 2.9s / 4.5s | 3.0s / 4.5s |
| Valid JSON | 100% | 100% | 100% | 100% | 100% |
| lead_type agrees with reference | 79.6% | **86.2%** | 90.0% | 84.6% | 95.4% |
| is_lead agrees | 94.2% | **95.8%** | 95.8% | 95.0% | 98.3% |
| email agrees | 86.7% | **90.4%** | 89.6% | 89.6% | 91.2% |
| phone agrees | 93.8% | **97.9%** | 97.9% | 98.3% | 98.3% |
| last name agrees | 89.2% | **96.2%** | 96.2% | 92.9% | 96.2% |
| source_match agrees | 44.6% | **60.4%** | 63.3% | 60.4% | 72.9% |
| Lead email set to leasing@, blueskyleads@ or the CloudMailin inbox | 6 | **0** | 0 | 0 | 0 |
| Answers with the string `"null"` in a field | 106 | **3** | 1 | 0 | 0 |
| Agent-label lead vs. not-lead accuracy | 82.9% | 82.3% | 81.0% | 81.0% | 82.9% |

Volume is roughly 250 to 1,000 emails a month (about 2,900 input tokens each,
mostly HTML), so every option costs between a few cents and about $6 a month.

### Why gpt-6-luna at effort `none`

- It costs about 38% less than gpt-4o-mini and is closer to the reference on every field.
- It follows the "don't use our own mailbox as the lead email" rule, which
  gpt-4o-mini broke on 118 of 5,518 emails (2.1%) in the production copy.
- It almost never returns the string `"null"`. gpt-4o-mini did so in 44% of
  answers, mostly in `source_match`.
- `low` effort gains about 4 points on lead_type but adds about 0.7s at p50.
  gpt-6-sol is the most accurate, at about 20× the price (still about $6 a month).
  To upgrade later, set `OPENAI_MODEL=gpt-6-sol`. No code change is needed.

### What a model change doesn't fix

Every model scores about 82% against the agents' labels. The gap is the same
emails for every model, mostly Lea handoffs: the prompt requires
`is_lead: true` for a handoff, but agents invalidate many of them as spam,
resident or vendor. Many of those have the handoff reason "Prospect opted out
of SMS via DNC list". That is a business-rules question about Lea handoffs,
not a model-quality issue.

## Deterministic guards

`OpenaiClient#sanitize_analysis` runs on every answer, whatever the model:

- The strings `"null"` and `"nil"`, and empty strings, become real `nil` at any
  depth. Downstream `present?` checks used to treat `"null"` as a value (for
  example `referral: "null"`).
- The lead email is dropped when it is one of our own mailboxes: a local part
  in `INVALID_EMAIL_PREFIXES` (exact, or followed by `+ . - _`), any
  `cloudmailin.net` address, or `COMPANY_EMAIL_DOMAIN`.

## Rollout

1. Check production's setting. If `OPENAI_MODEL` is set explicitly, the new
   default is ignored:
   `heroku config:get OPENAI_MODEL -a druid-prod`
2. Deploy to staging, then set or unset the model there:
   `heroku config:set OPENAI_MODEL=gpt-6-luna -a druid-staging`
   (or `heroku config:unset OPENAI_MODEL` to use the default).
   Watch a day of `cloudmailin_raw_emails` for `failed` rows and odd classifications.
3. Production: same steps with `-a druid-prod`.
4. Rollback: `heroku config:set OPENAI_MODEL=gpt-4o-mini -a druid-prod`. This
   works until 14 Jan 2027, because GPT-4.x still gets its classic parameters.
