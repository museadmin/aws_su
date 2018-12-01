# frozen_string_literal: true

require 'aws_su'

class Runner
  include AwsSu
end

runner = Runner.new
runner.authenticate('ds-nonprod')
runner.ec2_client.describe_vpcs



system('aws ec2 describe-vpcs --region eu-west-2')

