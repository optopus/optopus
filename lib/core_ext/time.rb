class Time
  def time_ago
    num = Time.now.to_i - self.to_i
    puts num
    return "just now" if num < 10
    return "#{num} seconds ago" if num < 60
    num = num / 60
    return "#{num} minutes ago" if num < 60
    num = num / 60
    return "#{num} hours ago" if num < 24
    num = num / 24
    return "#{num} days ago" if num < 365
    num = num / 365
    return "#{num} years ago"
  end
end
