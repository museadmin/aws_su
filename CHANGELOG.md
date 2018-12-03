# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [0.1.0] - 01-12-2018
### Added
- Ability to authenticate and switch role via a single authenticate() method
- Gemspec file updated to enable push to Rubygems.org

## [0.1.1] - 02-12-2018
### Added
- Required ruby version in gemspec
- Housekeeping now that gem is on both github and rubygems
- Changed authenticate() method to accept options hash
- Added detailed header to AwsSu module

## [0.1.2] - 02-12-2018
### Changed
- Order of precedence for setting region
1. As optional argument to authenticate()
2. Active profile in ~/.aws/config
3. First profile in ~/.aws/config

## [0.1.5] - 03-12-2018
### Added
- Added export of AWS_DEFAULT_REGION

## [0.1.6] - 03-12-2018
### Removed
- export of AWS_PROFILE

## [0.1.7] - 03-12-2018
### Changed
- For MFA, export awssudo file
- For existing session, export sts creds