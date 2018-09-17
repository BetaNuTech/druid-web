require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do

  let(:phone_number) { build(:phone_number) }

  it 'can be initialized' do
    assert(phone_number.valid?)
  end

  describe 'validations' do

    it 'requires a name' do
      phone_number.name = nil
      refute(phone_number.valid?)
    end

    it 'requires a number' do
      phone_number.number = nil
      refute(phone_number.valid?)
    end

    it 'formats the number before saving' do
      phone_number.prefix = nil
      new_number_raw = '+1 (123) 456-7890'
      new_number = '1234567890'
      phone_number.number = new_number_raw
      phone_number.save!
      expect(phone_number.number).to eq(new_number)
      expect(phone_number.prefix).to eq('1')
    end

    it 'has a category' do
      expect(phone_number.category).to eq('cell')
      phone_number.category = 'home'
      phone_number.save!
      expect{
        phone_number.category = 'foobar'
      }.to raise_error(ArgumentError)
    end

    it 'has an availability' do
      expect(phone_number.availability).to eq('any')
      phone_number.availability = 'morning'
      phone_number.save!
      expect{
        phone_number.availability = 'foobar'
      }.to raise_error(ArgumentError)
    end

    it "has a unique name by phoneable association" do
      property1 = create(:property)
      property2 = create(:property)

      dup_name = 'Foobar 123'
      ok_name = 'Quux'
      ok_name2 = 'Acme'

      phone1_1 = create(:phone_number, name: dup_name, phoneable: property1)
      phone1_2 = create(:phone_number, name: ok_name, phoneable: property1)
      phone1_3 = build(:phone_number, name: dup_name, phoneable: property1)
      phone2_1 = build(:phone_number, name: dup_name, phoneable: property2)

      refute(phone1_3.valid?)
      assert(phone2_1.valid?)

      phone1_3.name = ok_name2
      assert(phone1_3.valid?)
    end

  end

  describe 'associations' do
    it 'belongs to a phoneable class' do
      phone_number.phoneable = create(:property)
      phone_number.save!
    end
  end

  describe 'instance methods' do
    it 'returns number variants' do
      phone_number.number = '(555) 555-1234'
      expect(phone_number.number_variants).to eq(['5555551234','15555551234'])
    end
  end

end
