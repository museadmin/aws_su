
# Match AWS_ACCESS_KEY_ID
class MatchesAwsAccessKeyId
  def self.===(item)
    item.include?('AWS_ACCESS_KEY_ID')
  end
end