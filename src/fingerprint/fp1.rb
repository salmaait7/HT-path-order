def build_delay(circuit, output)
    paths = circuit.find_paths_to_output(output)
    delay_map = {}

    paths.each do |path|
        delay = path.delay(circuit)
        p_sans_ht = path.node_trace.reject { |n| n.start_with?('HT') } #eviter le HT dans la trace
        key = [path.startpoint, path.endpoint, p_sans_ht]
        delay_map[key] = delay
    end

    delay_map
end

def build_fingerprint(delay_map, th)
    keys = delay_map.keys.sort
    fp = {}

    keys.each_with_index do |ki, i|
        (i + 1...keys.length).each do |j|
            kj = keys[j]
            fp[[ki, kj]] = label(delay_map[ki], delay_map[kj], th)
        end
    end

    fp
end


def label(di, dj, th)
  return '~' if dj == 0
  ((di - dj) / dj) > th ? '>' : '~'
end

def count_violations(fp, test_map, th)
  violations = 0
  used = 0
  fp.each do |(ki, kj), ref|
    used += 1
    test = label(test_map[ki], test_map[kj], th)
    violations += 1 if test != ref
    puts "Violation: #{ki} vs #{kj} - expected #{ref}, got #{test}" if test != ref
  end
  [violations, used]
end


