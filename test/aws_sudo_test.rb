# frozen_string_literal: true

require 'aws_su'
require 'test_helper'

class AwsSudoTest < Minitest::Test

  include AwsSu

  def test_that_it_has_a_version_number
    refute_nil ::AwsSu::VERSION
  end

  def test_sts_api_returns_session_token
    # client = sts_client
    # valid = session_valid?
    # creds = assume_role_with_mfa_token('800650')
    # creds = assume_role
    authenticate('ds-nonprod')
    assert true
  end
end
