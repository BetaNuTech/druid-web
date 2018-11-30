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
        debug = !['test', 'production'].include?(Rails.env)
        klass_name = name

        yaml_path ||= "#{Rails.root}/db/seeds/#{table_name}.yml"
        raise "Data not found: #{yaml_path}" unless File.exist?(yaml_path)

        msg =  "SEED DATA: #{klass_name} Loading #{yaml_path}"
        Rails.logger.info msg
        puts "*** #{msg}" if debug

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
                old_record.attributes = record
                data_changed = old_record.changed?
                if old_record.save
                  if data_changed
                    msg =  "SEED LOAD: Updated #{klass_name}[#{old_record.id}] : #{old_record.previous_changes}"
                    Rails.logger.info msg
                    puts "*** " + msg if debug
                    updated << {id: old_record.id, changes: old_record.previous_changes}
                  else
                    msg =  "SEED LOAD: No Change #{klass_name}[#{old_record.id}]"
                    Rails.logger.info msg
                    puts "*** " + msg if debug
                    noops << {id: old_record.id}
                  end
                else
                  msg =  "SEED LOAD: Error Updating #{klass_name}[#{old_record.id}] : #{old_record.errors.to_a}"
                  Rails.logger.info msg
                  puts "*** " + msg if debug
                  errors << {id: old_record.id, errors: old_record.errors.to_a}
                end
              else
                new_record = new(record)
                if new_record.save
                  msg =  "SEED LOAD: Created #{klass_name}[#{new_record.id}] : #{record}"
                  Rails.logger.info msg
                  puts "*** " + msg if debug
                  imported << {id: new_record.id, changes: new_record.previous_changes}
                else
                  msg =  "SEED LOAD: Error Creating #{klass_name}['#{record[key_attribute]}'] : #{new_record.errors.to_a}"
                  Rails.logger.info msg
                  puts "*** " + msg if debug
                  errors << {id: nil, errors: new_record.errors.to_a}
                end
              end
            end
          end
          msgs = [
            "SEED LOAD: Noop (#{noops.size}) #{noops.join("  ")}",
            "SEED LOAD: Imported(#{imported.size}) #{imported.join("  ")}",
            "SEED LOAD: Errors(#{errors.size}) #{errors.join("  ")}",
            "SEED LOAD: Updated(#{updated.size}) #{updated.join("  ")}"
          ]
          msgs.each do |msg|
            puts "*** " + msg if debug
            Rails.logger.info msg
          end
          return true
        rescue => e
          msg =  "SEED LOAD FAILED! Rolled back updates. Error: #{e} #{e.backtrace}"
          Rails.logger.info msg
          puts "*** " + msg if debug
          return false
        end

      end
    end
  end
end
