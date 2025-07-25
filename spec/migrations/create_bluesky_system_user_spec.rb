require 'rails_helper'
require_migration 'create_bluesky_system_user'

RSpec.describe CreateBlueskySystemUser do
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      # Ensure we have the system_user column
      unless ActiveRecord::Base.connection.column_exists?(:users, :system_user)
        ActiveRecord::Base.connection.add_column :users, :system_user, :boolean, default: false
      end
      
      # Ensure administrator role exists
      Role.find_or_create_by!(name: 'Administrator', slug: 'administrator')
    end

    context 'when system user does not exist' do
      before do
        User.where(email: 'system@bluesky.internal').destroy_all
      end

      it 'creates the system user' do
        expect { migration.up }.to change { User.count }.by(1)
        
        system_user = User.find_by(email: 'system@bluesky.internal')
        expect(system_user).to be_present
        expect(system_user.system_user).to be true
        expect(system_user.confirmed_at).to be_present
        expect(system_user.role.name).to eq('Administrator')
      end

      it 'creates the user profile with Bluesky as first name' do
        migration.up
        
        system_user = User.find_by(email: 'system@bluesky.internal')
        expect(system_user.profile).to be_present
        expect(system_user.profile.first_name).to eq('Bluesky')
        expect(system_user.profile.last_name).to be_nil
      end
    end

    context 'when system user already exists' do
      let!(:existing_user) do
        User.create!(
          email: 'system@bluesky.internal',
          password: 'existing_password',
          role: Role.find_by(name: 'Administrator'),
          confirmed_at: 1.day.ago
        )
      end

      it 'updates the existing user to be a system user' do
        expect { migration.up }.not_to change { User.count }
        
        existing_user.reload
        expect(existing_user.system_user).to be true
      end

      it 'creates or updates the profile' do
        migration.up
        
        existing_user.reload
        expect(existing_user.profile).to be_present
        expect(existing_user.profile.first_name).to eq('Bluesky')
      end
    end

    context 'when system user exists with a different profile' do
      let!(:existing_user) do
        user = User.create!(
          email: 'system@bluesky.internal',
          password: 'existing_password',
          role: Role.find_by(name: 'Administrator'),
          confirmed_at: 1.day.ago
        )
        user.create_profile!(first_name: 'Old', last_name: 'Name')
        user
      end

      it 'updates the profile to Bluesky' do
        migration.up
        
        existing_user.reload
        expect(existing_user.profile.first_name).to eq('Bluesky')
        expect(existing_user.profile.last_name).to be_nil
      end
    end
  end

  describe '#down' do
    before do
      # Ensure system user exists
      migration.up
    end

    it 'removes the system user' do
      expect(User.find_by(email: 'system@bluesky.internal')).to be_present
      
      expect { migration.down }.to change { User.count }.by(-1)
      
      expect(User.find_by(email: 'system@bluesky.internal')).to be_nil
    end

    it 'removes the associated profile' do
      system_user = User.find_by(email: 'system@bluesky.internal')
      profile_id = system_user.profile.id
      
      migration.down
      
      expect(UserProfile.find_by(id: profile_id)).to be_nil
    end
  end
end