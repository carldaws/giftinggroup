require "test_helper"

class AmazonLinkTest < ActiveSupport::TestCase
  test "recognises Amazon shop and share links" do
    amazon = %w[ https://www.amazon.co.uk/dp/0261103342 https://amazon.com/x https://smile.amazon.de/x https://amzn.eu/d/abc https://a.co/d/abc ]
    others = %w[ https://www.amazon-fakes.example/dp/0261103342 https://notamazon.co.uk/dp/0261103342 not\ a\ link ]

    assert amazon.all? { AmazonLink.amazon?(it) }
    assert others.none? { AmazonLink.amazon?(it) }
  end

  test "takes the name from the link and the photo from the product code" do
    link = AmazonLink.new("https://www.amazon.co.uk/Hobbit-J-R-R-Tolkien/dp/0261103342/ref=sr_1_1?keywords=hobbit")

    assert_equal [ "Hobbit J R R Tolkien", "https://images-na.ssl-images-amazon.com/images/P/0261103342.01.LZZZZZZZ.jpg" ], [ link.title, link.image_url ]
  end

  test "a link without a name still gives the photo" do
    link = AmazonLink.new("https://www.amazon.co.uk/dp/b0bshf7whw?th=1")

    assert_equal [ nil, "https://images-na.ssl-images-amazon.com/images/P/B0BSHF7WHW.01.LZZZZZZZ.jpg" ], [ link.title, link.image_url ]
  end

  test "a link that isn't a product gives nothing" do
    link = AmazonLink.new("https://www.amazon.co.uk/gp/help/customer/display.html")

    assert_nil link.title
    assert_nil link.image_url
  end
end
