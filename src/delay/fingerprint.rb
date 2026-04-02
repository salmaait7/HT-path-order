require_relative 'parser'
# ---- helpers --

def normalize_trace(trace)
  # retire le buffer pour avoir des traces identiques entre ref et test
  trace.reject { |t| t.start_with?("eco_buffer_0") }
    # trace.reject do |tok|
    #    edge, node = tok.split(":", 2)
    #    node && node.start_with?("eco_buffer_0")
    # end
end

def build_delay_map(paths)
  m = {}

  paths.each do |p|
    next if p['delay'].nil?

    trace = p['trace']
    norm_trace = normalize_trace(trace)

    key = [p['startpoint'], p['endpoint'], norm_trace.join('|')]
  # key = [p['startpoint'], p['endpoint']]

    m[key] = p['delay']
  end

  m
end

def label(di, dj, th)
  return '~' if dj == 0
  ((di - dj) / dj) > th ? '>' : '~'
end

def build_fingerprint(delay_map_clean, th)
  keys = delay_map_clean.keys.sort
  fp = {}

  keys.each_with_index do |ki, i|
    (i + 1...keys.length).each do |j|
      kj = keys[j]
      fp[[ki, kj]] = label(delay_map_clean[ki], delay_map_clean[kj], th)
    end
  end

  fp
end

def count_violations(fp, delay_map_test, th)
  v = 0
  used = 0

  fp.each do |(ki, kj), ref|
    next unless delay_map_test.key?(ki) && delay_map_test.key?(kj)

    test = label(delay_map_test[ki], delay_map_test[kj], th)
    used += 1
    v += 1 if test != ref
    # puts "Violation: #{ki} vs #{kj} - expected #{ref}, got #{test}" if test != ref
  end

  [v, used]
end



