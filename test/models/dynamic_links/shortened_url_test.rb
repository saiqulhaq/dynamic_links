require 'test_helper'

# == Schema Information
#
# Table name: dynamic_links_shortened_urls
#
#  id         :bigint           not null, primary key
#  client_id  :bigint
#  url        :string(2083)     not null
#  short_url  :string(10)       not null
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_dynamic_links_shortened_urls_on_client_id  (client_id)
#  index_dynamic_links_shortened_urls_on_short_url  (short_url) UNIQUE
#
# @author Saiqul Haq <saiqulhaq@gmail.com>
class DynamicLinks::ShortenedUrlTest < ActiveSupport::TestCase
  self.use_transactional_tests = true

  setup do
    @client = dynamic_links_clients(:one)
    @url = 'https://example.com'
    @short_url = 'shortened_url'
  end

  test 'should not save shortened url without url' do
    shortened_url = DynamicLinks::ShortenedUrl.new(client: @client, short_url: 'abc123')
    assert_not shortened_url.save, 'Saved the shortened url without a url'
  end

  test 'should not save shortened url without short_url' do
    shortened_url = DynamicLinks::ShortenedUrl.new(client: @client, url: 'https://example.com')
    assert_not shortened_url.save, 'Saved the shortened url without a short_url'
  end

  test 'should save valid shortened url' do
    shortened_url = DynamicLinks::ShortenedUrl.new(client: @client, url: 'https://example.com', short_url: 'abc123ss')
    assert shortened_url.save, 'Failed to save valid shortened url'
  end

  test 'should not save shortened url with duplicate short_url' do
    DynamicLinks::ShortenedUrl.create!(client: @client, url: 'https://example.com', short_url: 'abc123b')
    duplicate_url = DynamicLinks::ShortenedUrl.new(client: @client, url: 'https://example.com/another', short_url: 'abc123b')
    assert_not duplicate_url.save, 'Saved the shortened url with a duplicate short_url'
  end

  test 'should allow the same short_url for different clients' do
    client_one = dynamic_links_clients(:one)
    client_two = dynamic_links_clients(:two)

    url_one = DynamicLinks::ShortenedUrl.create!(client: client_one, url: 'https://example.com', short_url: 'foobar')
    url_two = DynamicLinks::ShortenedUrl.new(client: client_two, url: 'https://example.org', short_url: 'foobar')

    assert url_two.valid?, 'ShortenedUrl with duplicate short_url but different client should be valid'
  end

  test 'should not allow the same short_url for the same client' do
    client = dynamic_links_clients(:one)

    DynamicLinks::ShortenedUrl.create!(client: client, url: 'https://example.com', short_url: 'xyz789')
    duplicate_url = DynamicLinks::ShortenedUrl.new(client: client, url: 'https://example.org', short_url: 'xyz789')

    assert_not duplicate_url.valid?, 'ShortenedUrl with duplicate short_url for the same client should not be valid'
  end

  test "find_or_create returns existing record if it exists" do
    existing_record = DynamicLinks::ShortenedUrl.create!(client: @client, url: @url, short_url: @short_url)
    result = DynamicLinks::ShortenedUrl.find_or_create!(@client, @short_url, @url)
    assert_equal existing_record, result, "Expected to return the existing record"
  end

  test "find_or_create creates and returns a new record if it doesn't exist" do
    assert_difference 'DynamicLinks::ShortenedUrl.count', 1 do
      result = DynamicLinks::ShortenedUrl.find_or_create!(@client, @short_url, @url)
      assert_not_nil result, "Expected a new ShortenedUrl record to be created"
      assert_equal @client, result.client
      assert_equal @url, result.url
      assert_equal @short_url, result.short_url
      # Call find_or_create again and ensure the count doesn't change
      assert_no_difference 'DynamicLinks::ShortenedUrl.count' do
        DynamicLinks::ShortenedUrl.find_or_create!(@client, @short_url, @url)
      end
    end
  end

  test 'should validate presence of url' do
    shortened_url = DynamicLinks::ShortenedUrl.new(client: @client, short_url: @short_url)
    assert_not shortened_url.valid?
    assert_includes shortened_url.errors[:url], "can't be blank"
  end

  test 'should validate presence of short_url' do
    shortened_url = DynamicLinks::ShortenedUrl.new(client: @client, url: @url)
    assert_not shortened_url.valid?
    assert_includes shortened_url.errors[:short_url], "can't be blank"
  end

  test 'should validate uniqueness of short_url scoped to client_id' do
    existing_record = DynamicLinks::ShortenedUrl.create!(client: @client, url: @url, short_url: @short_url)
    new_record = DynamicLinks::ShortenedUrl.new(client: @client, url: @url, short_url: @short_url)
    assert_not new_record.valid?
    assert_includes new_record.errors[:short_url], "has already been taken"
  end

  test 'find_or_create! should find existing record' do
    existing_record = DynamicLinks::ShortenedUrl.create!(client: @client, url: @url, short_url: @short_url)
    found_record = DynamicLinks::ShortenedUrl.find_or_create!(@client, @short_url, @url)
    assert_equal existing_record, found_record
  end

  test 'find_or_create! should create new record if not exists' do
    assert_difference 'DynamicLinks::ShortenedUrl.count', 1 do
      DynamicLinks::ShortenedUrl.find_or_create!(@client, @short_url, @url)
    end
  end

  test 'find_or_create! should raise error and log if save fails' do
    DynamicLinks::Logger.expects(:log_error).with(regexp_matches(/ShortenedUrl creation failed/))
    assert_raises ActiveRecord::RecordInvalid do
      DynamicLinks::ShortenedUrl.find_or_create!(@client, nil, @url)
    end
  end
end
