require 'spec_helper'
require_relative '../lib/invoice_executor_system/executor_system'

describe ExecutorSystem::Invoice do
  context '.load' do

    it 'should returns pending invoices' do

      returned_invoice = [
                           {
                            token: 'djakdjakjdkajdkajdkajdkj',
                             payment_method: 'jsdkajksajdkjakjdakjkdaj',
                             due_date: 1.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                           },
                           {
                             token: 'djdjakjdkajdkjakdjakjdaj',
                             payment_method: 'dadkalskdlakdlkaldalkd',
                             due_date: 3.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                            }
                          ]

      allow(ExecutorSystem::Invoice).to receive(:get_request).and_return(returned_invoice)

      pending_invoices = ExecutorSystem::Invoice.load

      expect(pending_invoices.count).to eq(returned_invoice.count)
    end

    it 'should have correct Invoice values attributes' do

      returned_invoice = [
                          {
                            token: 'djakdjakjdkajdkajdkajdkj',
                            payment_method: 'jsdkajksajdkjakjdakjkdaj',
                            due_date: 1.days.from_now.strftime("%F"),
                            amount: 1000,
                            status: 'pending'
                          }
                         ]

      allow(ExecutorSystem::Invoice).to receive(:get_request).and_return(returned_invoice)


      pending_invoices = ExecutorSystem::Invoice.load.first

      expect(pending_invoices).to be_instance_of(ExecutorSystem::Invoice)
      expect(pending_invoices.token).to eq 'djakdjakjdkajdkajdkajdkj'
      expect(pending_invoices.payment_method).to eq 'jsdkajksajdkjakjdakjkdaj'
      expect(pending_invoices.due_date).to  eq  1.days.from_now.strftime("%F").gsub("-","")
      expect(pending_invoices.amount).to eq '0000100000'
      expect(pending_invoices.status).to eq '01'
    end
  end
end
