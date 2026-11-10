# frozen_string_literal: true

# Coder for the attributes that were declared with a bare `serialize :name` on
# a jsonb column (Property#appsettings, UserProfile#appsettings,
# UserProfile#enabled_features).
#
# A bare `serialize` uses YAML, so saving writes a YAML document into the
# column as a JSON string. Rows that were never saved through the model still
# hold the column default, a JSON object. Up to Rails 7.0 the YAML coder
# returned anything that was not a YAML string untouched; Rails 7.1 passes it
# to the YAML parser, which raises on a Hash. This keeps the old behaviour so
# both kinds of row keep loading and nothing has to be migrated.
#
# See doc/rails_upgrade_plan.md.
class YamlInJsonbCoder
  YAML_DOCUMENT_START = '---'

  def self.load(value)
    return value unless value.is_a?(String) && value.start_with?(YAML_DOCUMENT_START)

    YAML.unsafe_load(value)
  end

  def self.dump(value)
    return if value.nil?

    YAML.dump(value)
  end
end
