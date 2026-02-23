GNUPLOT    = "C:/Program Files/gnuplot/bin/gnuplot.exe"
REPORTS_DIR = File.expand_path("../reports", __dir__)
require_relative "parser"

def write_dat(datfile, paths, x_index, jitter)
  File.open(datfile, "w") do |f|
    paths.each do |p|
      x = x_index[p["startpoint"]] + jitter
      f.puts "#{x} #{p["delay"]} #{p["endpoint"]}"
    end
  end
end

def plot(out_png, x_labels, series)
  out_png = File.expand_path(out_png).gsub("\\", "/")
  gp_file = File.expand_path("plot.gp").gsub("\\", "/")

  xtics = x_labels.each_with_index.map { |lab,i| "'#{lab}' #{i}" }.join(", ")
  plots = series.map do |s|
    dat = File.expand_path(s[:dat]).gsub("\\", "/")
    "'#{dat}' using 1:2 with points title '#{s[:name]}', '' using 1:2:3 with labels offset 0,0.8 notitle"
  end.join(", ")

  gp = <<~GP
    set terminal pngcairo size 1600,800
    set offset graph 0.03, graph 0.03, graph 0.03, graph 0.03
    set output '#{out_png}'
    set grid
    set key right top
    set xlabel 'Input'
    set ylabel 'Delay'
    set xtics (#{xtics})
    set pointsize 1.8
    plot #{plots}
  GP

  File.write(gp_file, gp)
  system(GNUPLOT, gp_file)
end

# - main -
f0 = File.join(REPORTS_DIR, "all_paths_sansHT.rpt")
f1 = File.join(REPORTS_DIR, "all_paths_withHT.rpt")

p0 = parse_timing_repo(f0)
p1 = parse_timing_repo(f1)

x_labels = (p0.map{|p| p["startpoint"]} + p1.map{|p| p["startpoint"]}).uniq.sort
x_index  = x_labels.each_with_index.to_h

write_dat("no_ht.dat",   p0, x_index, -0.12)
write_dat("with_ht.dat", p1, x_index,  0.12)

plot("comparison.png", x_labels, [
  {name: "No HT",   dat: "no_ht.dat"},
  {name: "With HT", dat: "with_ht.dat"}
])