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

      def payment_method_separate(emission_invoices)

        emission_list = {}

        IuguLite::PayType.all.each { |pay_type| emission_list[pay_type.name.to_sym] = [] }
        emission_invoices.each do |invoice|
          emission_list[invoice.payment_method.to_sym] << invoice
        end

        emission_list
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
