require_relative '../src/src.rb'

parser = NetlistParser.new
circuit = parser.parse_file(ARGV[0])
puts "Circuit: #{circuit.name}"

gate_names = circuit.gates.map(&:name)

circuit.outputs.each do |output|
    puts "Paths to output #{output}:"
    find_paths_to_output(circuit, output).each do |path|
        puts "  Path: #{path.join(' -> ')}"
        gates_in_path = path.select { |elem| gate_names.include?(elem) }
        gate_objects = gates_in_path.map { |gname| circuit.gates.find { |g| g.name == gname } }
        path_obj = Path.new(gate_objects)
        puts "  Delay: #{path_obj.delay}"
    end
end

