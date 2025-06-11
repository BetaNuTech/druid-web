require 'rails_helper'

RSpec.describe OpenaiClient, 'marketing sources integration' do
  let(:property) { create(:property) }
  let(:lead_source) { create(:lead_source) }
  let(:active_sources) { [lead_source] }
  let(:marketing_sources) { ['Zillow.com', 'Apartments.com', 'Rent.com'] }
  
  let(:email_data) {
    {
      headers: {
        'From' => 'john.doe@example.com',
        'Subject' => 'New Zillow Contact'
      },
      plain: 'John Doe is interested in your property'
    }
  }
  
  describe '#build_analysis_prompt' do
    let(:client) { OpenaiClient.new }
    
    it 'includes marketing sources in the prompt' do
      prompt = client.send(:build_analysis_prompt, email_data, property, active_sources, marketing_sources)
      
      expect(prompt).to include('Marketing Sources for this Property: Zillow.com, Apartments.com, Rent.com')
      expect(prompt).to include(property.name)
      expect(prompt).to include('john.doe@example.com')
      expect(prompt).to include('New Zillow Contact')
    end
    
    it 'handles empty marketing sources list' do
      prompt = client.send(:build_analysis_prompt, email_data, property, active_sources, [])
      
      expect(prompt).to include('Marketing Sources for this Property: None configured')
    end
    
    it 'handles nil marketing sources' do
      prompt = client.send(:build_analysis_prompt, email_data, property, active_sources)
      
      expect(prompt).to include('Marketing Sources for this Property: None configured')
    end
  end
  
  describe 'system prompt instructions' do
    let(:client) { OpenaiClient.new }
    
    it 'includes instructions for marketing source prioritization' do
      system_prompt = client.send(:system_prompt)
      
      expect(system_prompt).to include('FIRST try to match against the Marketing Sources list')
      expect(system_prompt).to include('Marketing Sources are the property\'s configured lead attribution sources')
      expect(system_prompt).to include('if email mentions "Zillow" and Marketing Sources includes "Zillow.com", return "Zillow.com"')
    end
  end
end