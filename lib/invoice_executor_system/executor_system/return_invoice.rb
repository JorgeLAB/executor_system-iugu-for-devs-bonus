module ExecutorSystem
  class ReturnInvoice

    attr_reader :token, :status

    def initialize(token:, status:)
      @token = token
      @status = status
    end

    def self.create(return_file_bank)

      return_invoices = []

      file = File.open(return_file_bank, 'r')
      file_read = file.readlines.map(&:chomp)
      invoices = file_read[1...file_read.count-1]

      invoices.each do |return_invoice|
        invoice = return_invoice.split
        token = invoice[1]
        status = invoice[5]
        return_invoices << new(token: token, status: status)
      end
      file.close

      return_invoices
    end
  end
end
