# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_sudo/version'

Gem::Specification.new do |spec|
  spec.name          = 'aws_su'
  spec.version       = AwsSu::VERSION
  spec.authors       = ['Bradley Atkins']
  spec.email         = ['Bradley.Atkins@bjss.com']

  spec.summary       = 'Gem to wrap helper methods around AWS authentication API'
  spec.description   = 'Developed for a specific use case: ' \
      'User has an AWS id in a master account and wants to assume'\
      ' a role in another account. This module exposes a single'\
      'authenticate() method that handles authentication and switching role '\
      'by referencing the user\'s aws secrets.'
  spec.homepage      = 'https://github.com/museadmin'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://localhost:9292/'

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = "Put your gem's public repo URL here."
    spec.metadata['changelog_uri'] = "Put your gem's CHANGELOG.md URL here."
  else
    raise 'RubyGems >= 2.0 is required to protect against public gem pushes'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'awsecrets'
  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
