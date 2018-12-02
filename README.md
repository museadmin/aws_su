# AwsSu

AwsSu is a gem developed for a specific use case, where the user has an ID setup in an AWS master account and wants to 
assume a role in another account that they have permission to assume.

## Installation

Add this line to your application's Gemfile:

```ruby
  gem 'aws_su'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_su

## Usage

Implemented as a Ruby Module, the gem can be included into any class that needs to authenticate and assume
a role prior to calling one of the aws client methods like so:

```ruby
    require 'aws_su'
    
    class RunAwsSu
      include AwsSu
    end
    
    run_aws_su = RunAwsSu.new
    run_aws_su.authenticate(
      profile: 'ds-nonprod',
      duration: '28800',
      region: 'eu-west-2'
    )
    run_aws_su.ec2_client.describe_vpcs
```

The gem expects to find the standard aws secrets files:

- ~/.aws/credentials
- ~/.aws/config

With the former containing the master account secrets:

```[master]
   aws_access_key_id = XXXXXXXXXXXXXX
   aws_secret_access_key = XXXXXXXXXXXXXXXXXXXX
```

And the latter containing the details of the role to be assumed:

```
    [profile my-profile]
    source_profile=master
    mfa_serial=arn:aws:iam::1234567890:mfa/bradley.atkins@bjss.com
    role_arn=arn:aws:iam::1234567890:role/MY-NONPROD-TESTER-ROLE
```

AwsSu also configures the current shell with the necessary environment variables to allow system calls to 
be made without further authentication:

```ruby
  system('aws ec2 describe-vpcs --region eu-west-2')
```

Clients currently supported are:

- ec2_client
- elb_client
- iam_client
- sqs_client

After you use the authenticator, running the AWS CLI from the command line is possible via the 
assumed role if you add this function to your ~/.bashrc or ~/bash_profile file:

```
    function awssu() {
        while read line
        do
            export "${line}"
        done < ~/.awssudo
        export AWS_DEFAULT_REGION="${1:-eu-west-2}" # Change to your default region
    }
```

If you have a valid session still available then you can enter:

```bash
    awssu eu-west-1
``` 

The region is optional and will default to eu-west-2 unless you change the default in the function.
 
This will call the function which will export the contents of the environment variables 
and then you can run the CLI without further authentication.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [The Github Repository](https://github.com/museadmin/aws_su). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AwsSudo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/aws_sudo/blob/master/CODE_OF_CONDUCT.md).
