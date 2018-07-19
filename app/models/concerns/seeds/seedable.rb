module Seeds
  module Seedable
    extend ActiveSupport::Concern

    class_methods do
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
        klass_name = name

        yaml_path ||= "#{Rails.root}/db/seeds/#{table_name}.yml"
        raise "Data not found: #{yaml_path}" unless File.exist?(yaml_path)

        msg =  "SEED DATA: Loading #{yaml_path}"
        Rails.logger.info msg

        seed_data = YAML.load(ERB.new(File.read(yaml_path)).result)
        data_description = seed_data.fetch(table_name.to_sym, {data:[]})
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
              if (old_record = where(key_attribute => record.fetch(key_attribute)).first).present?
                if old_record.update_attributes(record)
                  if old_record.changed?
                    msg =  "SEED LOAD: Updated #{klass_name}[#{old_record.id}] : #{old_record.previous_changes}"
                    Rails.logger.info msg
                    updated << {id: old_record.id, changes: old_record.previous_changes}
                  else
                    msg =  "SEED LOAD: No Change #{klass_name}[#{old_record.id}]"
                    Rails.logger.info msg
                    noops << {id: old_record.id}
                  end
                else
                  msg =  "SEED LOAD: Error Updating #{klass_name}[#{old_record.id}] : #{old_record.errors.to_a}"
                  puts msg
                  Rails.logger.info msg
                  errors << {id: old_record.id, errors: old_record.errors.to_a}
                end
              else
                new_record = new(record)
                if new_record.save
                  msg =  "SEED LOAD: Created #{klass_name}[#{new_record.id}] : #{record}"
                  puts msg
                  Rails.logger.info msg
                  imported << {id: new_record.id, changes: new_record.previous_changes}
                else
                  msg =  "SEED LOAD: Error Creating #{klass_name}['#{record[key_attribute]}'] : #{new_record.errors.to_a}"
                  puts msg
                  Rails.logger.info msg
                  errors << {id: nil, errors: new_record.errors.to_a}
                end
              end
            end
          end
          msgs = [
            "SEED LOAD: Noop (#{noops.size}) #{noops.join("\n")}",
            "SEED LOAD: Imported(#{imported.size}) #{imported.join("\n")}",
            "SEED LOAD: Errors(#{errors.size}) #{errors.join("\n")}",
            "SEED LOAD: Updated(#{updated.size}) #{updated.join("\n")}"
          ]
          msgs.each do |msg|
            puts msg
            Rails.logger.info msg
          end
          return true
        rescue => e
          msg =  "SEED LOAD FAILED! Rolled back updates. Error: #{e} #{e.backtrace}"
          Rails.logger.info msg
          return false
        end

      end
    end
  end
end
