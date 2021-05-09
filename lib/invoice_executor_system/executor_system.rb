# frozen_string_literal: true

require_relative '../iugu_lite/pay_type'

module ExecutorSystem
  class EmissionInvoice
    attr_reader :token, :payment_method, :due_date, :amount, :status

    def initialize(token:, payment_method:, due_date:, amount:, status:)
      @token = token
      @payment_method = payment_method
      @due_date = due_date
      @amount = amount
      @status = status
    end

    class << self
      def create(invoice)
        emission_invoice = {
          token: invoice.token,
          payment_method: IuguLite::PayType.search_name(invoice.payment_method),
          due_date: invoice.due_date.gsub('-', ''),
          amount: format('%010d', (invoice.amount * 100)),
          status: status_value(invoice.status)
        }

        new(**emission_invoice)
      end

      def create_emissions(data = [])
        data.map do |invoice|
          create(invoice)
        end
      end

      def status_value(status)
        invoice_status = {
          pending: '01',
          paid: '05',
          refused: '09',
          unprocessed: '10'
        }
        invoice_status[status.to_sym]
      end
    end
  end

  class FileEmission
    def self.create(emission_invoices)
      emission_file = File.open(filename, 'w')
      header_file(emission_file, emission_invoices.size)

      emission_invoices.each do |invoice|
        emission_file.write invoice_body(invoice)
      end

      footer_file(emission_file, emission_invoices)

      emission_file.close
    end

    class << self
      def filename
        root = Pathname.pwd
        timestamp = Time.now.strftime('%Y%M%d')
        invoice_method = 'BOLETO'
        root.join('db', 'emissions', "#{timestamp}_#{invoice_method}_EMISSAO.txt")
      end

      def header_file(file, invoices_count)
        header = format('%05d' % invoices_count)

        file.write("H #{header}\n")
      end

      def invoice_body(emission_invoice)
        token = emission_invoice.token
        due_date = emission_invoice.due_date
        amount = emission_invoice.amount
        status = emission_invoice.status

        "B #{token} #{due_date} #{amount} #{status}\n"
      end

      def footer_file(file, emission_invoices)
        total_amount = emission_invoices
                       .map { |invoice| invoice.amount.to_i }
                       .sum

        file.write("F #{format('%015d' % total_amount)}")
      end
    end
  end
end
