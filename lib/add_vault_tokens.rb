require "vault"
require "add_vault_tokens/version"

module AddVaultTokens
  class << self
    def connect
      return if @connected
      @connected = true
      Vault.address = ENV.fetch('VAULT_ADDR')
      Vault.token = ENV.fetch('VAULT_MASTER_TOKEN')
    end

    def have_policy_for?(app_name)
      @policies ||= Vault.sys.policies
      @policies.include?(app_name)
    end

    def create_token_for(app_name)
      Vault.auth_token.create(name: app_name, policies: [app_name])
    end

    def add_tokens_to_apps(app_info, prefix: "")
      result = Marshal.load(Marshal.dump(app_info))
      result.each do |app_name, info|
        full_app_name = prefix + app_name
        if have_policy_for?(full_app_name)
          STDERR.puts("Issuing token for #{full_app_name}")
          token = create_token_for(full_app_name)
          info['environment'] ||= {}
          info['environment']['VAULT_ADDR'] = ENV.fetch('VAULT_ADDR')
          info['environment']['VAULT_TOKEN'] = token.auth.client_token
        else
          STDERR.puts("WARNING: No policy for #{full_app_name}, so no token issued")
        end
      end
      result
    end
  end
end
