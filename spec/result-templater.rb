require 'fluoride-analyzer/request-templater'

describe Fluoride::Analyzer::RequestTemplater do
  let :template_string do
    <<-EOT
require 'spec_helper'

describe '<%= pattern %>' do
<% param_fields.each do |field| %>
  let :<%= field %> do
    FactoryGirl.create(:<%= field %>).id
  end
<%end%>
<% each_status_group do |group| %>

  # HTTP status code: <%= group.status_code %> <%= group.status_description %>
  # <%= group.request_count %> cases recorded by Fluoride
  # See example: '<%= group.example_source %>'
  #   example path: <%= group.example_path %>
  describe '<%= group.request_spec_description %>' do
    it "should <%= group.should_what %>" do
      <%= group.test_request(6) %>
<% group.test_result.each do |test_result_line| %>
      <%= test_result_line %>
<% end %>
    end
  end
<%end%>
end
    EOT
  end

  let :results do
    YAML.load(File.read(File.expand_path("../../spec-help/fixtures/results.yml", __FILE__)))
  end

  let :templater do
    Fluoride::Analyzer::RequestTemplater.new.tap do |tmplr|
      tmplr.template_string = template_string
      tmplr.results = results
    end
  end

  let :templated_list do
    templated_list = []
    templater.go do |path, contents|
      templated_list << [path, contents]
    end
    templated_list
  end

  let :paths do
    templated_list.map{|path, _| path}
  end

  let :contents do
    templated_list.map{|_, contents| contents}
  end

  it "should template once per result" do
    expect(templated_list.length).to eq(results.keys.length)
  end

  it "should put the right stuff in contents" do
    expect(contents).to all(match(/HTTP status code:/))
  end
end
