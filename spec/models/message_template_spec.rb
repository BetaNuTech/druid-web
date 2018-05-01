require 'rails_helper'

RSpec.describe MessageTemplate, type: :model do
  it "can be initialized" do
    assert(create(:message_template).valid?)
  end

  describe :validations do
    let(:message_template) { create(:message_template)}

    it "requires a name" do
      assert message_template.valid?
      message_template.name = nil
      refute message_template.valid?
    end
    it "requires a subject" do
      assert message_template.valid?
      message_template.subject = nil
      refute message_template.valid?
    end
    it "requires a body" do
      assert message_template.valid?
      message_template.body = nil
      refute message_template.valid?
    end
    it "has an optional user" do
      assert message_template.valid?
      message_template.user = nil
      assert message_template.valid?
    end
    it "has a message_type" do
      assert message_template.valid?
      message_template.message_type = nil
      refute message_template.valid?
    end
  end

  describe "rendering a template" do
    let(:template_subject_string) { "Subject {{user}}. ID: {{id}}" }
    let(:template_body_string) { "Body {{user}}. ID: {{id}}" }
    let(:message_template) {
      create(:message_template,
             name: 'Test',
             subject: template_subject_string,
             body: template_body_string)
    }
    let(:invalid_body_message_template) {
      create(:message_template,
             name: 'Test',
             subject: template_subject_string,
             body: "{{foobar")
    }
    let(:invalid_subject_message_template) {
      create(:message_template,
             name: 'Test',
             subject: "{{foobar",
             body: template_body_string)
    }
    let(:template_data) { {'user' => 'JohnSmith', 'id' => 42}}

    it "renders the template subject with variable substitution" do
      output = message_template.render(template_data)
      refute output.errors?
      expect(output.subject).to eq("Subject JohnSmith. ID: 42")
    end

    it "renders the template body with variable substitution" do
      output = message_template.render(template_data)
      refute output.errors?
      expect(output.body).to eq("Body JohnSmith. ID: 42")
    end

    it "returns errors in the body template" do
      output = invalid_body_message_template.render(template_data)
      assert output.errors?
      expect(output.errors.body.first).to match("MessageTemplate Rendering Error")
    end

    it "returns errors in the subject template" do
      output = invalid_subject_message_template.render(template_data)
      assert output.errors?
      expect(output.errors.subject.first).to match("MessageTemplate Rendering Error")
    end

    it "handles missing template data gracefully" do
      output = message_template.render({'id' => 42}) # missing user
      refute output.errors?
      expect(output.subject).to eq("Subject . ID: 42")
    end
  end

end
