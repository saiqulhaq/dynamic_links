# frozen_string_literal: true

require 'test_helper'

# @author Saiqul Haq <saiqulhaq@gmail.com>
module DynamicLinks
  class ClientTest < ActiveSupport::TestCase
    test 'creates client with valid attributes' do
      client = Client.new(
        name: 'Test Client',
        api_key: 'test_api_key_123',
        hostname: 'test.example.com',
        scheme: 'https'
      )

      assert client.valid?
      assert client.save
    end

    test 'validates presence of required fields' do
      client = Client.new

      refute client.valid?
      assert_includes client.errors[:name], "can't be blank"
      assert_includes client.errors[:api_key], "can't be blank"
      assert_includes client.errors[:hostname], "can't be blank"
      # NOTE: scheme has a default value in the migration, so it might not be blank
    end

    test 'validates uniqueness of name, api_key, and hostname' do
      Client.create!(
        name: 'Existing Client',
        api_key: 'existing_key',
        hostname: 'existing.example.com',
        scheme: 'https'
      )

      duplicate_client = Client.new(
        name: 'Existing Client',
        api_key: 'existing_key',
        hostname: 'existing.example.com',
        scheme: 'https'
      )

      refute duplicate_client.valid?
      assert_includes duplicate_client.errors[:name], 'has already been taken'
      assert_includes duplicate_client.errors[:api_key], 'has already been taken'
      assert_includes duplicate_client.errors[:hostname], 'has already been taken'
    end

    test 'validates scheme inclusion' do
      client = Client.new(
        name: 'Test Client',
        api_key: 'test_key',
        hostname: 'test.example.com',
        scheme: 'ftp'
      )

      refute client.valid?
      assert_includes client.errors[:scheme], 'is not included in the list'
    end

    test 'validates hostname format' do
      invalid_hostnames = [
        'invalid hostname with spaces',
        'invalid..hostname',
        '.invalid.hostname',
        'invalid.hostname.',
        'invalid_hostname_with_underscores'
      ]

      invalid_hostnames.each do |hostname|
        client = Client.new(
          name: 'Test Client',
          api_key: 'test_key',
          hostname: hostname,
          scheme: 'https'
        )

        refute client.valid?, "Expected #{hostname} to be invalid"
        assert_includes client.errors[:hostname], 'must be a valid hostname'
      end
    end

    test 'allows valid hostnames' do
      valid_hostnames = [
        'example.com',
        'sub.example.com',
        'deep.sub.example.com',
        'example-with-dashes.com',
        'localhost',
        '192.168.1.1'
      ]

      valid_hostnames.each do |hostname|
        client = Client.new(
          name: "Test Client #{hostname}",
          api_key: "test_key_#{hostname.gsub('.', '_')}",
          hostname: hostname,
          scheme: 'https'
        )

        assert client.valid?, "Expected #{hostname} to be valid, but got errors: #{client.errors.full_messages}"
      end
    end

    test 'prevents hostname changes after creation' do
      client = Client.create!(
        name: 'Test Client',
        api_key: 'test_key',
        hostname: 'original.example.com',
        scheme: 'https'
      )

      # Try to change hostname
      client.hostname = 'new.example.com'

      refute client.valid?
      assert_includes client.errors[:hostname], 'cannot be changed after creation as it would break existing short URLs'
    end

    test 'allows other attribute changes after creation' do
      client = Client.create!(
        name: 'Original Name',
        api_key: 'original_key',
        hostname: 'test.example.com',
        scheme: 'http'
      )

      # Change other attributes (but not hostname)
      client.name = 'New Name'
      client.scheme = 'https'

      assert client.valid?,
             "Expected client to be valid after changing non-hostname attributes, but got: #{client.errors.full_messages}"
      assert client.save
    end

    test 'allows creation with same hostname format as existing (different value)' do
      Client.create!(
        name: 'First Client',
        api_key: 'first_key',
        hostname: 'first.example.com',
        scheme: 'https'
      )

      second_client = Client.new(
        name: 'Second Client',
        api_key: 'second_key',
        hostname: 'second.example.com',
        scheme: 'https'
      )

      assert second_client.valid?
      assert second_client.save
    end
  end
end
