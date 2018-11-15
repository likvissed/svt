require 'feature_helper'

RSpec.describe Statistics, type: :model do
  context 'when type is "ups_battery"' do
    let(:type) { 'ups_battery' }
    let(:ups_battery) { Invent::Statistics::UpsBattery.new }

    it 'should be truthy' do
      expect(subject.run(type)).to be_truthy
    end

    it 'creates instance of Invent::Statistics::UpsBattery' do
      expect(Invent::Statistics::UpsBattery).to receive(:new).and_return(ups_battery)
      subject.run(type)
    end
  end

  context 'when unknown type' do
    let(:type) { 'unknown' }

    it 'should be falsey' do
      expect(subject.run(type)).to be_falsey
    end
  end
end
