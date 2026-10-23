# gifting.group

Free wishlists for groups of people who buy each other presents.

Start a group and invite people. Everyone shares their wishlists, and anyone can mark an item as reserved or bought, but never on their own list. Each person also has a chat that everyone in the group can see except them, for agreeing who gets what.

No ads, no affiliate links, no email. It's a work in progress.

## Running it locally

You need Ruby (see `.ruby-version`), PostgreSQL and libvips.

```sh
bin/setup
```

That installs gems, prepares the database and starts the app at http://localhost:2512.

## Tests

```sh
bin/rails test
bin/rubocop
```

## Licence

[AGPL-3.0](LICENSE). If you run a modified copy as a website, you have to publish your changes under the same licence.
