# Incoming Lead Parsing

Processing incoming Lead email notifications is a critical part of the function of Bluesky. These emails are submitted to the `/api/v1/leads.json` endpoint, parsed, and result in the creation of Lead records.

# Identifying and Resetting the API tokens

Authentication to the Leads API is performed using the `token` parameter. API token validation is sourced from `LeadSource` records, which have no corresponding management UI. Use the Rails console to view and manage existing Lead sources.

Lead Sources:
- AdBounce => Slug: adbounce (In use for AdBounces)
- Arrowtel => Slug: Arrowtel (No longer in use)
- BlueSky Portal => Slug: BlueskyPortal (Not in use currently)
- BlueSky Webapp => Slug: Bluesky (Used internally)
- CallCenter => Slug: CallCenter (for use by Blueconnect)
- Cloudmailin => Slug: Cloudmailin (For Cloudmailin webhooks)
- CoStar => Slug: Costar (Not in use)
- Cobalt => Slug: Cobalt (In use for Cobalt reporting integration)
- ForRent => Slug: Zillow (Not in use)
- Lineups => Slug: Lineups (May be in use?)
- Nextiva => Slug: Nextiva (Not in use anymore)
- RentPath => Slug: Zillow (Not in use anymore)
- YardiVoyager => Slug: YardiVoyager (Used for Voyager integrations)
- Zillow => Slug: Zillow (Not in use anymore)

```
# Managing tokens in production
heroku run rails console --app druid-prod
# The following can be used in dev/staging/production
# View the API token
source = LeadSource.active.where(slug: 'Cloudmailin').first
source.api_token
# Reset the API token
source.api_token = nil
source.save
# the API token is automatically regenerated on save when the api_token is missing
source.api_token
```

# Creating/Updating New Lead Sources

1. Create a new record (or update an existing one) in the YAML file at `db/seeds/lead_sources.yml`
2. Run `rake db:seed:lead_sources` in development
3. Deploy changes
4. Run `heroku run rake db:seed:lead_sources --app druid-prod` to load the new lead source in Production

_NOTE:_ Change the `active` flag in the seed YAML file to disable a lead source. They may be deleted manually from the console, but best practice would be to simply disable them unless the record was created in error.

## Cloudmailin

We utilize a Cloudmailin email address that forwards email data to the Lead creation API endpoint above via a webhook.

In most/all cases, the property office email address is configured to forward all emails to this Cloudmailin address to ensure that all possible leads are processed. This unavoidably does lead to a large amount of invalid Lead records.

Why save all of this data? Email headers and content often changes, and we need to be able to retain information that might actually be a lead. We can use the email data to make changes to the appropriate lead parsers and reprocess these records, so no leads are lost.

### The Cloudmailin Lead Parsers

When lead emails data is posted to the Lead API endpoint at /api/v1/leads.json, the flow of logic and data is as follows:

1. The request is received by the `LeadsController` in the `Api::V1` namespace.
2. The LeadsController validates the request, including checking the API token for authentication and authorization.
3. If the token is valid, the controller proceeds to process the lead data.
4. The lead data is parsed using the appropriate email parser located in the `app/lib/leads/adapters/cloud_mailin` directory. The specific parser used depends on the source of the email.
5. The parser extracts the relevant information from the email, such as the lead's first name, last name, phone number, email address, and any additional notes or comments.
6. The parsed lead data is then passed to the Leads::Creator service object for further processing and creation of the lead record.
7. The `Leads::Creator` service object performs additional validation and checks before creating the lead record in the database.
8. If the lead record is successfully created, the `LeadsController` returns a JSON response with the newly created lead record.
9. If there are any errors or validation failures during the lead creation process, the `LeadsController` returns an error response with the appropriate error messages.

### Adding a New Cloudmailin Parser

So, marketing is now using a new Lead source, what to do?

1. Marketing should provide the office email for the property (which should be configured to forward emails to the Cloudmailin email address).
2. Submit a test contact from the Ad source
3. After a minute go to the Lead search page and search for today's Disqualified leads, use "Null" in the search text, and sort by date.
4. Look at the source email for a few "Null" leads and find your contact. Copy/record the Lead ID.
5. 



## Blueconnect (AWS CallCenter)

Blueconnect (AWS callcenter) is managed at [https://blueconnect01.my.connect.aws](https://blueconnect01.my.connect.aws).




