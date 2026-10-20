# OpenAI Model Migration: gpt-4o → gpt-6-sol

OpenAI retires GPT-4o, GPT-4o mini, GPT-4.1 and GPT-4.1 mini on **14 January 2027**.
BlueSky's only AI call is `OpenaiClient#analyze_email`, which classifies every
CloudMailin email and extracts the lead's details (`ProcessCloudmailinEmailJob`).

Production and staging pinned `OPENAI_MODEL=gpt-4o`. The code default was
`gpt-4o-mini`, but that default only applied where the variable was unset.
The replacement is **`gpt-6-sol` with `reasoning_effort: none`**, which is now
also the code default.

## Evaluation (16 Oct 2026)

We replayed 240 real CloudMailin emails (Jun 2025 to Feb 2026, from a production
copy) through each candidate, using the exact production prompt. The sample was
stratified by the original classification, so rare types (spam, vendor, tour
booking, Lea handoff) are over-represented. The reference answer is
`gpt-6.1-sol` at medium reasoning effort. Category accuracy is scored against
the classification agents later gave the lead (158 emails had one).

Rerunning gpt-4o reproduced the stored production answers (96% same
lead_type), which confirms it was the model in production.

| | **gpt-4o (prod)** | **gpt-6-sol · none** | gpt-6-luna · none | gpt-6-luna · low | gpt-5.6-luna · low | gpt-4o-mini |
|---|---|---|---|---|---|---|
| Price in / out per 1M tokens | $2.50 / $10.00 | $2.00 / $10.00 | $0.10 / $0.50 | $0.10 / $0.50 | $0.20 / $1.20 | $0.15 / $0.60 |
| Cost per 1,000 emails | $9.29 | **$6.21** | $0.31 | $0.34 | $0.75 | $0.50 |
| Latency p50 / p90 | **1.7s / 2.4s** | 3.0s / 4.5s | 3.0s / 4.3s | 3.7s / 5.7s | 2.9s / 4.5s | 2.8s / 5.1s |
| Valid JSON | 100% | 100% | 100% | 100% | 100% | 100% |
| lead_type agrees with reference | 93.8% | **95.4%** | 86.2% | 90.0% | 84.6% | 79.6% |
| is_lead agrees | 98.3% | **98.3%** | 95.8% | 95.8% | 95.0% | 94.2% |
| email agrees | 83.3% | **91.2%** | 90.4% | 89.6% | 89.6% | 86.7% |
| phone agrees | 95.4% | **98.3%** | 97.9% | 97.9% | 98.3% | 93.8% |
| last name agrees | 92.5% | **96.2%** | 96.2% | 96.2% | 92.9% | 89.2% |
| source_match agrees | 57.5% | **72.9%** | 60.4% | 63.3% | 60.4% | 44.6% |
| Lead email set to leasing@, blueskyleads@ or the CloudMailin inbox | 0 | 0 | 0 | 0 | 0 | 6 |
| Answers with the string `"null"` in a field | 0 | 0 | 3 | 1 | 0 | 106 |
| Agent-label lead vs. not-lead accuracy | 82.9% | 82.9% | 82.3% | 81.0% | 81.0% | 82.9% |

Costs assume OpenAI's automatic prompt caching (about 40% of input tokens hit
the cache). Volume is roughly 250 to 1,000 emails a month at about 2,900 input
tokens each, mostly HTML, so gpt-6-sol costs about $2 to $6 a month.

### Why gpt-6-sol

- It is the like-for-like successor to gpt-4o: as accurate or more accurate on
  every field, and about a third cheaper.
- gpt-6-luna costs about 96% less but is clearly weaker than gpt-4o at
  classification (lead_type 86% vs. 94%). At this volume the saving is only
  under $6 a month, which isn't worth worse lead routing.
- gpt-6-sol is about 1.3s slower at p50. The classifier runs in a background
  job, so nobody waits on it.
- `gpt-6.1-sol` has no `none` effort. At `low` or `medium` it costs about the
  same and is slower, with no measured gain over `gpt-6-sol · none`.

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
  depth. Downstream `present?` checks would otherwise treat `"null"` as a value
  (for example `referral: "null"`).
- The lead email is dropped when it is one of our own mailboxes: a local part
  in `INVALID_EMAIL_PREFIXES` (exact, or followed by `+ . - _`), any
  `cloudmailin.net` address, or `COMPANY_EMAIL_DOMAIN`. The production copy
  has 118 such answers, all from Jun to Aug 2025, around when the prompt rule
  was added (21 Jul 2025). No current model broke the rule in the eval, but
  the guard keeps it from coming back.

## Rollout

The model is chosen by `OPENAI_MODEL`, so switching needs no deploy. Changing a
config var restarts every dyno, so wait until no long-running job is in flight.

1. Staging: `heroku config:set OPENAI_MODEL=gpt-6-sol -a druid-staging`
   (done 20 Oct 2026, and verified with a live classification).
2. Production: `heroku config:set OPENAI_MODEL=gpt-6-sol -a druid-prod`, then
   watch `cloudmailin_raw_emails` for `failed` rows and odd classifications.
3. Rollback: `heroku config:set OPENAI_MODEL=gpt-4o -a druid-prod`. This works
   until 14 Jan 2027, because GPT-4.x still gets its classic parameters.
