# frozen_string_literal: true

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

system('aws ec2 describe-vpcs --region eu-west-2')

