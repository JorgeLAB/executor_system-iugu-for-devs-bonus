# frozen_string_literal: true

require_relative '../pay_types'

module ExecutorSystem
  class Invoice
    attr_reader :token, :payment_method, :due_date, :amount, :status

    def initialize(token:, payment_method:, due_date:, amount:, status:)
      @token = token
      @payment_method = payment_method
      @due_date = due_date
      @amount = amount
      @status = status
    end

    def self.load
      invoices = get_request('/invoices')
      create_emissions(invoices)
    end

    class << self
      def create_emissions(data = [])
        data.map do |invoice|
          invoice[:payment_method] = PayTypes.search_name invoice[:payment_method]
          invoice[:due_date] = invoice[:due_date].gsub('-', '')
          invoice[:amount] = format('%010d', (invoice[:amount] * 100))
          invoice[:status] = status_value(invoice[:status])
          new(**invoice)
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
end
