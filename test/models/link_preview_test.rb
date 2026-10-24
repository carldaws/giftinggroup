require "test_helper"

class LinkPreviewTest < ActiveSupport::TestCase
  test "reads the name and picture a shop shares for link previews" do
    preview = parse(<<~HTML)
      <title>Ignored</title>
      <meta property="og:title" content="  Green   wool scarf ">
      <meta property="og:image" content="/images/scarf.jpg">
    HTML

    assert preview.found_anything?
    assert_equal [ "Green wool scarf", "https://store.example/images/scarf.jpg" ], [ preview.title, preview.image_url ]
  end

  test "reads the tags whichever way the shop writes them" do
    name = "Lint roller"
    preview = parse("<meta name='og:title' content='#{name}'>")

    assert_equal name, preview.title
  end

  test "a page that shares nothing gives nothing" do
    preview = parse("<title>Walking boots</title>")

    assert_not preview.found_anything?
    assert_nil preview.download_photo
  end

  private
    def parse(html)
      LinkPreview.parse(html, base_url: "https://store.example/products/1")
    end
end
