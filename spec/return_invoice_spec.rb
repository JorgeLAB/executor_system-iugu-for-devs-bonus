# frozen_string_literal: true

require 'spec_helper'

require_relative '../lib/invoice_executor_system/executor_system'
require_relative '../lib/bank_system/bank_system'
require_relative '../lib/iugu_lite/invoice'

describe ExecutorSystem::ReturnInvoice do

  before do
    @root = Pathname.pwd
    @timestamp = Time.now.strftime('%Y%m%d')

    allow_any_instance_of(Faraday::Connection).to receive(:get)
      .with('company_payment_methods')
      .and_return(
        instance_double(
          Faraday::Response, status: 200,
                             body: JSON.parse(File.read(@root.join('spec/fixtures/company_payment_methods.json')),
                                              symbolize_names: true)
        )
      )

    emission_invoices_list = ExecutorSystem::EmissionInvoice
                              .payment_method_separate(emission_invoices)

    ExecutorSystem::FileEmission.generate_files(emission_invoices_list)
    @emission_files = Dir.glob(@root.join('db', 'emissions', '*'))
    BankSystem::ReturnFile.generate(@emission_files)
  end

  after(:each) do
    File.delete(*@emission_files)
  end

  context '.create' do

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

    it 'should read a bank file return' do
      bank_return_dir = @root.join('db','bank_return','*')
      bank_files_return = Dir.glob(bank_return_dir)

      expected_return_invoices = []

      file = File.open(bank_files_return.first, 'r')
      file_read = file.readlines.map(&:chomp)
      invoices = file_read[1...file_read.count-1]

      invoices.each do |return_invoice|
        invoice = return_invoice.split
        token = invoice[1]
        status = invoice[5]
        expected_return_invoices << { token: token, status: status}
      end

      file.close

      return_invoices = described_class.create(bank_files_return.first)

      expected_return_invoices.each_with_index do |invoice, index|
        expect(return_invoices[index].token).to eq invoice[:token]
        expect(return_invoices[index].status).to eq invoice[:status]
      end

      File.delete(bank_files_return.first)
    end
  end

  context '.verified' do

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

    it 'should move the bank file return for verified' do
      bank_return_dir = @root.join('db','bank_return','*')
      bank_files_return = Dir.glob(bank_return_dir)
      bank_files_return_name = Dir.children(bank_return_dir.dirname).first
      expected_create_file = @root.join('db','verified', "#{bank_files_return_name}.PRONTO")

      described_class.verified

      expect(File).to_not exist(bank_files_return.first)
      expect(File).to exist(expected_create_file)

      File.delete(expected_create_file)
    end
  end
end
