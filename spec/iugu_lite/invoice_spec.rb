# frozen_string_literal: true

require 'pathname'
require 'spec_helper'

require_relative '../../lib/iugu_lite/invoice'

describe IuguLite::Invoice do
  let!(:root) { Pathname.pwd }

  context '.load' do
    it 'send request to iugu-lite and returns 5 invoices' do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with('invoices')
        .and_return(
          instance_double(
            Faraday::Response, status: 200,
                               body: JSON.parse(File.read(root.join('spec/fixtures/invoices.json')),
                                                symbolize_names: true)
          )
        )

      invoices = described_class.load
      expect(invoices.count).to eq 15
    end

    it 'if timout request raise error' do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .and_raise(Faraday::TimeoutError)

      expect do
        described_class.load
      end.to raise_error(Faraday::TimeoutError)
    end

    it 'if fail request raise error' do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .and_raise(Faraday::ConnectionFailed.new('expired'))

      expect do
        described_class.load
      end.to raise_error(Faraday::ConnectionFailed)
    end
  end

  context '.pending_invoices' do
    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with('invoices')
        .and_return(
          instance_double(
            Faraday::Response, status: 200,
                               body: JSON.parse(File.read(root.join('spec/fixtures/invoices.json')),
                                                symbolize_names: true)
          )
        )
    end

    it 'should returns pending invoices' do
      invoices = described_class.pending_invoices

      expect(invoices.count).to eq(15)
    end

    it 'should returns correct invoices values attributes' do
      expected_values = JSON.parse(File.read(root.join('spec/fixtures/invoices.json')),
                                   symbolize_names: true)

      invoices = described_class.pending_invoices

      invoices.each_with_index do |invoice, index|
        expect(invoice).to be_instance_of(IuguLite::Invoice)
        expect(invoice.token).to eq expected_values[index][:token]
        expect(invoice.payment_method).to eq expected_values[index][:payment_method]
        expect(invoice.due_date).to eq expected_values[index][:due_date]
        expect(invoice.amount).to eq expected_values[index][:amount]
        expect(invoice.status).to eq expected_values[index][:status]
      end
    end
  end
end
