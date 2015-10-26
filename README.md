# `add-vault-tokens`

This is a short script for use with [vault](https://vaultproject.io/) and
[docker-compose](https://docs.docker.com/compose/).  Given a
`docker-compose.yml` file and a `VAULT_MASTER_TOKEN` as input, this script
will generate a new, limited vault token for each application described in
the `docker-compose.yml` file.

You can install this as:

```sh
gem install add-vault-tokens
```

## Usage

Assume you have a `docker-compose.yml` containing:

```yml
app:
  image: "example/app"

service:
  image: "example/service"
```

Also assume that your vault server has two policies defined, named `app`
and `service`.  First, you need to create a `VAULT_MASTER_TOKEN` for use
with `add-vault-tokens`:

```sh
vault token-create -policy=app -policy=service
```

Then you run `add-vault-tokens` as follows:

```
# The URL of your vault server.
export VAULT_ADDR=https://...

# The master token you just generated.
export VAULT_MASTER_TOKEN=...

# Generate tokens
add-vault-tokens docker-compose.yml
```

This will update `docker-compose.yml` to include new environment variables:

```yml
app:
  image: "example/app"
  environment:
    VAULT_ADDR="https://..."
    # A new token with policy "app":
    VAULT_TOKEN="..."

service:
  image: "example/service"
  environment:
    VAULT_ADDR="https://..."
    # A new token with policy "service":
    VAULT_TOKEN="..."
```

If a `VAULT_ENV` environment variable is present, it will also be added to
the `docker-compose.yml` file.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/faradayio/add-vault-tokens.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

