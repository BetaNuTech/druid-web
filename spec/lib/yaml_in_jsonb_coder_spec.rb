# frozen_string_literal: true

require 'rails_helper'

RSpec.describe YamlInJsonbCoder do
  describe '.load' do
    it 'parses a YAML document' do
      expect(described_class.load("---\nlead_auto_welcome: '1'\n")).to eq('lead_auto_welcome' => '1')
    end

    it 'returns a Hash untouched' do
      value = { 'lead_auto_welcome' => '1' }
      expect(described_class.load(value)).to equal(value)
    end

    it 'returns nil and plain strings untouched' do
      expect(described_class.load(nil)).to be_nil
      expect(described_class.load('plain')).to eq('plain')
    end
  end

  describe '.dump' do
    it 'writes YAML, and nothing for nil' do
      expect(described_class.dump('a' => 1)).to eq("---\na: 1\n")
      expect(described_class.dump(nil)).to be_nil
    end
  end

  # Production holds both shapes: a YAML document stored as a JSON string
  # (rows saved through the model) and a JSON object (the column default).
  describe 'rows already in the database' do
    let(:property) { create(:property) }

    def stored_type
      Property.connection.select_value("SELECT jsonb_typeof(appsettings) FROM properties WHERE id = '#{property.id}'")
    end

    it 'reads a row holding a JSON object' do
      Property.where(id: property.id).update_all(%q(appsettings = '{"lead_auto_welcome": "1"}'::jsonb))

      expect(stored_type).to eq('object')
      expect(Property.find(property.id).appsettings).to eq('lead_auto_welcome' => '1')
    end

    it 'reads a row holding YAML in a JSON string' do
      yaml = { 'lead_auto_welcome' => '0' }.to_yaml
      Property.where(id: property.id).update_all(['appsettings = to_jsonb(?::text)', yaml])

      expect(stored_type).to eq('string')
      expect(Property.find(property.id).appsettings).to eq('lead_auto_welcome' => '0')
    end

    it 'keeps writing YAML in a JSON string, as before' do
      record = Property.find(property.id)
      record.appsettings = { 'lead_auto_welcome' => '1' }
      record.save!

      expect(stored_type).to eq('string')
      expect(Property.find(property.id).appsettings).to eq('lead_auto_welcome' => '1')
    end
  end
end
