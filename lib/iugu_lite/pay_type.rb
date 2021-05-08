# frozen_string_literal: true

require_relative '../iugu_lite'

module IuguLite
  class PayType
    attr_reader :name, :token

    def initialize(name:, token:)
      @name = name
      @token = token
    end

    class << self
      def all
        response = IuguLite.executor_service.get('company_payment_methods')

        response.body.map do |pay_type|
          new(**pay_type)
        end
      end

      def search_name(token)
        payment_method = all.select { |payment_method| payment_method.token.eql? token }
        payment_method.first.name
      end
    end
  end
end
