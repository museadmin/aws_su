
# Match AWS_TOKEN_TTL
class MatchesAwsTokenEtl
  def self.===(item)
    item.include?('AWS_TOKEN_TTL')
  end
end