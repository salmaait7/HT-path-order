require_relative '../src/src.rb'


circuit = NetlistParser.new.parse_file(ARGV[0])
alt_circuit = NetlistParser.new.parse_file(ARGV[1])

clean_map = build_delay(circuit, circuit.outputs[0]).merge(build_delay(circuit, circuit.outputs[1]))
fp = build_fingerprint(clean_map, 1.0)
alt_map = build_delay(alt_circuit, alt_circuit.outputs[0]).merge(build_delay(alt_circuit, alt_circuit.outputs[1]))


violations, total = count_violations(fp, alt_map, 1.0)
puts "Total : #{total}, Violations: #{violations}"

