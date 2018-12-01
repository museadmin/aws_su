
# Match AWS_SECRET_ACCESS_KEY
class MatchesAwsSecretAccessKey
  def self.===(item)
    item.include?('AWS_SECRET_ACCESS_KEY')
  end
end