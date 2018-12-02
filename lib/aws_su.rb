# frozen_string_literal: true

require 'aws_config'
require 'matches'
require 'awsecrets'
require 'aws_su/version'

# Set up the AWS authentication environment for a user
# who has an ID in a master account and is allowed to
# switch to a role in another account.
#
# Typical usage scenario:
#
#   require 'aws_su'
#
#   class RunAwsSu
#   include AwsSu
#   end
#
#   run_aws_su = RunAwsSu.new
#   run_aws_su.authenticate(
#     profile: 'ds-nonprod',
#     duration: '28800',
#     region: 'eu-west-2'
#   )
#   run_aws_su.ec2_client.describe_vpcs
#
# also sets up current shell so system calls don't need further authentication:
#
#   system('aws ec2 describe-vpcs --region eu-west-2')
#
# It is assumed that the region is set in the first profile in .aws/config, e.g.
#
#   [profile master]
#   region=eu-west-2
#
# or it can be set in the call to authenticate() as shown above
#
module AwsSu
  class Error < StandardError; end

  AWS_SUDO_FILE = Dir.home + '/.awssudo'
  AWS_CONFIG_FILE = Dir.home + '/.aws/config'
  DURATION = '28800'
  @profile = nil                  # name of current profile
  @token_ttl = nil                # The session expiry
  @session = nil                  # Name of the active session
  @duration = DURATION            # Session duration in seconds
  @master_config = Awsecrets.load # AWS config for master account

  # Authenticate user for the session
  # @param options Hash {
  #   duration: 'AWS role session timeout',
  #   region: AWS region,
  #   profile: Name of profile in .aws/config to use
  # }
  def authenticate(options = {})
    @session = "aws-su-session-#{Time.now.to_i}"
    @profile = options[:profile]
    @duration = options[:duration].nil? ? DURATION : options[:duration]
    @token_ttl = calculate_session_expiry(@duration)

    region = AWSConfig.profiles.first[1][:region]
    @region = options[:region].nil? ? region : options[:region]
    raise('Unable to determine region') if @region.nil?

    export_aws_sudo_file
    assume_role
  end

  # Configure the ec2 client
  def ec2_client
    Aws::EC2::Client.new
  end

  # Configure the elb client
  def elb_client
    Aws::ElasticLoadBalancing::Client.new
  end

  # Configure the IAM client
  def iam_client
    Aws::IAM::Client.new
  end

  # Configure the S3 client
  def s3_client
    Aws::S3::Client.new
  end

  # SQS Client
  def sqs_client
    Aws::SQS::Client.new
  end

  # STS
  def sts_client
    Aws::STS::Client.new(
      credentials: load_secrets,
      region: @region
    )
  end

  private

  # Assume a role
  # @param duration A string integer representing the role session duration
  def assume_role(duration = DURATION)
    if session_valid?
      # Recover persisted session and use that to update AWS.config
      Aws.config.update(
        credentials: Aws::Credentials.new(
          parse_access_key,
          parse_secret_access_key,
          parse_session_token
        )
      )
    else
      # Session has expired so auth again
      assume_role_mfa(duration)
    end
    # For the benefit of anything downstream we are running
    export_aws_sudo_file
  end

  # Assume a role using an MFA Token
  def assume_role_mfa(duration, mfa_code = nil)
    mfa_code = prompt_for_mfa_code if mfa_code.nil?
    role_creds = sts_client.assume_role(
      role_arn: AWSConfig[@profile]['role_arn'],
      role_session_name: @session,
      duration_seconds: duration.to_i,
      serial_number: AWSConfig[@profile]['mfa_serial'],
      token_code: mfa_code.to_s
    )
    update_aws_config(role_creds)
    persist_aws_su(role_creds)
  end

  # Calculate the session expiration
  # # @param duration A string integer representing the role session duration
  def calculate_session_expiry(duration = DURATION)
    (Time.now + duration.to_i).strftime('%Y-%m-%d %H:%M:%S')
  end

  # Get the values for AWS secrets etc and export them to the environment
  def export_aws_sudo_file
    return unless File.exists?(AWS_SUDO_FILE)

    File.readlines(AWS_SUDO_FILE).each do |line|
      case line
      when MatchesAwsAccessKeyId
        ENV['AWS_ACCESS_KEY_ID'] = line.split('=')[1].strip
      when MatchesAwsSecretAccessKey
        ENV['AWS_SECRET_ACCESS_KEY'] = line.split('=')[1].strip
      when MatchesAwsSessionToken
        ENV['AWS_SESSION_TOKEN'] = line.split('=')[1].strip
      when MatchesAwsSecurityToken
        ENV['AWS_SECURITY_TOKEN'] = line.split('=')[1].strip
      when MatchesAwsTokenEtl
        ENV['AWS_TOKEN_TTL'] = line.split('=')[1].strip
      when MatchesAwsProfile
        ENV['AWS_PROFILE'] = line.split('=')[1].strip
      end
    end
  end

  # Export the AWS values to the ENV
  def export_config_to_environment(config)
    ENV['AWS_ACCESS_KEY_ID'] = config.credentials.access_key_id
    ENV['AWS_SECRET_ACCESS_KEY'] = config.credentials.secret_access_key
    ENV['AWS_SESSION_TOKEN'] = config.credentials.session_token
    ENV['AWS_SECURITY_TOKEN'] = config.credentials.session_token
    ENV['AWS_TOKEN_TTL'] = @token_ttl
    ENV['AWS_PROFILE'] = @profile
  end

  # Load the user's AWS Secrets
  def load_secrets
    Awsecrets.load
  end

  # Parse the secret access key from awssudo
  def parse_access_key
    File.readlines(AWS_SUDO_FILE).each do |line|
      return line.split('=')[1].chomp if line.include?('AWS_ACCESS_KEY')
    end
  end

  # Parse the secret access key from awssudo
  def parse_secret_access_key
    File.readlines(AWS_SUDO_FILE).each do |line|
      return line.split('=')[1].chomp if line.include?('AWS_SECRET_ACCESS_KEY')
    end
  end

  # Parse the session token from awssudo
  def parse_session_token
    File.readlines(AWS_SUDO_FILE).each do |line|
      return line.split('=')[1].chomp if line.include?('AWS_SESSION_TOKEN')
    end
  end

  # Recover the persisted session timeout from AWSSUDO file
  def parse_ttl_timeout
    File.readlines(AWS_SUDO_FILE).each do |line|
      return line.split('=')[1].chomp if line.include?('AWS_TOKEN_TTL')
    end
  end

  # Persist the config to the awssudo file
  # @param config Credentials from assume role to persist
  # @param file The temporary secrets file ~/.awssudo
  def persist_aws_su(config, file = AWS_SUDO_FILE)
    File.open(file, 'w') do |f|
      f.puts('AWS_ACCESS_KEY_ID=' + config.credentials.access_key_id)
      f.puts('AWS_SECRET_ACCESS_KEY=' + config.credentials.secret_access_key)
      f.puts('AWS_SESSION_TOKEN=' + config.credentials.session_token)
      f.puts('AWS_SECURITY_TOKEN=' + config.credentials.session_token)
      f.puts('AWS_TOKEN_TTL=' + @token_ttl)
      f.puts('AWS_PROFILE=' + @profile)
    end
  end

  # Prompt the user to supply and MFA code
  def prompt_for_mfa_code
    puts 'Enter MFA code: '
    mfa_token_code = gets.chomp
    return mfa_token_code unless mfa_token_code.nil? || mfa_token_code.empty?
    raise(Error, 'No code supplied, aborting')
  end

  # See if we have a valid session or if it has expired
  def session_valid?
    return false unless File.exists?(AWS_SUDO_FILE)
    File.readlines(AWS_SUDO_FILE).each do |line|
      next unless line.include?('AWS_TOKEN_TTL')
      aws_token_ttl = line.split('=')[1]
      return true if Time.parse(aws_token_ttl) > Time.now
      return false
    end
    false
  end

  # Update the Aws.config
  def update_aws_config(role_creds)
    Aws.config.update(
      credentials: Aws::Credentials.new(
        role_creds.credentials.access_key_id,
        role_creds.credentials.secret_access_key,
        role_creds.credentials.session_token
      )
    )
  end

end
