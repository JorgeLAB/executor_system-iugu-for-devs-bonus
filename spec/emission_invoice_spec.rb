# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/invoice_executor_system/executor_system'
require_relative '../lib/iugu_lite/invoice'

describe ExecutorSystem::EmissionInvoice do
  let(:root) { Pathname.pwd }

  before do
    allow_any_instance_of(Faraday::Connection).to receive(:get)
      .with('company_payment_methods')
      .and_return(
        instance_double(
          Faraday::Response, status: 200,
                             body: JSON.parse(File.read(root.join('spec/fixtures/company_payment_methods.json')),
                                              symbolize_names: true)
        )
      )

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

  context '.create' do
    it 'should returns emission invoice with valid invoice' do
      invoice = IuguLite::Invoice.new(
        token: '5315babefff775cf77fd',
        payment_method: 'token_boleto',
        due_date: 1.days.from_now.strftime('%F'),
        amount: 1000,
        status: 'pending'
      )

      emission_invoice = described_class.create(invoice)

      expect(emission_invoice).to be_instance_of(ExecutorSystem::EmissionInvoice)
      expect(emission_invoice.token).to eq '5315babefff775cf77fd'
      expect(emission_invoice.payment_method).to eq 'Boleto'
      expect(emission_invoice.due_date).to  eq 1.days.from_now.strftime('%F').gsub('-', '')
      expect(emission_invoice.amount).to eq '0000100000'
      expect(emission_invoice.status).to eq '01'
    end
  end

  context '.create_emissions' do
    it 'should returns array with emission invoices' do
      pending_invoices = IuguLite::Invoice.pending_invoices

      emission_invoices = described_class.create_emissions(pending_invoices)

      expected_values = JSON.parse(File.read(root.join('spec/fixtures/invoices.json')),
                                   symbolize_names: true)

      emission_invoices.each_with_index do |invoice, index|
        expect(invoice).to be_instance_of(ExecutorSystem::EmissionInvoice)
        expect(invoice.token).to eq expected_values[index][:token]
        expect(invoice.payment_method).to eq 'Boleto'
        expect(invoice.due_date).to eq expected_values[index][:due_date].gsub('-', '')
        expect(invoice.amount).to eq format('%010d', (expected_values[index][:amount] * 100))
        expect(invoice.status).to eq '01'
      end
    end
  end

  context '.payment_method_separate' do
    let!(:emission_invoices) do
      emission_invoices = []

      20.times do
        emission_invoices << described_class
                             .new(
                               token: SecureRandom.hex(10),
                               payment_method: ['Boleto', 'Card', 'PIX'].sample,
                               due_date: 1.days.from_now.strftime('%Y%M%d'),
                               amount: "0000#{rand(9)}00000",
                               status: '01'
                             )
      end

      emission_invoices
    end

    it 'should separate the emission invoices by payment method' do

      expected_emission_invoice = { 'Boleto': [], 'Card': [], 'PIX': [] }

      emission_invoices.each do |invoice|
        expected_emission_invoice[invoice.payment_method.to_sym] << invoice
      end

      emission_invoices_separate = described_class.payment_method_separate(emission_invoices)

      expect(emission_invoices_separate).to eq(expected_emission_invoice)
    end
  end
end
