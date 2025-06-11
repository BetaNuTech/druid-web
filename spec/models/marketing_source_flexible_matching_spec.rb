require 'rails_helper'

RSpec.describe MarketingSource, 'flexible matching', type: :model do
  let(:property) { create(:property) }
  
  describe '.normalize_name' do
    it 'removes common TLD suffixes' do
      expect(MarketingSource.normalize_name('Zillow.com')).to eq('zillow')
      expect(MarketingSource.normalize_name('Apartments.net')).to eq('apartments')
      expect(MarketingSource.normalize_name('Rent.org')).to eq('rent')
    end
    
    it 'removes www prefix' do
      expect(MarketingSource.normalize_name('www.Zillow.com')).to eq('zillow')
      expect(MarketingSource.normalize_name('www.apartments')).to eq('apartments')
    end
    
    it 'converts to lowercase and strips whitespace' do
      expect(MarketingSource.normalize_name(' ZILLOW.COM ')).to eq('zillow')
      expect(MarketingSource.normalize_name('  ApartmentList  ')).to eq('apartmentlist')
    end
    
    it 'handles blank values' do
      expect(MarketingSource.normalize_name('')).to eq('')
      expect(MarketingSource.normalize_name(nil)).to eq('')
    end
  end
  
  describe '.find_by_flexible_referral' do
    let!(:zillow_source) { create(:marketing_source, property: property, name: 'Zillow.com') }
    let!(:apartments_source) { create(:marketing_source, property: property, name: 'Apartments') }
    
    it 'finds exact matches first' do
      result = MarketingSource.find_by_flexible_referral(property, 'Zillow.com')
      expect(result).to eq(zillow_source)
    end
    
    it 'finds flexible matches when exact match not found' do
      result = MarketingSource.find_by_flexible_referral(property, 'Zillow')
      expect(result).to eq(zillow_source)
      
      result = MarketingSource.find_by_flexible_referral(property, 'www.zillow.com')
      expect(result).to eq(zillow_source)
    end
    
    it 'finds matches with different TLD patterns' do
      result = MarketingSource.find_by_flexible_referral(property, 'Apartments.com')
      expect(result).to eq(apartments_source)
      
      result = MarketingSource.find_by_flexible_referral(property, 'apartments.net')
      expect(result).to eq(apartments_source)
    end
    
    it 'returns nil when no match found' do
      result = MarketingSource.find_by_flexible_referral(property, 'NonExistent')
      expect(result).to be_nil
    end
    
    it 'returns nil for blank referral' do
      result = MarketingSource.find_by_flexible_referral(property, '')
      expect(result).to be_nil
      
      result = MarketingSource.find_by_flexible_referral(property, nil)
      expect(result).to be_nil
    end
  end
  
  describe '#leads with flexible matching' do
    let!(:marketing_source) { create(:marketing_source, property: property, name: 'Zillow.com') }
    let!(:exact_lead) { create(:lead, property: property, referral: 'Zillow.com') }
    let!(:flexible_lead1) { create(:lead, property: property, referral: 'Zillow') }
    let!(:flexible_lead2) { create(:lead, property: property, referral: 'www.zillow.com') }
    let!(:unmatched_lead) { create(:lead, property: property, referral: 'Apartments.com') }
    
    it 'includes exact and flexible matches' do
      leads = marketing_source.leads
      
      expect(leads).to include(exact_lead)
      expect(leads).to include(flexible_lead1)
      expect(leads).to include(flexible_lead2)
      expect(leads).not_to include(unmatched_lead)
    end
    
    it 'returns an ActiveRecord relation' do
      leads = marketing_source.leads
      expect(leads).to be_a(ActiveRecord::Relation)
    end
  end
end