# frozen_string_literal: true

require 'pathname'
require 'spec_helper'

require_relative '../lib/iugu_lite/pay_type'

describe IuguLite::PayType do
  let(:root) { Pathname.pwd }

  context '.all' do
    it 'send request to iugu-lite to get all paytypes' do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with('company_payment_methods')
        .and_return(
          instance_double(
            Faraday::Response, status: 200,
                               body: JSON.parse(File.read(root.join('spec/fixtures/company_payment_methods.json')),
                                                symbolize_names: true)
          )
        )

      pay_types = described_class.all
      expect(pay_types.count).to eq 3
    end

    it 'if timout request raise error' do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .and_raise(Faraday::TimeoutError)

      expect do
        described_class.all
      end.to raise_error(Faraday::TimeoutError)
    end

    it 'if fail request raise error' do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .and_raise(Faraday::ConnectionFailed.new('expired'))

      expect do
        described_class.all
      end.to raise_error(Faraday::ConnectionFailed)
    end
  end

  context '.search_name' do
    it 'should return name with token valid' do
      allow_any_instance_of(Faraday::Connection).to receive(:get)
        .with('company_payment_methods')
        .and_return(
          instance_double(
            Faraday::Response, status: 200,
                               body: JSON.parse(File.read(root.join('spec/fixtures/company_payment_methods.json')),
                                                symbolize_names: true)
          )
        )

      paytype_name = described_class.search_name("token_boleto")

      expect(paytype_name).to eq 'Boleto'
    end
  end
end
