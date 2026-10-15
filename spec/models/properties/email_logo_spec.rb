require 'rails_helper'

# Prospect emails for a property without its own footer logo fall back to a
# file served from public/. That URL is baked into every email sent, so the
# file must exist, and it must carry the current company brand.
RSpec.describe 'Default email footer logo', type: :model do
  let(:property) { create(:property) }

  it 'falls back to the Bluecore logo, which exists in public/' do
    expect(property.email_footer_logo).not_to be_attached

    url = property.email_footer_logo_url

    expect(url).to end_with('/bluecore_logo_small.png')
    expect(Rails.root.join('public', File.basename(url))).to exist
  end

  # The template preview renders layouts/message_templates/email.html.erb, whose
  # footer is {{ email_business_logo }}.
  it 'is the logo in a rendered email when no property is given' do
    template = MessageTemplate.new(body: '<p>Hello</p>', message_type: MessageType.new(name: 'Email', html: true))

    html = template.body_preview

    expect(html).to include('/bluecore_logo_small.png')
    expect(html).not_to match(/bluecrest/i)
  end

  # Emails that were already sent still point at the old file; keep it so they
  # don't show a broken image.
  it 'keeps the old Bluecrest file for already-sent emails' do
    expect(Rails.root.join('public/bluecrest_logo_small.png')).to exist
  end
end
