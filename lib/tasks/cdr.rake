namespace :cdr do
  namespace :cleanup do

    desc 'Delete recordings from blacklist'
    task blacklist: :environment do 
      filename = 'recording_blacklist.csv'      
      file_path = File.join(Rails.root,'config',filename)
      raise 'Blacklist not found at #{file_path}}' unless File.exist?(file_path)
      data = CSV.read(file_path)
      numbers = data[1..-1].map{|r| PhoneNumber.format_phone(r[1])}

      puts "*** Deleting any call recordings associated with call data records from the following numbers..."
      numbers.each{|n| puts "#{n}"}
      puts

      Cdr.delete_recordings_from(numbers)

      puts "DONE\n!"
    end 

  end
end
