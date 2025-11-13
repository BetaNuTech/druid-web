require 'rails_helper'
include ApplicationHelper

RSpec.describe LeadsHelper, type: :helper do
  describe "titles_for_select" do
    it "should return an array of strings" do
      out = titles_for_select('Mr.')
      expect(out).to match('selected="selected" value="Mr."')
      expect(out).to match('value="Mr."')
      expect(out).to match('value="Mrs."')
    end
  end

  describe "display_preference_option" do
    it "should return the attribute for Strings" do
      expect(display_preference_option("hello")).to eq("hello")
    end

    it "should return the attribute for Numbers" do
      expect(display_preference_option(1.2)).to eq(1.2)
      expect(display_preference_option(1)).to eq(1)
      expect(display_preference_option(0)).to eq(0)
    end

    it "should return the short_date for Date" do
      val = Date.current
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return the short_date for DateTime" do
      val = DateTime.current
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return the short_date for TimeWithZone" do
      val = DateTime.current
      expect(display_preference_option(val)).to be_a(String)
    end

    it "should return 'No preference' if no value is present" do
      expect(display_preference_option(nil)).to eq('No preference')
      expect(display_preference_option(false)).to eq('No preference')
    end
  end

  describe "sources_for_select" do
    let(:sources) {
      [
        create(:lead_source, slug: LeadSource::DEFAULT_SLUG, name: 'BlueSky WebApp'),
        create(:lead_source, slug: 'Other', name: 'Other Source'),
      ]
    }

    it "should return form options as HTML for selecting a lead source" do
      option1, option2 = sources
      out = sources_for_select(option2.id)
      expect(out).to match("<option selected=\"selected\" value=\"#{option2.id}\">#{option2.name}</option>")
    end
  end

  describe "linkify_note_content" do
    it "returns empty string for nil input" do
      expect(linkify_note_content(nil)).to eq('')
    end

    it "returns empty string for blank input" do
      expect(linkify_note_content('')).to eq('')
      expect(linkify_note_content('   ')).to eq('')
    end

    it "converts HTTP URLs to clickable links" do
      text = "Check out http://example.com for more info"
      result = linkify_note_content(text)
      expect(result).to include('<a href="http://example.com"')
      expect(result).to include('target="_blank"')
      expect(result).to include('rel="noopener noreferrer"')
      expect(result).to include('>http://example.com</a>')
    end

    it "converts HTTPS URLs to clickable links" do
      text = "Visit https://secure.example.com"
      result = linkify_note_content(text)
      expect(result).to include('<a href="https://secure.example.com"')
      expect(result).to include('target="_blank"')
      expect(result).to include('rel="noopener noreferrer"')
    end

    it "converts multiple URLs in same text" do
      text = "Check http://example.com and https://another.com"
      result = linkify_note_content(text)
      expect(result).to include('<a href="http://example.com"')
      expect(result).to include('<a href="https://another.com"')
    end

    it "handles Lea conversation URLs" do
      text = "Lea conversation: https://lea.example.com/conversation/abc123"
      result = linkify_note_content(text)
      expect(result).to include('<a href="https://lea.example.com/conversation/abc123"')
      expect(result).to include('target="_blank"')
    end

    it "preserves text before and after URLs" do
      text = "Before http://example.com after"
      result = linkify_note_content(text)
      expect(result).to include('Before')
      expect(result).to include('after')
      expect(result).to include('<a href="http://example.com"')
    end

    it "handles text without URLs" do
      text = "This is plain text without any links"
      result = linkify_note_content(text)
      expect(result).to include('This is plain text')
      expect(result).not_to include('<a href=')
    end

    it "applies simple_format for newlines" do
      text = "Line 1\nLine 2"
      result = linkify_note_content(text)
      expect(result).to include('<p>')
      expect(result).to include('</p>')
    end

    it "handles URLs with query parameters" do
      text = "Check https://example.com/page?foo=bar&baz=qux"
      result = linkify_note_content(text)
      expect(result).to include('<a href="https://example.com/page?foo=bar&baz=qux"')
    end
  end
end
