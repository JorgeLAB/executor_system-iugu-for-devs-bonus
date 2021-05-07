# frozen_string_literal: true

class PayTypes
  attr_reader :name, :token

  def initialize(name:, token:)
    @name = name
    @token = token
  end

  def self.all
    [
      new(name: 'Boleto', token: 'token_boleto'),
      new(name: 'PIX', token: 'token_pix'),
      new(name: 'Cartao de Crédito', token: 'token_card')
    ]
  end

  def self.search_name(token)
    payment_method = all.select { |payment_method| payment_method.token.eql? token }
    payment_method.first.name
  end
end
