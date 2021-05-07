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

    def self.new_connection
      Faraday.new(
        url: iugu_lite_uri,
        params: { executor_token: '' }
      ) do |faraday|
        faraday.headers['Content-Type'] = 'application/json'
        faraday.response :json, parser_options: { symbolize_names: true },
                                content_type: /\bjson$/
        faraday.adapter :net_http
      end
    end

    def self.get_request(endpoint, data = {})
      response = new_connection.get(endpoint) { |req| req.params = data }
    end

    def iugu_lite_uri
      "iugu_lite_url/api/#{api_version}/#{endpoint}"
    end

    def api_version
      'v1'
    end

    private

      class << self
        def create_emissions( data = [])
          data.map do |invoice|
            invoice[:due_date] = invoice[:due_date].gsub("-","")
            invoice[:amount] = "%010d" % (invoice[:amount]*100)
            invoice[:status] = status_value(invoice[:status])
            new(**invoice)
          end
        end

        def status_value(status)
          invoice_status = {
                            :pending => '01',
                            :paid => '05',
                            :refused => '09',
                            :unprocessed => '10',
                           }
          invoice_status[status.to_sym]
        end
      end
  end
end
