# frozen_string_literal: true

require_relative 'lib/btc_sender/version'

Gem::Specification.new do |spec|
  spec.name = 'btc_sender'
  spec.version = BtcSender::VERSION
  spec.authors = ['T Zhuk']
  spec.email = ['tee0zed@gmail.com']

  spec.summary = 'Minimalistic tBTC and BTC sender.'
  spec.description = 'Minimalistic tBTC and BTC sender.'
  spec.required_ruby_version = '>= 2.7.7'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .gitlab-ci.yml appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'bitcoinrb'
  spec.add_runtime_dependency 'bundler'
  spec.add_runtime_dependency 'httparty'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
end
