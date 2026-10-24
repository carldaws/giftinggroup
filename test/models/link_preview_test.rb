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

  test "reads pages in the character set the shop's server declares" do
    name = "Café crème"
    preview = LinkPreview.parse("<meta property='og:title' content='#{name}'>".b, base_url: "https://store.example/1", charset: "utf-8")

    assert_equal name, preview.title
  end

  test "keeps pictures whose addresses have spaces or accents" do
    file = "My Fotó.jpg"
    preview = parse("<meta property='og:image' content='https://cdn.store.example/#{file}'>")

    assert_equal file, URI.decode_uri_component(URI(preview.image_url).path.delete_prefix("/"))
  end

  test "a page that shares nothing gives nothing" do
    preview = parse("<title>Walking boots</title>")

    assert_not preview.found_anything?
  end

  private
    def parse(html)
      LinkPreview.parse(html, base_url: "https://store.example/products/1")
    end
end
