# REPORTS_DIR = File.expand_path("../reports", __dir__)
NUM = /(?:\d+(?:\.\d*)?|\.\d+)/

def parse_timing_repo(filename)
  content  = File.read(filename)
  sections = content.split('Startpoint:')[1..] || []

  paths = []

  sections.each do |section|
    lines = section.lines

    startpoint = lines[0].split('(')[0].strip

    endpoint_line = lines.find { |l| l.start_with?('Endpoint:') }
    next unless endpoint_line
    endpoint = endpoint_line.split('Endpoint:')[1].split('(')[0].strip

    trace = []
    delay = nil
    in_trace = false

    lines.each do |line|

      if line.include?('(in)')
        in_trace = true
        next
      end

      if in_trace && line.include?('(out)')
        in_trace = false
      end

      if in_trace && !line.strip.empty?
       if (m = line.match(/^\s*#{NUM.source}\s+#{NUM.source}\s+([\^v])\s+(\S+)\s*\(/))
          edge = m[1]
          signal = m[2]
          trace << "#{edge}:#{signal}"
        end
      end

     
      if line.include?('data arrival time')
        m = line.match(/(#{NUM.source})\s+data arrival time/)
        delay = m[1].to_f if m
      end
    end

    next if delay.nil?

    paths << {
      'startpoint' => startpoint,
      'endpoint'   => endpoint,
      'delay'      => delay,
      'trace'      => trace
    }
  end

  # keep only max delay per path
  best = {}
  paths.each do |p|
    key = [p['startpoint'], p['endpoint'], p['trace'].join('|')]
    if !best.key?(key) || p['delay'] > best[key]['delay']
      best[key] = p
    end
  end

  best.values
end



  # file = File.join(REPORTS_DIR, 'all_paths_sansHT.rpt')
  # if File.exist?(file)
  #   puts "Test (#{file}):"
  #   paths = parse_timing_repo(file)
  #   puts "  Chemins trouvés: #{paths.length}"
  #   # if paths.size > 0
  #   #   first_key, first_delay = paths.first['startpoint'], paths.first['delay']
  #   #   puts "  Premier chemin: #{first_key.inspect} => #{first_delay}"
  #   # end
  # else
  #   puts "Fichier test non trouvé: #{file}"
  # end

