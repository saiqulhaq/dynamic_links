# == Schema Information
#
# Table name: dynamic_links_clients
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  api_key    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dynamic_links_clients_on_api_key  (api_key) UNIQUE
#  index_dynamic_links_clients_on_name     (name) UNIQUE
#
require 'test_helper'

module DynamicLinks
  class ClientTest < ActiveSupport::TestCase
    self.use_transactional_tests = true

    test 'should not save client without name' do
      client = Client.new(api_key: 'unique_api_key', hostname: 'example.com', scheme: 'https')
      assert_not client.save, 'Saved client without a name'
    end

    test 'should not save client without api_key' do
      client = Client.new(name: 'Unique Name', hostname: 'example.com', scheme: 'https')
      assert_not client.save, 'Saved client without an api_key'
    end

    test 'should not save client without hostname' do
      client = Client.new(name: 'Unique Name', api_key: 'unique_api_key', scheme: 'https')
      assert_not client.save, 'Saved client without a hostname'
    end

    test 'should not save client with invalid scheme' do
      client = Client.new(name: 'Unique Name', api_key: 'unique_api_key', hostname: 'example.com', scheme: 'invalid')
      assert_not client.save, 'Saved client with an invalid scheme'
    end

    test 'should save client with name, api_key, hostname, and valid scheme' do
      client = Client.new(name: 'Test Client', api_key: 'test_api_key', hostname: 'example.com', scheme: 'https')
      assert client.save, 'Failed to save valid client'
    end

    test 'should not save client with duplicate api_key' do
      Client.create!(name: 'Test Client', api_key: 'test_api_key', hostname: 'example.com', scheme: 'https')
      duplicate_client = Client.new(name: 'Test Client 2', api_key: 'test_api_key', hostname: 'example2.com', scheme: 'https')
      assert_not duplicate_client.save, 'Saved client with a duplicate api_key'
    end

    test 'should not save client with duplicate name' do
      Client.create!(name: 'Test Client', api_key: 'test_api_key', hostname: 'example.com', scheme: 'https')
      duplicate_client = Client.new(name: 'Test Client', api_key: 'test_api_key1', hostname: 'example2.com', scheme: 'https')
      assert_not duplicate_client.save, 'Saved client with a duplicate name'
    end
  end
end
