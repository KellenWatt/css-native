require "date"
Gem::Specification.new do |s|
  # Required
  s.name = "css-native"
  s.version = "0.1.1"
  s.summary = "CSS generation made cleaner"
  s.author = "Kellen Watt"
  s.files = Dir["lib/**/*"]
  
  # Recommended
  s.license = "MIT"
  s.description = "A CSS generator designed to make writing CSS-compatible code cleaner and easier to undestand"
  s.date = Date.today.strftime("%Y-%m-%d")
  s.homepage = "https://github.com/KellenWatt/css-native"
  s.metadata = {}
  
  
  # Optional and situational - delete or keep, as necessary
  # s.bindir = "bin"
  # s.executables = []
  # s.required_ruby_version = ">= 2.5" # Sensible default
end
