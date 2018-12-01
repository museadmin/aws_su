
# Match AWS_SESSION_TOKEN
class MatchesAwsSessionToken
  def self.===(item)
    item.include?('AWS_SESSION_TOKEN')
  end
end