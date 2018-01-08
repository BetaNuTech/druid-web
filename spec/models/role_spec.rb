require 'rails_helper'

RSpec.describe Role, type: :model do
  it "can be initialized" do
    role = build(:role)
  end

  it "can be saved" do
    role = build(:role)
    assert role.save
  end

  it "can be updated" do
    new_name = 'foobar'
    role = create(:role)
    role.reload
    expect(role.name).to_not eq(new_name)
    role.name = new_name
    assert role.save
    expect(role.name).to eq(new_name)
  end

  it "must have a name" do
    role = build(:role)
    assert role.save
    role.name = nil
    refute role.save
  end

  it "must have a slug" do
    role = build(:role)
    assert role.save
    role.slug = nil
    refute role.save
  end

end
