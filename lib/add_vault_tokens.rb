require "vault"
require "add_vault_tokens/version"

module AddVaultTokens
  class << self
    # Connect if we haven't already.
    def connect
      return if @connected
      @connected = true
      Vault.address = ENV.fetch('VAULT_ADDR')
      Vault.token = ENV.fetch('VAULT_MASTER_TOKEN')
    end

    # Does our vault have a policy for app_name?
    def have_policy_for?(app_name)
      @policies ||= Vault.sys.policies
      @policies.include?(app_name)
    end

    # Renew our master token.  We do this in case it's getting old, in
    # which case we don't want to risk our generated tokens expiring early.
    def renew_master_token
      # TODO: Use renew_self as soon as it's available, so we don't need
      # the power to renew any arbitrary token.
      Vault.auth_token.renew(ENV.fetch('VAULT_MASTER_TOKEN'))
    end

    # Create a token for app_name with the appropriate security policy.
    def create_token_for(app_name)
      Vault.auth_token.create(name: app_name,
                              ttl: '720h',
                              policies: [app_name])
    end

    # Given a parsed `docker-compose.yml` file, return a new version with
    # appropriate vault-related environment variables injected.  If
    # specified, append `prefix` to each service name in the file before
    # looking up a policy.
    def add_tokens_to_apps(parsed_yaml, quiet: false, prefix: "")
      env = ENV.fetch('VAULT_ENV', nil)
      result = Marshal.load(Marshal.dump(parsed_yaml))
      result.each do |app_name, info|
        full_app_name = prefix + app_name
        if have_policy_for?(full_app_name)
          STDERR.puts("Issuing token for #{full_app_name}") unless quiet
          token = create_token_for(full_app_name)
          info['environment'] ||= {}
          info['environment']['VAULT_ADDR'] = ENV.fetch('VAULT_ADDR')
          info['environment']['VAULT_ENV'] = env if env
          info['environment']['VAULT_TOKEN'] = token.auth.client_token
        else
          unless quiet
            STDERR.puts("WARNING: No policy for #{full_app_name}, so no token issued")
          end
        end
      end
      result
    end
  end
end
