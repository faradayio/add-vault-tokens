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

    # Create a token for app_name with the appropriate security policy.
    def create_token_for(app_name)
      Vault.auth_token.create(name: app_name, policies: [app_name])
    end

    # Given a parsed `docker-compose.yml` file, return a new version with
    # appropriate vault-related environment variables injected.  If
    # specified, append `prefix` to each service name in the file before
    # looking up a policy.
    def add_tokens_to_apps(parsed_yaml, prefix: "")
      env = ENV.fetch('VAULT_ENV', nil)
      result = Marshal.load(Marshal.dump(parsed_yaml))
      result.each do |app_name, info|
        full_app_name = prefix + app_name
        if have_policy_for?(full_app_name)
          STDERR.puts("Issuing token for #{full_app_name}")
          token = create_token_for(full_app_name)
          info['environment'] ||= {}
          info['environment']['VAULT_ADDR'] = ENV.fetch('VAULT_ADDR')
          info['environment']['VAULT_ENV'] = env if env
          info['environment']['VAULT_TOKEN'] = token.auth.client_token
        else
          STDERR.puts("WARNING: No policy for #{full_app_name}, so no token issued")
        end
      end
      result
    end
  end
end
