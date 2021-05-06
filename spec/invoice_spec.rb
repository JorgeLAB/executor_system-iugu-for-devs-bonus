require 'spec_helper'

describe ExecutorSystem::Invoice do
  context '.load' do

    it 'should returns pending invoices' do

      returned_invoice = [
                           {
                            token: 'djakdjakjdkajdkajdkajdkj',
                             company_payment_method: 'jsdkajksajdkjakjdakjkdaj',
                             due_date: 1.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                           },
                           {
                             token: 'djdjakjdkajdkjakdjakjdaj',
                             company_payment_method: 'dadkalskdlakdlkaldalkd',
                             due_date: 3.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                            }
                          ]

      allow(Faraday).to receive(:get_request).and_return(returned_invoice)

      pending_invoices = ExecutorSystem::Invoice.load

      expected(pending_invoices.count).to eq(returned_invoice.count)
    end

    it 'should have correct Invoice values attributes' do

      returned_invoice = [
                          {
                            token: 'djakdjakjdkajdkajdkajdkj',
                            company_payment_method: 'jsdkajksajdkjakjdakjkdaj',
                            due_date: 1.days.from_now.strftime("%F"),
                            amount: 1000,
                            status: 'pending'
                          }
                         ]

      allow(Faraday).to receive(:get_request).and_return(returned_invoice)

      expected_executor_invoice = Invoice.new( token: 'djakdjakjdkajdkajdkajdkj',
                                               payment_method: 'jsdkajksajdkjakjdakjkdaj',
                                               due_date: 1.days.from_now.strftime("%F").gsub("-",""),
                                               amount: 000100000,
                                               status: 01
                                             )

      pending_invoices = ExecutorSystem::Invoice.load

      expect(pending_invoices).to eq(expected_executor_invoice)
    end

    it 'should returns correct executor_invoices' do

      returned_invoice = [
                           { token: 'djakdjakjdkajdkajdkajdkj',
                             company_payment_method: 'jsdkajksajdkjakjdakjkdaj',
                             due_date: 1.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                           },
                           {
                             token: 'djdjakjdkajdkjakdjakjdaj',
                             company_payment_method: 'dadkalskdlakdlkaldalkd',
                             due_date: 3.days.from_now.strftime("%F"),
                             amount: 1000,
                             status: 'pending'
                            }
                          ]

      allow(Faraday).to receive(:get_request).and_return(returned_invoice)

      expected_invoices = executer_invoices_objects(returned_invoice)

      pending_invoices = ExecutorSystem::Invoice.load

      expected(pending_invoices).to contain_exactly **expected_invoices
    end
  end
end
