require_relative 'parser'

REPORTS_DIR = File.expand_path("../reports", __dir__)

# ---- helpers ----
def build_delay_map(paths, key_mode: :start_end)
  m = {}

  paths.each do |p|
    next if p['delay'].nil?

    key =
      case key_mode
      when :start_end
        [p['startpoint'], p['endpoint']]
      when :start_end_trace
        [p['startpoint'], p['endpoint'], p['trace'].join('|')]
      else
        raise "Unknown key_mode: #{key_mode}"
      end

    m[key] = p['delay'] if !m.key?(key) || p['delay'] > m[key]
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
  end

  [v, used]
end

# ---- main ----
f_clean = File.join(REPORTS_DIR, "all_paths_sansHT.rpt")
f_test  = File.join(REPORTS_DIR, "all_paths_withHT.rpt")

paths_clean = parse_timing_repo(f_clean)
paths_test  = parse_timing_repo(f_test)

m_clean = build_delay_map(paths_clean, key_mode: :start_end)
m_test  = build_delay_map(paths_test,  key_mode: :start_end)

th = 0.07  
fp = build_fingerprint(m_clean, th)
violations, used = count_violations(fp, m_test, th)

rate = used.zero? ? 0.0 : violations.to_f / used

puts "Threshold th = #{th}"
puts "Pairs in fingerprint: #{fp.size}"
puts "Violations: #{violations}"
puts "Violation rate: #{(rate * 100).round(2)}%"