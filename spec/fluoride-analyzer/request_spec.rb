require 'fluoride-analyzer'

describe Fluoride::Analyzer::Request do

  describe 'serialization' do
    describe 'to yaml' do
      it 'should generate a hash view of the request'
    end
    describe 'from yaml' do
      it 'should generate a request from a hash'
    end
  end

  describe 'equality' do
    let :request_1 do
      Fluoride::Analyzer::Request.new.tap do |req|
        req.request_hash[:controller] = 'my_controller'
        req.request_hash[:action]     = 'my_action'
        req.request_hash[:method]     = :get
        req.request_hash[:params]     = {}
      end
    end
    let :request_2 do
      Fluoride::Analyzer::Request.new.tap do |req|
        req.request_hash[:controller] = 'my_controller'
        req.request_hash[:action]     = 'my_action'
        req.request_hash[:method]     = :get
        req.request_hash[:params]     = {}
      end
    end

    it 'different controllers should cause inequality' do
      request_2.request_hash[:controller] = 'other_controller'
      request_1.should hash_equivalently_to(request_2)
    end


    it 'different actions     should cause inequality' do
      request_2.request_hash[:controller] = 'other_controller'
      request_1.should hash_equivalently_to(request_2)
    end
    it 'different ids should still be equal'

    context 'with whitelisted params' do
      it 'different ids should still be equal'
      it 'different whitelist params should not be equal'
    end
  end

end

