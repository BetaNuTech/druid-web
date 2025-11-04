# Email Graphics Permanence

## Overview

Email header images and footer logos uploaded to properties are permanently stored and cannot be deleted through the user interface. This design decision preserves the integrity of previously sent emails.

## Why Email Graphics Cannot Be Deleted

### Technical Explanation

When an automated email is sent to a lead or prospect:

1. The email body is generated using Liquid templates
2. The HTML includes image URLs that reference property-specific graphics stored in ActiveStorage/S3
3. These URLs point to specific blob files in cloud storage
4. The rendered HTML (with image URLs) is stored in the database
5. The email is delivered to the recipient with these external image references

### The Problem with Deletion

Email clients (Gmail, Outlook, Apple Mail, etc.) do **not** embed images directly into emails. Instead, they:

1. Display the HTML structure
2. Make HTTP requests to the image URLs when the user opens the email
3. Download and display the images in real-time

**If a property deletes their custom email header or footer:**
- The S3 file is permanently removed
- All previously sent emails that reference that image URL will show broken images
- Recipients who open old emails will see missing image icons instead of the graphics

### Real-World Impact

**Example Scenario:**
1. Property uploads custom header image on January 1
2. System sends 500 emails to leads throughout January
3. Property decides to delete the header image on February 1
4. All 500 previously sent emails now show broken images when recipients open them
5. This damages the professional appearance and brand consistency

## Current Implementation

### Model: Properties::Logo Concern

**Email attachments:**
- `email_header_image` - Custom header graphic (recommended 620px wide)
- `email_footer_logo` - Custom footer logo

**Behavior:**
- ✅ Properties can upload new email graphics
- ✅ Uploading a new file replaces the reference (previous file becomes orphaned but remains in S3)
- ❌ Properties **cannot** delete email graphics through the UI
- ✅ General property logo (`logo`) can still be deleted if needed

### User Interface

**Property Edit Form:**
- Displays current email header/footer images
- Provides file upload fields to replace images
- **No "Remove" checkboxes** for email graphics
- Helper text explains: "Upload a new image to replace. Images cannot be deleted to preserve sent email integrity."

### Code Protection

**Removed capabilities:**
- `remove_email_header_image` attribute accessor
- `remove_email_footer_logo` attribute accessor
- `purge_email_header` callback and method
- `purge_email_footer` callback and method
- Strong parameters for email graphic removal

## User Workflow

### Uploading Initial Graphics

1. Navigate to Property Edit page
2. Scroll to "Email Header Image" or "Email Footer Logo" section
3. Click "Choose File" and select image
4. Save the property
5. New graphics will be used in all future automated emails

### Replacing Graphics

1. Navigate to Property Edit page
2. Current image is displayed in the form
3. Click "Choose File" and select new image
4. Save the property
5. **New uploads will be used for future emails**
6. **Previous emails will continue showing the old image** (as long as it remains in S3)

### What Happens to Old Images

When you upload a new email graphic to replace an existing one:

- The property record updates to reference the new ActiveStorage blob
- The old blob remains in S3 storage
- Previously sent emails continue to reference and display the old blob
- Old blobs are **not automatically deleted** to preserve email history

## Storage Considerations

### Cost Analysis

**Typical email graphics:**
- Email header: 50-200KB
- Email footer logo: 20-100KB
- Total per property: ~70-300KB

**Example cost (AWS S3 Standard):**
- $0.023 per GB/month
- 100 properties with replaced graphics = ~30MB
- Monthly cost: less than $0.01

**Conclusion:** Storage cost is negligible compared to the value of preserving email integrity.

### Cleanup Options

If S3 storage becomes a concern, administrators can:

1. **Manual audit:** Identify truly orphaned blobs (never used in any sent message)
2. **Rails console cleanup:** Manually purge specific unused blobs
3. **Lifecycle policies:** Configure S3 lifecycle rules for very old unused blobs

**IMPORTANT:** Always check message history before purging any blob:

```ruby
# Example cleanup check (Rails console only, not exposed to users)
blob = ActiveStorage::Blob.find(blob_id)
blob_key = blob.key

# Check if used in any sent emails
sent_email_count = Message.email.sent.outgoing
  .where("body LIKE ?", "%#{blob_key}%").count

if sent_email_count == 0
  puts "Safe to purge - not referenced in any sent emails"
  blob.purge  # Admin action only
else
  puts "DO NOT PURGE - used in #{sent_email_count} sent email(s)"
end
```

## Industry Best Practices

This approach aligns with how professional email platforms handle attachments:

- **Mailchimp:** Campaign images are permanently hosted, no deletion after sending
- **SendGrid:** Email template assets persist indefinitely
- **Salesforce Marketing Cloud:** Sent email assets are locked and preserved
- **ActiveCampaign:** Images used in sent campaigns cannot be deleted

## Future Enhancements

Potential improvements if email volume grows significantly:

1. **Blob versioning:** Track image versions and allow safe cleanup of very old versions
2. **Base64 embedding:** Embed small logos directly in email HTML (trade-off: larger email size)
3. **Archive flagging:** Mark old blobs as "archived" but keep them accessible
4. **Usage analytics:** Dashboard showing which blobs are actively used vs orphaned

## Development Notes

### Testing Considerations

When testing email functionality:

1. **Upload graphics:** Test uploading header/footer images
2. **Verify preview:** Check that `/message_templates/:id` shows property graphics
3. **Send test email:** Confirm actual sent emails contain correct image URLs
4. **Replace graphics:** Upload new images and verify replacement works
5. **Check old messages:** View previously sent messages at `/messages/:id` to ensure images still load

### Related Code Locations

**Model:**
- `/app/models/concerns/properties/logo.rb` - ActiveStorage attachments and URL helpers

**Forms:**
- `/app/views/properties/_form_general.html.erb` - Property edit form

**Email Templates:**
- `/app/views/layouts/message_templates/email.html.erb` - Email layout with Liquid variables

**Message Rendering:**
- `/app/models/message_template.rb` - Template rendering with Liquid processing
- `/app/models/message.rb` - Message display with layout

**Template Data:**
- `/app/models/concerns/leads/messaging.rb` - Lead template data generation
- `/app/models/concerns/properties/logo.rb` - Image URL helpers

## Questions and Answers

**Q: What if a property genuinely needs to remove an inappropriate image?**
A: Upload a replacement image immediately. Contact an administrator if the original must be purged from storage (rare cases only).

**Q: Won't storage costs accumulate over time?**
A: Minimally. Images are small (~50-200KB). Even 1000 replaced images = ~100MB = ~$0.002/month on S3.

**Q: Can administrators delete graphics if absolutely necessary?**
A: Yes, via Rails console, but only after verifying the blob is not referenced in any sent messages. This should be extremely rare.

**Q: What happens if we migrate to a different storage provider?**
A: ActiveStorage abstracts storage. Images can be migrated to new storage while preserving URLs through ActiveStorage's redirect mechanism.

**Q: Does this apply to the general property logo too?**
A: No. The general `logo` field can still be deleted because it's used in the application UI, not in sent emails. Only `email_header_image` and `email_footer_logo` are protected.

## Conclusion

Preserving email graphics is essential for maintaining professional communication history. This approach:

- ✅ Protects brand integrity in historical emails
- ✅ Prevents user errors that would break sent messages
- ✅ Aligns with industry best practices
- ✅ Has negligible storage cost impact
- ✅ Provides clear user expectations

Users can easily replace graphics when needed, but the system prevents accidental deletion that would harm previously sent communications.
