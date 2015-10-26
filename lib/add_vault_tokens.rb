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

    def create_token_for(service_name)
      Vault.auth_token.create(name: service_name, policies: [service_name])
    end

    def add_tokens_to_apps(app_info, prefix: "")
      result = Marshal.load(Marshal.dump(app_info))
      result.each do |app_name, info|
        token = create_token_for(prefix + app_name)
        info['environment'] ||= {}
        info['environment']['VAULT_ADDR'] = ENV.fetch('VAULT_ADDR')
        info['environment']['VAULT_TOKEN'] = token.auth.client_token
      end
      result
    end
  end
end
