# frozen_string_literal: true

require 'spec_helper'

require_relative '../../lib/invoice_executor_system/executor_system'
require_relative '../../lib/iugu_lite/invoice'
require_relative '../../lib/bank_system/bank_system'

describe BankSystem::ReturnFile do

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
  end

  after(:each) do
    File.delete(*@emission_files)
  end

  context '.generate' do

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

    it 'should generate return file' do

      described_class.generate(@emission_files)
      return_filename = "#{@timestamp}_RETURN_FILE.TXT"
      return_file = @root.join('db', 'bank_return', return_filename )

      expect(File).to exist(return_file)

      File.delete(return_file)
    end

    it 'should have correct values in header' do

      return_filename = "#{@timestamp}_RETURN_FILE.TXT"
      return_file = @root.join('db', 'bank_return', return_filename )

      total_invoices = '00020'
      return_file_header = "H #{total_invoices}\n"

      described_class.generate(@emission_files)

      file = File.open(return_file,'r')
      header = file.readlines.first
      file.close

      expect(header).to eq(return_file_header)

      File.delete(return_file)
    end

    it 'should have correct values in body' do
      return_filename = "#{@timestamp}_RETURN_FILE.TXT"
      return_file = @root.join('db', 'bank_return', return_filename )

      expected_return_file = []

      emission_invoices.each do |invoice|
        token = invoice.token
        due_date = invoice.due_date
        amount = invoice.amount
        status = '05'

        expected_return_file << "B #{token} #{due_date} #{@timestamp} #{amount} #{status}"
      end

      described_class.generate(@emission_files)

      file = File.open(return_file)
      return_file_body = file.readlines.map(&:chomp)
      file.close

      expect(return_file_body).to include(*expected_return_file)

      File.delete(return_file)
    end

    it 'should habe correct values in footer' do
      return_filename = "#{@timestamp}_RETURN_FILE.TXT"
      return_file = @root.join('db', 'bank_return', return_filename )

      total_amount = emission_invoices
                     .map { |invoice| invoice.amount.to_i }
                     .sum

      expected_footer = "F #{format('%015d' % total_amount)}"

      described_class.generate(@emission_files)

      file = File.open(return_file, 'r')
      return_file_footer = file.readlines.last.chomp
      file.close

      expect(return_file_footer).to eq(expected_footer)
      File.delete(return_file)
    end
  end
end
