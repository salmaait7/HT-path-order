require "csv"
require_relative "../src/src.rb"

#--config---

th = 0.11 
N_genuine  = 100
N_infected = 100

Inter_die = 0.435   # ±20%
Intra_die = 0.08   # ±8%
Noise = 0.003 # 0.3%

Seed_genuine = 42
Seed_infected = 99

#--- Random generation---

def rand_uniform(min, max, rng)
  min + (max - min) * rng.rand
end

def rand_gaussian(stddev, rng)
  u1 = rng.rand
  u2 = rng.rand
  z0 = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
  stddev * z0
end

#-- helpers---
def generate_synthetic_chips(
  delay_map,
  n_chips:,
  inter_die: Inter_die,
  intra_die: Intra_die,
  noise_n: Noise,
  rng: Random.new(3651)
)
  path_keys = delay_map.keys
  nominals = path_keys.map { |k| delay_map[k].to_f }

  chips = []

  n_chips.times do
    delta_inter = rand_uniform(-inter_die, inter_die, rng) # same for all paths in a chip
    chip_map = {}

    path_keys.each_with_index do |k, idx|
      d_nom = nominals[idx]
      delta_intra = rand_uniform(-intra_die, intra_die, rng) # independent intra

      d_var = d_nom * (1.0 + delta_inter) * (1 + delta_intra)
      noise_sigma = noise_n * d_nom
      eps = rand_gaussian(noise_sigma, rng)

        d_meas = d_var + eps
      # puts"the path hase a negatif delay #{d_meas}" if d_meas < 0.0
      d_meas = 0.0 if d_meas < 0.0

      chip_map[k] = d_meas
    end

    chips << chip_map
  end

  chips
end



def print_summary(title, s)
  puts "---- #{title} ----"
  puts "N              : #{s[:n]}"
  puts "Viol mean      : #{ s[:viol_mean]}"
  puts "Viol median    : #{s[:viol_median]}"
  puts "Viol min/max   : #{s[:viol_min]} / #{s[:viol_max]}"
  puts "Rate mean      : #{format('%.3f', s[:rate_mean])}"
  puts "Rate median    : #{format('%.3f', s[:rate_median])}"
  puts "Rate min/max   : #{format('%.3f', s[:rate_min])} / #{format('%.3f', s[:rate_max])}"
end



def summarize_results(rows)
  vals = rows.map { |r| r[:violations] }
  rates = rows.map { |r| r[:violation_rate] }

  mean = ->(arr) { arr.empty? ? 0.0 : arr.sum.to_f / arr.size }

  sorted_vals = vals.sort
  sorted_rates = rates.sort

  median = lambda do |arr|
    return 0.0 if arr.empty?
    n = arr.size
    n.odd? ? arr[n / 2] : (arr[n / 2 - 1] + arr[n / 2]).to_f / 2.0
  end

  {
    n: rows.size,
    viol_mean: mean.call(vals),
    viol_median: median.call(sorted_vals),
    viol_min: vals.min || 0,
    viol_max: vals.max || 0,
    rate_mean: mean.call(rates),
    rate_median: median.call(sorted_rates),
    rate_min: rates.min || 0.0,
    rate_max: rates.max || 0.0
  }
end


def plot_violation_rates(genuine_rows, infected_rows)

  puts "Plotting violation rates ..."

  gp = <<~GP
    set terminal pngcairo size 800,600
    set output "violation.png"
    set title "Violation Rates"
    set xlabel "Chip index"
    set ylabel "Violation rate"
    set key left top
    plot \
      "-" using 1:2 with points pt 7 ps 1 title 'Genuine', \
      "-" using 1:2 with points pt 7 ps 1 title 'Infected'
  GP

  gp << genuine_rows.map { |r| "#{r[:chip_idx]} #{r[:violation_rate]}" }.join("\n")
  gp << "\ne\n"
  gp << infected_rows.map { |r| "#{r[:chip_idx]} #{r[:violation_rate]}" }.join("\n")
  gp << "\ne\n"


  IO.popen("gnuplot", "w") do |io|
    io.puts gp
  end

 
end

# ---- main ----
# f_clean = File.join(REPORTS_DIR, "all_paths_c432.rpt")
# infected  = File.join(REPORTS_DIR, "all_paths_alt_c432.rpt")
f_clean = File.join(REPORTS_DIR, "all_paths_sansHT.rpt")
infected  = File.join(REPORTS_DIR, "all_paths_withHT3.rpt")
paths_clean = parse_timing_repo(f_clean)
paths_inf  = parse_timing_repo(infected)

 puts "Building fingerprint..."

m_clean = build_delay_map(paths_clean)

fp = build_fingerprint(m_clean, th)


  puts "Generating synthetic chips..."
  genuine_chips = generate_synthetic_chips(
    m_clean,
    n_chips: N_genuine,
    rng: Random.new(Seed_genuine)
  )

  infected_chips = generate_synthetic_chips(
    paths_inf.empty? ? m_clean : build_delay_map(paths_inf), # fallback to clean if infected paths are missing
    n_chips: N_infected,
    rng: Random.new(Seed_infected)
  )

  puts "  genuine chips  : #{genuine_chips.size}"
  puts "  infected chips : #{infected_chips.size}"

  puts "Counting violations..."
  genuine_rows = genuine_chips.each_with_index.map do |chip_map, idx|
    v, used = count_violations(fp, chip_map, th)
    rate = used.zero? ? 0.0 : v.to_f / used
    { violations: v, total_pairs: used, violation_rate: rate, class: "genuine", chip_idx: idx }
  end

  infected_rows = infected_chips.each_with_index.map do |chip_map, idx|
    v, used = count_violations(fp, chip_map, th)
    rate = used.zero? ? 0.0 : v.to_f / used
    { violations: v, total_pairs: used, violation_rate: rate, class: "infected", chip_idx: idx }
  end


  puts "----Summary---"
  print_summary("GENUINE", summarize_results(genuine_rows))
  print_summary("INFECTED", summarize_results(infected_rows))
  plot_violation_rates(genuine_rows, infected_rows)



