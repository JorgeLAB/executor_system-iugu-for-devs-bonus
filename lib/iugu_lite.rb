# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'

module IuguLite
  class << self
    def executor_service
      @executor_service ||= new_connection
    end

    private

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
      "#{endpoint}/api/#{api_version}/"
    end

    def endpoint
      'https://test.iugu-lite.com.br'
    end

    def api_version
      'v1'
    end
  end
end
