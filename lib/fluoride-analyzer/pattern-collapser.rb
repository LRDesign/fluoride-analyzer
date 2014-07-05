module Fluoride::Analyzer
  class PatternCollapser
    def initialize(pattern, methods_hash)
      @pattern = pattern
      @methods_hash = methods_hash
    end

    def erase_list
      %w{ format }
    end

    def pattern
      erase_list.inject(@pattern) do |pattern, erase|
        pattern.sub(/\(.:#{erase}\)/,'')
      end
    end

    def param_letname_map
      { :id => :model_id }
    end

    def params_fields
      @methods_hash.values.first.values.first.first['path_params'].keys.reject do |key|
        key == :format
      end.map do |name|
        param_letname_map.fetch(name, name)
      end
    end
  end
end
