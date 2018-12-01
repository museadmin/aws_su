# frozen_string_literal: true

require 'aws_su'

class Runner
  include AwsSu
end

runner = Runner.new

runner.authenticate('ds-nonprod')

system('aws ec2 describe-vpcs --region eu-west-2')

