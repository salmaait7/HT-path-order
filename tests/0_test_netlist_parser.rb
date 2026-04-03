require_relative '../src/src.rb'

parser = NetlistParser.new
circuit = parser.parse_file(ARGV[0])

puts "Circuit: #{circuit.name}"
puts "Inputs : #{circuit.inputs.inspect}"
puts "Outputs: #{circuit.outputs.inspect}"
puts "Wires  : #{circuit.wires.inspect}"
puts "Gates  :"

circuit.gates.each do |g|
    puts "  #{g.type} #{g.name}: out=#{g.output}, in=#{g.inputs.inspect}"
end

# get possible paths to outputs
circuit.outputs.each do |output|
    puts "Paths to output #{output}:"
    find_paths_to_output(circuit, output).each do |path|
        puts "  Path: #{path.join(' -> ')}"
    end
end

