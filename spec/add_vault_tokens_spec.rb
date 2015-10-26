require 'spec_helper'
require 'psych'

describe AddVaultTokens do
  before do
    allow(ENV).to receive(:fetch).with('VAULT_ADDR') { 'https://example.com' }
    allow(ENV).to receive(:fetch).with('VAULT_ENV', nil) { 'staging' }
    allow(ENV).to receive(:fetch).with('VAULT_MASTER_TOKEN') { '123' }
    # Define a list of known policies for testing purposes.
    allow(Vault.sys).to receive(:policies) do
      ['staging-api', 'staging-app1', 'staging-app2']
    end
  end

  def token_double(value='fake_token')
    double(auth: double(client_token: value))
  end

  it 'has a version number' do
    expect(AddVaultTokens::VERSION).not_to be nil
  end

  it 'connects to vault using VAULT_ADDR and VAULT_MASTER_TOKEN' do
    expect(Vault).to receive(:address=).with('https://example.com')
    expect(Vault).to receive(:token=).with('123')
    AddVaultTokens.connect
  end

  it 'can issue a single token' do
    expect(Vault.auth_token).to receive(:create)
      .with(name: 'staging-api', policies: ['staging-api'])
      .and_return(token_double('new_token'))

    result = AddVaultTokens.create_token_for('staging-api')
    expect(result.auth.client_token).to eq('new_token')
  end

  it 'can update a JSON structure with appropriate tokens' do
    # Stub out create_token_for this time, so we don't need to worry about
    # exactly which arguments it uses.
    expect(AddVaultTokens).to receive(:create_token_for)
      .with('staging-app1').and_return(token_double('app1-token'))
    expect(AddVaultTokens).to receive(:create_token_for)
      .with('staging-app2').and_return(token_double('app2-token'))

    input = <<YAML
app1:
  image: example/app1
  environment:
    VAR: "value"

app2:
  image: example/app2

unknown:
  image: example/unknown
YAML
    output = AddVaultTokens.add_tokens_to_apps(Psych.load(input), prefix: "staging-")
    expected = <<YAML
app1:
  image: example/app1
  environment:
    VAR: "value"
    VAULT_ADDR: "https://example.com"
    VAULT_ENV: "staging"
    VAULT_TOKEN: "app1-token"

app2:
  image: example/app2
  environment:
    VAULT_ADDR: "https://example.com"
    VAULT_ENV: "staging"
    VAULT_TOKEN: "app2-token"

unknown:
  image: example/unknown
YAML
    expect(output).to eq(Psych.load(expected))
  end
end
