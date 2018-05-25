namespace :docs do
  namespace :compile do


    desc "Compile DOT files in doc/"
    task :dot, :paths do |t, args|
      output_types = %w{png pdf}

      dotfiles = Array(args.paths).
        select{|p| p.match(/\.dot$/)}.
        map{|f| [f, File.dirname(f), File.basename(f, ".*") ]}.
        to_a

      puts " * Compiling DOT files in doc/"
      dotfiles.each do |dotfile|
        output_types.each do |format|
          input_filename = dotfile.first
          output_filename = "#{dotfile[1]}/#{dotfile.last}.#{format}"
          puts "  - #{input_filename} => #{output_filename}"
          system("dot -T#{format} '#{input_filename}' -o '#{output_filename}'")
        end
      end
    end


  end

end
