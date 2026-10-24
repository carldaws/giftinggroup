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

  test "unpacks compressed pages that arrive unasked, but only up to the limit" do
    page = "<title>Walking boots</title>" + ("x" * 10.kilobytes)

    assert_equal page, PublicFetch.decompressed(ActiveSupport::Gzip.compress(page), limit: 1.megabyte)
    assert_raises(PublicFetch::Refused) { PublicFetch.decompressed(ActiveSupport::Gzip.compress(page), limit: 1.kilobyte) }
    assert_equal page, PublicFetch.decompressed(page, limit: 1.megabyte)
    assert_raises(PublicFetch::Refused) { PublicFetch.decompressed("\x1F\x8Bnot really".b, limit: 1.megabyte) }
  end

  test "won't start a fetch with too little time left to limit it" do
    assert_raises(PublicFetch::Refused) { PublicFetch.get("https://example.com/", limit: 1.kilobyte, give_up_at: PublicFetch.now + 0.2) }
  end

  test "only fetches ordinary web addresses" do
    %w[ file:///etc/passwd ftp://example.com/ javascript:alert(1) not\ a\ url http://user:secret@example.com/ http://example.com:8080/ https://example.com:2375/ ].each do |url|
      assert_raises(PublicFetch::Refused) { PublicFetch.get(url, limit: 1.kilobyte) }
    end
  end
end
