module BankSystem
  class ReturnInvoice
    attr_reader :token, :due_date, :create_at, :amount, :status

    def initialize(token:, due_date:, amount:, status:)

      @token = token
      @due_date = due_date
      @create_at = Time.now.strftime("%Y%m%d")
      @amount = amount
      @status = '05'
    end

    def self.create(invoice)
      new(token: invoice[0], due_date: invoice[1], amount: invoice[2], status: invoice[3])
    end
  end

  class ReturnFile

    def self.generate(emission_files)
      timestamp = Time.now.strftime('%Y%m%d')
      root = Pathname.pwd
      filename = "#{timestamp}_RETURN_FILE.TXT"
      filepath = root.join('db','bank_return', filename)
      file = File.new( filepath, 'w' )

      file_header = header_count(emission_files)
      header_file(file, file_header)

      return_invoices = read_emission(emission_files)
      body_file(file, return_invoices)

      footer_file(file, emission_files)

      file.close
    end

    class << self
      def header_file(file, invoices_count)
        header = format('%05d' % invoices_count)

        file.write("H #{header}\n")
      end

      def header_count(emission_files)
        invoices_count = 0

        emission_files.each do |emission|
          file = File.open(emission, 'r')
          count = file.readlines.first.chomp[/\d.+/].to_i
          invoices_count = invoices_count + count
        end

        invoices_count
      end

      def body_file(file, return_invoices)
        return_invoices.each do |invoice|
          file.write return_file_body(invoice)
        end
      end

      def return_file_body(return_invoice)
        token = return_invoice.token
        due_date = return_invoice.due_date
        amount = return_invoice.amount
        create_at = return_invoice.create_at
        status = return_invoice.status

        "B #{token} #{due_date} #{create_at} #{amount} #{status}\n"
      end

      def read_emission(emission_files)

        return_invoices = []

        emission_files.each do |emission|
          file = File.open(emission, 'r')
          invoices_body = file.readlines.map(&:chomp)
          invoices_body_count = invoices_body.count - 1

          invoices_body[1...invoices_body_count].map do |invoice|
            return_invoices << BankSystem::ReturnInvoice.create(invoice.split[1..])
          end
        end

        return_invoices
      end

      def footer_file(file, emission_invoices)
        return_invoices = read_emission(emission_invoices)
        total_amount = return_invoices
                       .map { |invoice| invoice.amount.to_i }
                       .sum

        file.write("F #{format('%015d' % total_amount)}")
      end
    end
  end
end
