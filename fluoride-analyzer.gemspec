Gem::Specification.new do |spec|
  spec.name		= "fluoride-analyzer"
  spec.version		= "0.0.8"
  author_list = {
    "Judson Lester" => 'judson@lrdesign.com',
    "Evan Down" => 'evan@lrdesign.com',
    "Patricia Ho" => "patricia@lrdesign.com"
  }
  spec.authors		= author_list.keys
  spec.email		= spec.authors.map {|name| author_list[name]}
  spec.summary		= "Analysis of recorded requests "
  spec.description	= <<-EndDescription
  Part of the Fluoride suite - tools for making your black box a bit whiter
  EndDescription

  spec.homepage        = "http://github.com/lrdesign/#{spec.name.downcase}"
  spec.required_rubygems_version = Gem::Requirement.new(">= 0") if spec.respond_to? :required_rubygems_version=

  # Do this: y$@"
  # !!find lib bin doc spec spec_help -not -regex '.*\.sw.' -type f 2>/dev/null
  spec.files		= %w[
    lib/fluoride-analyzer/parser.rb
    lib/fluoride-analyzer/patterner.rb
    lib/fluoride-analyzer/exception-result.rb
    lib/fluoride-analyzer/rails/railtie.rb
    lib/fluoride-analyzer/group-context.rb
    lib/fluoride-analyzer/config.rb
    lib/fluoride-analyzer/request-templater.rb
    lib/fluoride-analyzer/group-collapser.rb
    lib/fluoride-analyzer/rails.rb
    lib/fluoride-analyzer/pattern-collapser.rb
    lib/fluoride-analyzer/request.rb
    lib/fluoride-analyzer/tasklib.rb
    lib/fluoride-analyzer/result-collection.rb
    lib/fluoride-analyzer/request-processor.rb
    lib/fluoride-analyzer/pattern-context.rb
    lib/fluoride-analyzer/exchange-result.rb
    lib/fluoride-analyzer.rb
    default_config/templates/request_spec.erb
    spec/result-templater.rb
    spec/railtie_spec.rb
    spec/result-parser.rb
  ]

  spec.test_file        = "spec-help/gem-test-suite.rb"
  spec.licenses = ["MIT"]
  spec.require_paths = %w[lib/]
  spec.rubygems_version = "1.3.5"

  spec.has_rdoc		= true
  spec.extra_rdoc_files = Dir.glob("doc/**/*")
  spec.rdoc_options	= %w{--inline-source }
  spec.rdoc_options	+= %w{--main doc/README }
  spec.rdoc_options	+= ["--title", "#{spec.name}-#{spec.version} Documentation"]

  spec.add_dependency("mattock", "> 0")
  spec.add_dependency("valise", "> 0")

  #spec.post_install_message = "Thanks for installing my gem!"
end
