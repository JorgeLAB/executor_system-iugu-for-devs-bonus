# frozen_string_literal: true

module IuguLite
  def executor_service
    @executor_service ||= new_connection
  end

  class << self
    def new_connection
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

    def iugu_lite_uri
      "iugu_lite_url/api/#{api_version}/#{endpoint}"
    end

    def api_version
      'v1'
    end
  end
end
