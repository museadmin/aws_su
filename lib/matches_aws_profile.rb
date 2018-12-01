
# Match AWS_PROFILE
class MatchesAwsProfile
  def self.===(item)
    item.include?('AWS_PROFILE')
  end
end