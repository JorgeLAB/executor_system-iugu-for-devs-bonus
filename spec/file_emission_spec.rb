# frozen_string_literal: true

require 'spec_helper'

require_relative '../lib/invoice_executor_system/executor_system'
require_relative '../lib/iugu_lite/invoice'

describe ExecutorSystem::FileEmission do

  before do
    @root = Pathname.pwd

    allow_any_instance_of(Faraday::Connection).to receive(:get)
      .with('company_payment_methods')
      .and_return(
        instance_double(
          Faraday::Response, status: 200,
                             body: JSON.parse(File.read(@root.join('spec/fixtures/company_payment_methods.json')),
                                              symbolize_names: true)
        )
      )

    allow_any_instance_of(Faraday::Connection).to receive(:post)
        .with('invoices')
        .and_return(
          instance_double(
            Faraday::Response, status: 200,
                               body: JSON.parse(File.read(@root.join('spec/fixtures/invoices.json')),
                                                symbolize_names: true)
          )
        )
  end

  context '.create' do
    let!(:root) { Pathname.pwd }

    before(:each) do
      timestamp = Time.now.strftime('%Y%M%d')
      invoice_method = 'BOLETO'
      @filename = root.join('db', 'emissions', "#{timestamp}_#{invoice_method}_EMISSAO.txt")
    end

    after(:each) do
      File.delete(@filename)
    end

    it 'should create a emission file' do
      emission_invoice = ExecutorSystem::EmissionInvoice
                         .new(
                           token: '5315babefff775cf77fd',
                           payment_method: 'Boleto',
                           due_date: 1.days.from_now.strftime('%Y%M%d'),
                           amount: '0000100000',
                           status: '01'
                         )

      described_class.create(@filename,[emission_invoice])

      expect(File).to exist(@filename)
    end

    it 'should have correct values in header' do
      emission_invoice = ExecutorSystem::EmissionInvoice
                         .new(
                           token: '5315babefff775cf77fd',
                           payment_method: 'Boleto',
                           due_date: 1.days.from_now.strftime('%Y%M%d'),
                           amount: '0000100000',
                           status: '01'
                         )

      total_invoices = '00001'
      emission_invoice_header = "H #{total_invoices}\n"

      described_class.create(@filename,[emission_invoice])

      file = File.open(@filename)
      header = file.readlines.first
      file.close

      expect(header).to eq(emission_invoice_header)
    end

    it 'should have correct values in body' do
      emission_invoice = ExecutorSystem::EmissionInvoice
                         .new(
                           token: '5315babefff775cf77fd',
                           payment_method: 'Boleto',
                           due_date: 1.days.from_now.strftime('%Y%M%d'),
                           amount: '0000100000',
                           status: '01'
                         )

      token = emission_invoice.token
      due_date = emission_invoice.due_date
      amount = emission_invoice.amount
      status = emission_invoice.status

      expected_body = "B #{token} #{due_date} #{amount} #{status}"

      described_class.create(@filename,[emission_invoice])

      file = File.open(@filename)
      body_invoice = file.readlines.map(&:chomp)
      file.close

      expect(body_invoice[1]).to eq(expected_body)
    end

    it 'should have correct values in footer' do
      emission_invoice = ExecutorSystem::EmissionInvoice
                         .new(
                           token: '5315babefff775cf77fd',
                           payment_method: 'Boleto',
                           due_date: 1.days.from_now.strftime('%Y%M%d'),
                           amount: '0000100000',
                           status: '01'
                         )

      total_amount = '000000000100000'
      emission_invoice_footer = "F #{total_amount}"

      described_class.create(@filename,[emission_invoice])

      file = File.open(@filename)
      footer = file.readlines.last
      file.close

      expect(footer).to eq(emission_invoice_footer)
    end

    context 'with more than 1 invoice' do
      let!(:emission_invoices) do
        emission_invoices = []

        20.times do
          emission_invoices << ExecutorSystem::EmissionInvoice
                               .new(
                                 token: SecureRandom.hex(10),
                                 payment_method: 'Boleto',
                                 due_date: 1.days.from_now.strftime('%Y%M%d'),
                                 amount: "0000#{rand(9)}00000",
                                 status: '01'
                               )
        end

        emission_invoices
      end

      it 'should have correct values in header' do
        emission_invoice_header = "H #{format('%05d' % emission_invoices.size)}"

        described_class.create(@filename, emission_invoices)

        file = File.open(@filename)
        header_invoice = file.readlines.first.chomp
        file.close

        expect(emission_invoice_header).to eq(header_invoice)
      end

      it 'should have correct values in body ' do
        expected_invoices = []

        emission_invoices.each do |emission_invoice|
          token = emission_invoice.token
          due_date = emission_invoice.due_date
          amount = emission_invoice.amount
          status = emission_invoice.status

          expected_invoices << "B #{token} #{due_date} #{amount} #{status}"
        end

        described_class.create(@filename, emission_invoices)

        file = File.open(@filename)
        body_invoice = file.readlines.map(&:chomp)
        file.close

        expect(body_invoice).to include(*expected_invoices)
      end

      it 'should have correct values in footer' do
        total_amount = emission_invoices
                       .map { |invoice| invoice.amount.to_i }
                       .sum

        emission_invoice_footer = "F #{format('%015d' % total_amount)}"

        described_class.create(@filename, emission_invoices)

        file = File.open(@filename)
        header_invoice = file.readlines.last
        file.close

        expect(emission_invoice_footer).to eq(header_invoice)
      end
    end
  end

  context '.filename' do
    let!(:emission_invoices) do
      emission_invoices = []

      20.times do
        emission_invoices << ExecutorSystem::EmissionInvoice
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

    it 'should separate by payment method' do

      payment_method_separate = ExecutorSystem::EmissionInvoice
                                  .payment_method_separate(emission_invoices)

      timestamp = Time.now.strftime('%Y%M%d')
      expected_filenames = []
      payment_method_separate.keys.each do |pay_type|
        invoice_method = pay_type.to_s.upcase
        expected_filenames << @root.join('db', 'emissions', "#{timestamp}_#{invoice_method}_EMISSAO.txt")
      end

      emission_filenames = []
      payment_method_separate.keys.each do |pay_type|
        invoice_method = pay_type.to_s.upcase
        emission_filenames << described_class.filename( invoice_method )
      end

      expect(emission_filenames).to eq(expected_filenames)
    end
  end

  context '.generate_files' do

    it 'should create emission files' do
      timestamp = Time.now.strftime('%Y%M%d')
      invoices = IuguLite::Invoice.pending_invoices

      emission_invoices = ExecutorSystem::EmissionInvoice.create_emissions(invoices)
      emission_invoices_list = ExecutorSystem::EmissionInvoice.payment_method_separate(emission_invoices)

      file_boleto = @root.join('db', 'emissions', "#{timestamp}_BOLETO_EMISSAO.txt")
      file_card = @root.join('db', 'emissions', "#{timestamp}_CARD_EMISSAO.txt")
      file_pix = @root.join('db', 'emissions', "#{timestamp}_PIX_EMISSAO.txt")

      described_class.generate_files(emission_invoices_list)

      expect(File).to exist(file_boleto)
      expect(File).to exist(file_card)
      expect(File).to exist(file_pix)

      File.delete(file_boleto, file_card, file_pix)
    end
  end
end
