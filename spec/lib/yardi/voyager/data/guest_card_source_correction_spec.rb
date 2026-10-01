require 'rails_helper'

RSpec.describe Yardi::Voyager::Data::GuestCard, '.source_correction_xml' do
  let(:prospect) do
    Yardi::Backup::Database::Prospect.new(prospect_id: 'p0523371', created_at: 1.hour.ago, source: 'Property Website',
                                          agent: 'Esteban Garcia', created_by: 'leapro', status: 'Prospect',
                                          first_name: 'Pat', last_name: 'Caller', relationship: nil)
  end

  it "re-states only the card's identity and adds one first-contact event with the new source" do
    xml = described_class.source_correction_xml(propertyid: '1002edge', prospect: prospect, source: 'Google Business Profile',
                                                event_date: Time.zone.parse('2026-09-28 15:02:00'), comment: 'corrected')
    doc = Nokogiri::XML(xml)

    expect(doc.at_xpath('//Customer/@Type').value).to eq('prospect')
    expect(doc.at_xpath("//Identification[@IDType='ProspectID']/@IDValue").value).to eq('p0523371')
    expect(doc.at_xpath("//Identification[@IDType='PropertyID']/@IDValue").value).to eq('1002edge')
    expect(doc.xpath('//Customer/*').map(&:name)).to eq(%w[Identification Identification Name])
    expect(doc.xpath('//Event').size).to eq(1)
    expect(doc.at_xpath('//Event/FirstContact').text).to eq('true')
    expect(doc.at_xpath('//Event/TransactionSource').text).to eq('Google Business Profile')
    expect(doc.at_xpath('//Event/Agent/AgentName/FirstName').text).to eq('Esteban')
    expect(doc.at_xpath('//Event/Agent/AgentName/LastName').text).to eq('Garcia')
  end
end
