module ExecutorSystem
  class FileEmission

    def self.generate_files(emission_invoices)
      emission_invoices.each do |key, invoices|
        emission_file = filename(key)
        create(emission_file, invoices)
      end
    end

    def self.create(filename, emission_invoices)
      emission_file = File.open(filename, 'w')
      header_file(emission_file, emission_invoices.size)

      emission_invoices.each do |invoice|
        emission_file.write invoice_body(invoice)
      end

      footer_file(emission_file, emission_invoices)

      emission_file.close
    end

    class << self

      def filename(pay_type)
        root = Pathname.pwd
        timestamp = Time.now.strftime('%Y%M%d')
        invoice_method = pay_type.to_s.upcase
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
