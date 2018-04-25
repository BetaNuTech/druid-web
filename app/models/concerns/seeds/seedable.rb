module Seeds
  module Seedable

    # Example YAML data
    #
    #   ---
    #   :lead_actions:
    #     :version: 1
    #     :key: :name
    #     :data:
    #     - :name: Claim Lead
    #       :description: Claim a new/open Lead
    #       :active: true
    #     - :name: First Contact
    #       :description: Contact Lead for the first time (Phone/SMS/Email)
    #       :active: true

    def load_seed_data(yaml_path=nil)
      klass_name = class_name

      yaml_path ||= "#{Rails.root}/db/seeds/#{self.table_name}.yml"
      raise "Data not found: #{yaml_path}" unless File.exist?(yaml_path)

      Rails.logger.info "SEED DATA: Loading #{yaml_path}"

      seed_data = YAML.load(File.read(yaml_path))
      data_description = seed_data.fetch(self.table_name.to_sym, {data:[]})
      key_attribute = data_description.fetch(:key, :name)
      data = data_description.fetch(:data)
      raise "Seed data empty: #{yaml_path}" if data.empty?

      imported = []
      noops = []
      updated = []
      errors = []

      begin
        transaction do
          data.each do |record|
            if (old_record = self.where(key_attribute => record.fetch(key_attribute)).first).present?
              if old_record.update_attributes(record)
                if old_record.changed?
                  Rails.logger.info "SEED LOAD: Updated #{klass_name}[#{old_record.id}] : #{old_record.previous_changes}"
                  updated << {id: old_record.id, changes: old_record.previous_changes}
                else
                  Rails.logger.info "SEED LOAD: No Change #{klass_name}[#{old_record.id}]"
                  noops << {id: old_record.id}
                end
              else
                Rails.logger.info "SEED LOAD: Error Updating #{klass_name}[#{old_record.id}] : #{old_record.errors.to_a}"
                errors << {id: old_record.id, errors: old_record.errors.to_a}
              end
            else
              new_record = self.new(record)
              if new_record.save
                Rails.logger.info "SEED LOAD: Created #{klass_name}[#{new_record.id}] : #{record}"
                imported << {id: new_record.id, changes: new_record.previous_changes}
              else
                Rails.logger.info "SEED LOAD: Error Creating #{klass_name}[}] : #{new_record.errors.to_a}"
                errors << {id: nil, errors: old_record.errors.to_a}
              end
            end
          end
        end
        Rails.logger.info "SEED LOAD: Noop (#{noops.size}) #{noops.join("\n")}"
        Rails.logger.info "SEED LOAD: Imported(#{imported.size}) #{imported.join("\n")}"
        Rails.logger.info "SEED LOAD: Updated(#{updated.size}) #{updated.join("\n")}"
        Rails.logger.info "SEED LOAD: Errors(#{errors.size}) #{errors.join("\n")}"
        return true
      rescue => e
        Rails.logger.info "SEED LOAD FAILED! Rolled back updates. Error: #{e} #{e.backtrace}"
        return false
      end

    end
  end
end
