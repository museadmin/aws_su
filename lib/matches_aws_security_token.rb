
# Match AWS_SECURITY_TOKEN
class MatchesAwsSecurityToken
  def self.===(item)
    item.include?('AWS_SECURITY_TOKEN')
  end
end