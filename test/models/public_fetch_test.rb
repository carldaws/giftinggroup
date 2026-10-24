require "test_helper"

class PublicFetchTest < ActiveSupport::TestCase
  test "won't fetch anything on the server or its private network" do
    %w[
      http://127.0.0.1/ http://10.0.0.5/ http://172.18.0.2/ http://192.168.1.1/ http://169.254.169.254/latest/meta-data
      http://[::1]/ http://[::ffff:127.0.0.1]/ http://[fd00::1]/ http://[64:ff9b::7f00:1]/ http://100.64.0.1/
    ].each do |url|
      assert_raises(PublicFetch::Refused) { PublicFetch.get(url, limit: 1.kilobyte) }
    end
  end

  test "only fetches ordinary web addresses" do
    %w[ file:///etc/passwd ftp://example.com/ javascript:alert(1) not\ a\ url http://user:secret@example.com/ http://example.com:8080/ https://example.com:2375/ ].each do |url|
      assert_raises(PublicFetch::Refused) { PublicFetch.get(url, limit: 1.kilobyte) }
    end
  end
end
