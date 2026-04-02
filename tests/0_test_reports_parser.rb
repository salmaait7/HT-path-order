require_relative "../src/delay/parser"
file = "reports/paths.rpt"
  if File.exist?(file)
    puts "Test (#{file}):"
    paths = parse_timing_repo(file)
    puts "  Chemins trouvés: #{paths.length}"
    # if paths.size > 0
    #   first_key, first_delay = paths.first['startpoint'], paths.first['delay']
    #   puts "  Premier chemin: #{first_key.inspect} => #{first_delay}"
    # end
  else
    puts "Fichier test non trouvé: #{file}"
  end