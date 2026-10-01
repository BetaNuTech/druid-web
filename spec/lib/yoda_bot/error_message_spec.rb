require 'rails_helper'

RSpec.describe YodaBot::ErrorMessage do
  def build(message: "undefined method `code' for nil", data: nil)
    YodaBot::ErrorMessage.new(
      error_class: 'NoMethodError',
      message: message,
      location: 'app/models/lead.rb:42 in Lead#foo',
      origin: 'leads#show',
      data: data,
      host: 'www.blue-sky.app'
    )
  end

  it 'speaks like Yoda' do
    text = build(data: 'lead_id: 123').text(0)

    opening = text.lines.first.strip.delete_prefix('*').delete_suffix('*')
    expect(YodaBot::ErrorMessage::OPENINGS).to include(opening)
    expect(text).to include('`NoMethodError` in `leads#show`, there is.')
    expect(text).to include('Born at `app/models/lead.rb:42 in Lead#foo`, this error was.')
    expect(text).to include('Carried, this data was: _lead_id: 123_')
    expect(text).to include('From www.blue-sky.app, this comes.')
  end

  it 'reports repeats held back by the rate limit' do
    expect(build.text(1)).to include('Seen 1 more time since last I spoke')
    expect(build.text(37)).to include('Seen 37 more times since last I spoke')
    expect(build.text(0)).not_to include('Seen')
  end

  it 'leaves out lines it has nothing for' do
    text = YodaBot::ErrorMessage.new(error_class: 'StandardError', message: 'boom').text

    expect(text).to include('`StandardError`, there is.')
    expect(text).not_to include('Born at')
    expect(text).not_to include('Carried')
    expect(text).not_to include('this comes')
  end

  it 'an exception message cannot ping anyone or break the code block' do
    text = build(message: 'boom <!channel> <@U123> ``` & more').text(0)

    expect(text).not_to include('<!channel>')
    expect(text).not_to include('<@U123>')
    expect(text).to include('&lt;!channel&gt;')
    expect(text.scan('```').count).to eq(2)
  end
end
