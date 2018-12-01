# frozen_string_literal: true

require 'aws_sudo'

class Runner

  include AwsSudo
end

runner = Runner.new

runner.authenticate('ds-nonprod')
runner.ec2_client.describe_vpcs

