require 'rails_helper'

RSpec.describe Yardi::Voyager::Data::GuestCard, '.source_correction_xml' do
  let(:prospect) do
    Yardi::Backup::Database::Prospect.new(prospect_id: 'p0519843', created_at: 1.hour.ago, source: 'Property Website',
                                          agent: 'Nichole Powell', created_by: 'leapro', status: 'Prospect',
                                          first_name: 'Pat', last_name: 'Caller', relationship: nil)
  end
  let(:event) do
    Yardi::Backup::Database::Event.new(event_id: BigDecimal('1931457'), event_type: 'Email', date: Time.utc(2026, 4, 4),
                                       time: '10:31 AM', agent: 'Admin', notes: 'Original note')
  end

  it "re-states the card's first-contact event under its own ID with only the source changed" do
    xml = described_class.source_correction_xml(propertyid: '1002edge', prospect: prospect, event: event,
                                                source: 'Google Business Profile')
    doc = Nokogiri::XML(xml)

    expect(doc.at_xpath('//Customer/@Type').value).to eq('prospect')
    expect(doc.at_xpath("//Identification[@IDType='ProspectID']/@IDValue").value).to eq('p0519843')
    expect(doc.at_xpath("//Identification[@IDType='PropertyID']/@IDValue").value).to eq('1002edge')
    expect(doc.xpath('//Customer/*').map(&:name)).to eq(%w[Identification Identification Name])
    expect(doc.xpath('//Event').size).to eq(1)
    expect(doc.at_xpath('//Event/@EventType').value).to eq('Email')
    expect(doc.at_xpath('//Event/@EventDate').value).to eq('2026-04-04T10:31:00')
    expect(doc.at_xpath('//Event/EventID/@IDValue').value).to eq('1931457')
    expect(doc.at_xpath('//Event/FirstContact').text).to eq('true')
    expect(doc.at_xpath('//Event/Comments').text).to eq('Original note')
    expect(doc.at_xpath('//Event/TransactionSource').text).to eq('Google Business Profile')
  end

  it "names the card's current agent so Voyager does not reassign the card" do
    xml = described_class.source_correction_xml(propertyid: '1002edge', prospect: prospect, event: event,
                                                source: 'Google Business Profile')
    doc = Nokogiri::XML(xml)

    expect(doc.at_xpath('//Event/Agent/AgentName/FirstName').text).to eq('Nichole')
    expect(doc.at_xpath('//Event/Agent/AgentName/LastName').text).to eq('Powell')
  end
end
