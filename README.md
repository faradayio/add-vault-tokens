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

First, you need to create a security policy `master-token.hcl` for the
master token:

```hcl
# Mandatory for all policies.
path "auth/token/lookup-self" {
  policy = "read"
}

# Allow listing all available policies, so we can decide which child tokens
# to generate.
path "sys/policy" {
  policy = "sudo"
}

# Allow creation of child tokens.
path "auth/token/create" {
  policy = "write"
}

# Allow renewal of this token.
#
# SECURITY - HACK - We can't just allow renewal via `renew-self` in 0.3, so
# allow renewal of _any_ token as the next best substitute.
path "auth/token/renew/*" {
  policy = "sudo"
}
```

This can be loaded using:

```sh
vault policy-write master-token master-token.hcl
```

Then you need to define two new policies, `app` and `service`, specifying
which secrets can be accessed by each container.  Once this is done, you
can create your `VAULT_MASTER_TOKEN` for use with `add-vault-tokens`:

```sh
vault token-create -policy=master-token -policy=app -policy=service
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
the `docker-compose.yml` file, and the policy names will be prefixed by
`$VAULT_ENV-`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/faradayio/add-vault-tokens.

## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

