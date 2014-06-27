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
    it 'different controllers should cause inequality'
    it 'different actions     should cause inequality'
    it 'different ids should still be equal'

    context 'with whitelisted params' do
      it 'different ids should still be equal'
      it 'different whitelist params should not be equal'
    end
  end

end

