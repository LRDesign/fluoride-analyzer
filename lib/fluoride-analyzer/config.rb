module Fluoride::Analyzer
  class Config
    require 'yaml'
    include Singleton

    CONFIG_FILE = '.fluoride.yml'
    DEFAULT_EXCLUDE_PATHS      = [ %r[^/images], %r[^/stylesheets], %r[^/javascripts], %r[^/system],  ]
    DEFAULT_EXCLUDE_MIME_TYPES =   [ %r[image], %r[text/css], %r[javascript], %r[shockwave] ]

    attr_accessor :exclude_path_patterns,
                  :exclude_mime_types,
                  :match_on_required_params,
                  :exclude_match_params,
                  :limit_count


    def self.initialize()
      yaml_config = YAML::load(File.open(CONFIG_FILE))
      self.exclude_path_patterns = DEFAULT_EXCLUDE_PATHS
                                   + yaml_config['exclude_path_patterns']
                                   - yaml_config['include_path_patterns']

      self.exclude_mime_types    = DEFAULT_EXCLUDE_MIME_TYPES
                                   + yaml_config['exclude_mime_types']
                                   - yaml_config['include_mime_types']


      if yaml_config.has_key?('match_on_required_params')
        self.match_on_required_params = yaml_config['match_on_required_params']
      else
        self.match_on_required_params = false
      end

      self.exclude_match_params = yaml_config['exclude_match_params'] || []
      self.include_match_params = yaml_config['include_match_params'] || []
      self.limit_count          = yaml_config['limit_count']
    end
  end
end

