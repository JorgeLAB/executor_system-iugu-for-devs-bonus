# frozen_string_literal: true

require 'spec_helper'

describe IuguLite do
  context '.executor_service' do
    subject { described_class.executor_service }

    it 'is a faraday instance' do
      expect(subject).to be_instance_of(Faraday::Connection)
    end

    it 'use the configuration url' do
      expect(subject.url_prefix).to eq URI('https://test.iugu-lite.com.br/api/v1/')
    end

    it 'content-type using json' do
      expect(subject.headers['Content-Type']).to eq('application/json')
    end
  end
end
