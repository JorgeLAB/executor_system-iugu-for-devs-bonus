# frozen_string_literal: true

require_relative '../iugu_lite'

class IuguLite::Invoice
  attr_reader :token, :payment_method, :due_date, :amount, :status

  def initialize(token:, payment_method:, due_date:, amount:, status:)
    @token = token
    @payment_method = payment_method
    @due_date = due_date
    @amount = amount
    @status = status
  end

  def self.pending_invoices
    invoices = load
    invoices.map do |invoice|
      new(**invoice)
    end
  end

  def self.load
    response = IuguLite.executor_service.post('invoices')
    response.body
  end
end
