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

    def self.verified
      root = Pathname.pwd
      bank_return_dir = root.join('db','bank_return','*')
      bank_files_return = Dir.glob(bank_return_dir)

      invoices_verified = []

      bank_files_return.each do |return_file_bank|
        invoices = create(return_file_bank)
        invoices_verified << invoices.flatten
        move_verified(return_file_bank)
      end
    end

    private

      def self.move_verified(return_file_bank)
        return_file_verified = return_file_bank.gsub('bank_return', 'verified')
                                               .gsub('TXT','TXT.PRONTO')
        FileUtils.mv(return_file_bank, return_file_verified)
      end
  end
end
