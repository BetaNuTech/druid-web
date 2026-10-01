# Slack Error Notifications (Yoda Bot)

BlueSky posts every reported error to the private corporate Slack channel
`#bluesky-errors` as **Yoda Bot**, the corporate Slack app that Cobalt also uses
for its `#cobalt-errors` posts. The messages are written in Yoda's voice:

````
*Disturbance in the Force, I sense.*
`NoMethodError` in `leads#show`, there is.
```undefined method 'code' for nil```
Born at `app/models/lead.rb:42 in Lead#foo`, this error was.
Carried, this data was: _lead_id: 1c2d..._
Seen 3 more times since last I spoke, it was. Silent, I stayed.
From www.blue-sky.app, this comes.
````

This replaces the old `exception_notification` Slack notifier, which posted
through an incoming webhook (`SLACK_ERROR_NOTIFICATION_WEBHOOK`). Slack has
deprecated incoming webhooks.

Email exception notifications (`EXCEPTION_RECIPIENTS`) are unchanged.

## How it works

1. `config/initializers/exception_notification.rb` registers
   `YodaBot::ErrorNotifier` as an `ExceptionNotifier` notifier. It therefore
   sees both kinds of error:
   - uncaught request exceptions, from `ExceptionNotification::Rack`
   - explicit `ErrorNotification.send(exception, data)` calls
2. `YodaBot::ErrorNotifier` (`app/lib/yoda_bot/error_notifier.rb`) runs inline
   where the error happened. It only gathers details and enqueues a job. The
   details are:
   - the exception class and message
   - `controller#action` for request errors
   - the first backtrace frame inside the app
   - the extra data passed to `ErrorNotification.send`
3. `YodaBotErrorJob` (`app/jobs/yoda_bot_error_job.rb`, `low_priority` queue)
   applies the rate limit. It then posts the text built by
   `YodaBot::ErrorMessage` with `chat.postMessage` from `slack-ruby-client`.

### Rate limit

`ErrorAlert` (`error_alerts` table) posts each distinct error at most once
every 15 minutes. The next post says how many repeats were held back. An error
is identified by its exception class plus the file and method where it was
raised. The message and line number are not part of that, so the same failure
across many properties counts as one error. Exceptions with no backtrace (e.g.
`StandardError.new(msg)`) are grouped by message instead, with digits ignored.

### Safety

- Exception text is escaped, so a message can never ping `@channel` or a user.
- A failed Slack post is only logged (`YodaBotErrorJob: could not post ...`).
  It is never reported through `ErrorNotification`, so a broken token or
  channel cannot cause a loop.
- Nothing is posted in the test environment.

## Configuration

| Variable | Purpose |
| --- | --- |
| `SLACK_CORP_YODABOT_OAUTH_TOKEN` | Yoda Bot's bot token (`xoxb-...`), the same one Cobalt uses. Blank means no posts. |
| `ERROR_SLACK_CHANNEL` | Channel to post in. Defaults to `#bluesky-errors`. Set it blank to stop posts, or point it at a scratch channel for testing. |
| `EXCEPTION_NOTIFIER_ENABLED` | Must be `true` (the default) for any error notification. |

Slack setup:

- The Yoda Bot app needs the `chat:write` scope.
- Because `#bluesky-errors` is private, the bot must be a member. Run `/invite @Yoda Bot` in the channel.

### Heroku

```
heroku config:set SLACK_CORP_YODABOT_OAUTH_TOKEN=xoxb-... -a druid-staging
heroku config:set SLACK_CORP_YODABOT_OAUTH_TOKEN=xoxb-... -a druid-prod
```

After confirming posts arrive, remove the old webhook:

```
heroku config:unset SLACK_ERROR_NOTIFICATION_WEBHOOK -a druid-staging
heroku config:unset SLACK_ERROR_NOTIFICATION_WEBHOOK -a druid-prod
```

### Testing a post

```
heroku run rails runner 'ErrorNotification.send(RuntimeError.new("Yoda test"), source: "manual")' -a druid-staging
```

The post arrives once a worker runs the job. If nothing shows up, look for a
`YodaBotErrorJob: could not post` line in the logs:

- `not_in_channel` / `channel_not_found`: invite the bot to the channel.
- `invalid_auth`: check the token.
