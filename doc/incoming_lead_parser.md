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
- Nextiva => Slug: Nextiva (Nextiva phone system pushes leads into Bluesky)
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
5. Perform a new database backup using `heroku pg:backups:capture --app druid-prod`
6. Load the production database into your development environment using `bin/load_prod_db`
7. In your development console find the "test" Lead and raw email JSON data: `lead = Lead.find("XXX"); data = JSON.parse(lead.preference.raw_data)`
8. Copy that data to a text file for convenience.
9. Create a new lead email parser in `app/lib/leads/adapters/cloud_mailin/` using the `rent_dot_com_parser.rb` as a reference.
10. Change the new parser class name to match the file name according to Ruby/Rails Classname/Filename conventions.
11. Add a `require_relative` statement to `app/lib/leads/adapters/cloud_mailin/parser.rb` to load the new parser. Place it before `null_parser`.
12. Add the new Parser class name to the `PARSERS` array. Keep in mind that the `match?` method of each parser is executed in this order to identify where an email is coming from. Depending on the implementation of `match`, this order can be important as emails from different sources may have similar data.
13. In the new parser, the `match` method of the parser must return true if and only if the email is coming from the new lead source. Update it to return true if the lead email is coming from this source.
14. Testing: use the Rails console to test your parser during its development. Like this `lead2 = Lead.reparse(lead)` Issue `reload!` after file changes then find your test lead again with `lead = Lead.find("XXX")`. Using `binding.pry` statements to create breakpoints is extremely helpful.
15. In the new parser, notice that the `parse` method returns a Hash of Lead attributes. Processing is done for each attribute then all of the data is returned as a single Hash.
16. You will notice that some parsers use regex, and the `rent_dot_com_parser.rb` uses Nokogiri to parse HTML and extract DOM elements using CSS syntax.
17. Creating the parser will require a lot of incremental changes and testing in a feedback loop of edit/reload/reparse.
18. When the new parser is functional, try to reparse Leads which had a parse failure: `reparsed_leads = Lead.where(created_at: 7.days.ago.., classification: 'parse_failure').map{|lead| Lead.reparse(lead)}.select{|lead| lead.valid?}`.
19. commit, update version, and deploy to production.
20. Production testing: open a Heroku rails console with `heroku run rails console --app druid-production`. Find the test Lead record by ID, and issue a `reparse` for that Lead as detailed above to see if a new valid Lead is created. If successful, reparse recent Leads as detailed in the previous step. Otherwise, debug in development.


## Blueconnect (AWS CallCenter)

Blueconnect (AWS callcenter) is managed at [https://blueconnect01.my.connect.aws](https://blueconnect01.my.connect.aws).

All Blueconnect phone numbers are documented at [https://docs.google.com/spreadsheets/d/1u93B1eAuxekjjyllpFF0Jlts9scIC0pZT8GANOP1XG0/edit#gid=0](https://docs.google.com/spreadsheets/d/1u93B1eAuxekjjyllpFF0Jlts9scIC0pZT8GANOP1XG0/edit#gid=0).

The Blueconnect AWS callcenter services incoming calls and redirects them to Property main phone numbers as configured/documented in Bluesky. The Flow [https://blueconnect01.awsapps.com/connect/contact-flows/edit?id=arn%3Aaws%3Aconnect%3Aus-east-1%3A212049522981%3Ainstance%2F7666c929-8e23-4f2b-8268-df4b94da6aca%2Fcontact-flow%2Ff1487648-84ad-4731-a719-11446b806660](PROD - Incoming Call Passthrough) extracts call meta-information and supplies it to Lambda functions which call a Bluesky API endpoint to identify the intended property based on what number is being called. The call is then forwarded to that Property main phone number and the Bluesky Lead API is called simultaneously to create a Lead.

The Lambda functions are at [https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions) and the code for these functions is mirrored in the Bluesky source at `external/lambda/`

### Property Setup

Edit the Property record in Bluesky and make sure that there is a Listing ID active for "Call Center". Use the convention of using the Yardi ID for the listing code and make sure the "Active" checkmark is selected.

### Adding a new Marketing Phone Number

TODO: AWS CallCenter
TODO: Document number in the Google docs spreadsheet
TODO: Setup the Marketing source phone number in Bluesky
TODO: Testing
