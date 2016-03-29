# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'add_vault_tokens/version'

Gem::Specification.new do |spec|
  spec.name          = "add-vault-tokens"
  spec.version       = AddVaultTokens::VERSION
  spec.authors       = ["Eric Kidd"]
  spec.email         = ["git@randomhacks.net"]

  spec.summary       = %q{Issue per-application Vault tokens to apps in docker-compose.yml}
  spec.description   = %q{Given a master vault token, issue short-lived, per-application tokens to each app in a docker-compose.yml file, restricting each app the to corresponding security policy.}
  spec.homepage      = "https://github.com/faradayio/add-vault-tokens"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "vault", "~> 0.3.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
