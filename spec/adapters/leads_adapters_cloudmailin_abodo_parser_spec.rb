require 'rails_helper'

RSpec.describe Leads::Adapters::CloudMailin::AbodoParser do
  let(:email_plain) {
      <<-EOS
      You have an interested renter from ABODO!

Simply hit reply to respond to the renter
-------

*Name:* John Doe
*Email:*  johndoe@icloud.com <abodoleads+l1xl0dhexxxx@abodoapts.com>
*Phone Number:* 5555554444
*Student:* No

*In Regards to Property:* 1221 New Meister Lane
<https://mandrillapp.com/track/click/4608894/www.abodo.com?p=3DeyJzIjoiNGhq=
WExwMEpfZ3pnWkhzLW5jdjYyYmFFZWdrIiwidiI6MSwicCI6IntcInVcIjo0NjA4ODk0LFwidlw=
iOjEsXCJ1cmxcIjpcImh0dHA6XFxcL1xcXC93d3cuYWJvZG8uY29tXFxcL3BmbHVnZXJ2aWxsZS=
10eFxcXC9wcm9wZXJ0aWVzXFxcLzI4MjQyOTlcIixcImlkXCI6XCJhNTYwYWEzZGIxNzY0ZGRlY=
Tg4NTcxNmMwZmRiZTU3OFwiLFwidXJsX2lkc1wiOltcImIyMDQ5NjU3ZWEwNjFhMWY2ODI0NTMy=
ZTM5YjE4NDI1MmEzZTRjMTRcIl19In0>


Hi, I found your property on ABODO and would like to find out more
information. Please let me know when you are available for a viewing. Thank
you. Number of bedrooms: 2 Bedroom

-------

View Additional Information
<https://mandrillapp.com/track/click/4608894/www.abodo.com?p=3DeyJzIjoiZGdS=
SHF4ZjlLYkJveDdIOE1oVEpyTTBUV1prIiwidiI6MSwicCI6IntcInVcIjo0NjA4ODk0LFwidlw=
iOjEsXCJ1cmxcIjpcImh0dHA6XFxcL1xcXC93d3cuYWJvZG8uY29tXFxcL2xhbmRsb3Jkc1xcXC=
84MDgzMlxcXC9sZWFkLWluc2lnaHRzXFxcLzExNzYzNjRcIixcImlkXCI6XCJhNTYwYWEzZGIxN=
zY0ZGRlYTg4NTcxNmMwZmRiZTU3OFwiLFwidXJsX2lkc1wiOltcIjY5ZTY5ZDk0ODI4Mjg0MzNj=
YjFlM2IyZjU0MjZmNTZjZGYwMmUyM2JcIl19In0>

-------

Thank you for being a loyal ABODO customer. If you have any feedback,
suggestions or praise, we=E2=80=99d love to hear from you!

And, if you are looking for new opportunities to gain more exposure to
renters in Pflugerville and generate more leads, contact your sales
executive or call us at (800) 488-0074.
Thanks,

The ABODO Team
info@abodo.com

p.s. Responding to a lead in five minutes instead of thirty makes it 2.5x
more likely you'll get their business.
EOS
  }

  let(:email_data) {
    {
      plain: email_plain,
      html: '',
      headers: { 'Message-ID' => 'Message12345' }
    }
  }

  describe "parsing email data" do
    it "should parse the data" do
      adapter = Leads::Adapters::CloudMailin::AbodoParser

      result = adapter.parse(email_data)
      ap result
      expect(result[:title]).to eq(nil)
      expect(result[:first_name]).to eq('John')
      expect(result[:last_name]).to eq('Doe')
      expect(result[:email]).to eq('johndoe@icloud.com')
      expect(result[:phone1]).to eq('5555554444')
      expect(result[:preference_attributes][:notes]).to match(/I found your property/)
      expect(result[:preference_attributes][:notes]).to match(/2 Bedroom/)
      expect(result[:notes]).to match(/Message-ID: Message12345/)

    end
  end
end
