require 'fluoride-analyzer'

module Fluoride::Analyzer

  describe RequestProcessor do
    let :request_parser do
      RequestProcessor.new(config)
    end
    let :config do
      Config.new(config_options)
    end
    let :base_config do
      { }
    end


    # method that returns a hash containing the unique things about this
    # route, as controlled by config
    describe 'route_key' do
      let :route_key do
        RequestProcessor.route_key(path, method)
      end

      describe 'when required params are not matched' do
        let :config_options do
          base_config.merge({ :match_on_required_params => false})
        end

        it "should not have id" do
          route_key[:params].should be_nil
        end
        it "should have controller" do
          route_key[:controller].should == controller_name
        end
        it "should have action" do
          route_key[:action].should == action_name
        end
      end

      describe 'when params are matched but some are excluded' do
        let :config_options do
          base_config.merge({ :match_on_required_params => true,
                              :exclude_match_params => [ :id ]
          })
        end
      end

    end
  end
end
