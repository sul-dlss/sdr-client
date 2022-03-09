# frozen_string_literal: true

# Provides RSpec matchers for Cocina models
module CocinaMatchers
  extend RSpec::Matchers::DSL

  # NOTE: each k/v pair in the hash passed to this matcher will need to be present in actual
  matcher :cocina_object_with do |**kwargs|
    kwargs.each do |cocina_section, expected|
      match do |actual|
        expected.all? do |expected_key, expected_value|
          # NOTE: there's no better method on Hash that I could find for this.
          #        #include? and #member? only check keys, not k/v pairs
          actual.public_send(cocina_section).to_h.any? do |actual_key, actual_value|
            if expected_value.is_a?(Hash) && actual_value.is_a?(Hash)
              expected_value.all? { |pair| actual_value.to_a.include?(pair) }
            else
              actual_key == expected_key && actual_value == expected_value
            end
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include CocinaMatchers
end
