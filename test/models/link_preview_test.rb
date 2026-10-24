require "test_helper"

class LinkPreviewTest < ActiveSupport::TestCase
  test "reads the sharing tags shops publish" do
    preview = parse(<<~HTML)
      <html><head>
        <title>Ignored when there's a better name</title>
        <meta property="og:title" content="  Green   wool scarf ">
        <meta property="og:image" content="/images/scarf.jpg">
        <meta property="product:price:amount" content="25.00">
        <meta property="product:price:currency" content="GBP">
      </head></html>
    HTML

    assert_reads preview, title: "Green wool scarf", image_url: "https://store.example/images/scarf.jpg", price: "£25"
  end

  test "falls back to the page title and to structured product data" do
    preview = parse(<<~HTML)
      <html><head>
        <title>Walking boots | Outdoor Shop</title>
        <script type="application/ld+json">
          {"@context": "https://schema.org", "@graph": [{"@type": "Product", "name": "Walking boots", "offers": {"@type": "Offer", "price": "89.99", "priceCurrency": "EUR"}}]}
        </script>
      </head></html>
    HTML

    assert_reads preview, title: "Walking boots | Outdoor Shop", image_url: nil, price: "€89.99"
  end

  test "leaves the shop's own name out of the title" do
    by_address = LinkPreview.parse("<title>The Hobbit by J. R. R. Tolkien | Waterstones</title>", base_url: "https://www.waterstones.com/book/1")
    by_site_name = LinkPreview.parse(<<~HTML, base_url: "https://www.lego.com/en-gb/product/1")
      <meta property="og:site_name" content="LEGO">
      <title>Millennium Falcon 75192 | Star Wars | Buy online at the Official LEGO Shop GB</title>
    HTML

    assert_reads by_address, title: "The Hobbit by J. R. R. Tolkien"
    assert_reads by_site_name, title: "Millennium Falcon 75192 | Star Wars"
    assert_reads parse("<title>Pots - Pans | Le Creuset</title>"), title: "Pots - Pans | Le Creuset"
  end

  test "copes with pages that have nothing useful" do
    preview = parse("<html><head><script type='application/ld+json'>not json</script></head></html>")

    assert_reads preview, title: nil, price: nil
    assert_nil preview.download_photo
  end

  test "only sensible prices are kept" do
    prices = %w[ 1e20000000 Infinity NaN 0 -5 12,99 1,299.50 ].index_with { |amount| price_from(amount, "gbp") }

    assert_equal({ "1e20000000" => nil, "Infinity" => nil, "NaN" => nil, "0" => nil, "-5" => nil, "12,99" => "£12.99", "1,299.50" => "£1299.50" }, prices)
  end

  test "odd structured data doesn't break anything" do
    preview = parse(<<~HTML)
      <script type="application/ld+json">[null, 1, "text"]</script>
      <script type="application/ld+json">{"@type": ["Product", "Thing"], "offers": [{"price": "40", "priceCurrency": "USD"}]}</script>
    HTML

    assert_reads preview, price: "$40"
  end

  test "reads pages in the character set they declare" do
    preview = LinkPreview.parse("<title>Caf\xE9 cr\xE8me</title>".b, base_url: "https://store.example/1", charset: "ISO-8859-1")

    assert_reads preview, title: "Café crème"
  end

  test "a page with no picture or price isn't treated as a product" do
    assert_not parse("<html><head><title>Amazon.co.uk</title></head></html>").product?
    assert parse("<html><head><meta property='og:image' content='/boots.jpg'></head></html>").product?
  end

  private
    def parse(html)
      LinkPreview.parse(html, base_url: "https://store.example/products/1")
    end

    def price_from(amount, currency)
      parse(%(<meta property="product:price:amount" content="#{amount}"><meta property="product:price:currency" content="#{currency}">)).price
    end

    def assert_reads(preview, **expected)
      assert_equal expected, expected.keys.index_with { preview.public_send(it) }
    end
end
