module BlueskyWeb
  VERSION = ((File.read(File.join(__dir__,'VERSION'))) rescue '0.0.0').chomp
end
