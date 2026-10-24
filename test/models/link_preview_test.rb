require "test_helper"

class LinkPreviewTest < ActiveSupport::TestCase
  test "reads the sharing tags shops publish" do
    preview = parse(<<~HTML)
      <html><head>
        <title>Ignored when there's a better name</title>
        <meta property="og:title" content="  Green   wool scarf ">
        <meta property="og:image" content="/images/scarf.jpg">
      </head></html>
    HTML

    assert_reads preview, title: "Green wool scarf", image_url: "https://store.example/images/scarf.jpg"
  end

  test "falls back to the page title" do
    assert_reads parse("<title>Walking boots</title>"), title: "Walking boots", image_url: nil
  end

  test "reads pages in the character set they declare" do
    preview = LinkPreview.parse("<title>Caf\xE9 cr\xE8me</title>".b, base_url: "https://store.example/1", charset: "ISO-8859-1")

    assert_reads preview, title: "Café crème"
  end

  test "a page without a picture isn't treated as a product" do
    assert_not parse("<html><head><title>Amazon.co.uk</title></head></html>").product?
    assert parse("<html><head><meta property='og:image' content='/boots.jpg'></head></html>").product?
  end

  test "a page with nothing useful gives nothing" do
    preview = parse("<html></html>")

    assert_reads preview, title: nil, image_url: nil
    assert_nil preview.download_photo
  end

  private
    def parse(html)
      LinkPreview.parse(html, base_url: "https://store.example/products/1")
    end

    def assert_reads(preview, **expected)
      assert_equal expected, expected.keys.index_with { preview.public_send(it) }
    end
end
