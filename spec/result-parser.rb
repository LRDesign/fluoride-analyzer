require 'action_controller/railtie'
require 'fluoride-analyzer/parser'

describe Fluoride::Analyzer::Parser do
  def config(app)
    app.routes.draw do
      get "/", :to => 'root#index', :as => :root
    end
  end

  let! :rails_application do
    Class.new(::Rails::Application).tap do |app|
      app.configure do
        config.active_support.deprecation = :stderr
        config.eager_load = false
      end
      config(app)
      app.initialize!
    end
  end

  after :each do
    Rails.application = nil
  end

  let :requests_stream do
    YAML::dump_stream(*requests)
  end

  let :parser do
    Fluoride::Analyzer::Parser.new.tap do |parser|
      parser.parse_stream("test-file.yaml", requests_stream)
    end
  end

  let :results do
    parser.formatted_results
  end

  let :requests do
    [
      {"type"=>"normal_exchange",
      "tags"=>nil,
      "request"=>
       {"query_string"=>"",
        "body"=>"",
        "method"=>"GET",
        "accept"=>
         "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "content_type"=>nil,
        "user_agent"=>
         "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36",
        "referer"=>nil,
        "host"=>"0.0.0.0:3000",
        "authorization"=>nil,
        "cookies"=>nil,
        "path"=>"/",
        "accept_encoding"=>"gzip,deflate,sdch"},
      "response"=>
       {"body"=>
         ["<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n\n<!--\n\tsomebody@gmail.com june 2014\n-->\n\n\t<meta charset=\"utf-8\" />\n\t<title>Application</title>\n\t<meta name=\"viewport\" content=\"width=device-width, initial-sc"],
        "status"=>200,
        "headers"=>
         {"Content-Type"=>"text/html; charset=utf-8",
          "ETag"=>"\"5ff1d9c9172424e5d906216dcdacd9ef\"",
          "X-UA-Compatible"=>"IE=Edge,chrome=1",
          "Cache-Control"=>"max-age=0, private, must-revalidate",
          "X-Runtime"=>"0.873536"}}
    },

     {"type"=>"normal_exchange",
      "tags"=>nil,
      "request"=>
       {"query_string"=>"",
        "body"=>"",
        "method"=>"GET",
        "accept"=>"text/css,*/*;q=0.1",
        "content_type"=>nil,
        "user_agent"=>
         "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/34.0.1847.116 Safari/537.36",
        "referer"=>"http://0.0.0.0:3000/",
        "host"=>"0.0.0.0:3000",
        "authorization"=>nil,
        "cookies"=>nil,
        "path"=>"/stylesheets/2014-bootstrap.css",
        "accept_encoding"=>"gzip,deflate,sdch"},
      "response"=>
       {"body"=>
         ["/*! normalize.css v3.0.0 | MIT License | git.io/normalize */\nhtml {\n  font-family: sans-serif;\n  -ms-text-size-adjust: 100%;\n  -webkit-text-size-adjust: 100%; }\n\nbody {\n  margin: 0; }\n\narticle,\naside,\n"],
        "status"=>200,
        "headers"=>
         {"Content-Length"=>"15835",
          "Content-Type"=>"text/css",
          "Last-Modified"=>"Sun, 29 Jun 2014 00:00:48 GMT"}},
    }
    ]
  end

  it "should have excluded 1 request" do
    expect(parser.counts[:excluded]).to eq(1)
  end

  it "should have 0 unrecognized requests" do
    expect(parser.counts[:excluded]).to eq(1)
  end

  it "should be a well formatted version of the results" do
    expect(results).to match("/" => {"GET" => {200 => match([ a_hash_including("path" => "/") ])}})
  end
end
