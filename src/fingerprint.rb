require_relative 'parser'

REPORTS_DIR = File.expand_path("../reports", __dir__)

# ---- helpers --

def normalize_trace(trace)
  # retire le buffer pour avoir des traces identiques entre ref et test
  # trace.reject { |t| t.start_with?("eco_buffer_0") }
    trace.reject do |tok|
       edge, node = tok.split(":", 2)
       node && node.start_with?("eco_buffer_0")
    end
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
    puts "Violation: #{ki} vs #{kj} - expected #{ref}, got #{test}" if test != ref
  end

  [v, used]
end

# ---- main ----
f_clean = File.join(REPORTS_DIR, "all_paths_sansHT.rpt")
f_test  = File.join(REPORTS_DIR, "all_paths_withHT2.rpt")

paths_clean = parse_timing_repo(f_clean)
paths_test  = parse_timing_repo(f_test)

m_clean = build_delay_map(paths_clean)
m_test  = build_delay_map(paths_test)

th = 0.05  
fp = build_fingerprint(m_clean, th)
violations, used = count_violations(fp, m_test, th)

rate = used.zero? ? 0.0 : violations.to_f / used

puts "Pairs in fingerprint: #{fp.size}"
puts "Violations: #{violations}"
puts "Violation rate: #{(rate * 100).round(2)}%"

