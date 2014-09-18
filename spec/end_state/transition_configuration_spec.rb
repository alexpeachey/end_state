require 'spec_helper'
require 'ostruct'

module EndState
  describe Transition do
    subject(:config) { TransitionConfiguration.new }

    describe '#custom_action' do
      let(:custom) { double :custom }

      it 'sets the action' do
        config.custom_action custom
        expect(config.action).to eq custom
      end
    end

    describe '#blocked' do
      it 'sets the blocked event message' do
        config.blocked 'This is blocked.'
        expect(config.blocked_event_message).to eq 'This is blocked.'
      end
    end

    describe '#guard' do
      let(:guard) { double :guard }
      let(:another_guard) { double :another_guard }

      it 'adds a guard' do
        expect { config.guard guard }.to change(config.guards, :count).by(1)
      end

      it 'adds multiple guards' do
        expect { config.guard guard, another_guard }.to change(config.guards, :count).by(2)
      end
    end

    describe '#concluder' do
      let(:concluder) { double :concluder }
      let(:another_concluder) { double :another_concluder }

      it 'adds a concluder' do
        expect { config.concluder concluder }.to change(config.concluders, :count).by(1)
      end

      it 'adds multiple concluders' do
        expect { config.concluder concluder, another_concluder }.to change(config.concluders, :count).by(2)
      end
    end

    describe '#persistence_on' do
      it 'adds a Persistence concluder' do
        expect { config.persistence_on }.to change(config.concluders, :count).by(1)
      end
    end

    describe '#allow_params' do
      it 'adds supplied keys to the allowed_params array' do
        expect { config.allow_params :foo, :bar }.to change(config.allowed_params, :count).by(2)
      end
    end

    describe '#require_params' do
      it 'adds supplied keys to the required_params array' do
        expect { config.require_params :foo, :bar }.to change(config.required_params, :count).by(2)
      end

      it 'adds supplied keys to the allowed_params array' do
        expect { config.allow_params :foo, :bar }.to change(config.allowed_params, :count).by(2)
      end
    end
  end
end
