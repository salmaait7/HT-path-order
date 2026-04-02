require_relative '../src/delay/fingerprint'
  f_clean = "reports/all_paths_sansHT.rpt"
  f_test  = "reports/all_paths_withHT3.rpt"

  paths_clean = parse_timing_repo(f_clean)
  paths_test  = parse_timing_repo(f_test)

  m_clean = build_delay_map(paths_clean)
  m_test  = build_delay_map(paths_test)

  th = 0.07
  fp = build_fingerprint(m_clean, th)
  violations, used = count_violations(fp, m_test, th)

  rate = used.zero? ? 0.0 : violations.to_f / used

  puts "Pairs in fingerprint: #{fp.size}"
  puts "Violations: #{violations}"
  puts "Violation rate: #{(rate * 100).round(2)}%"