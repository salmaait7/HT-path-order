def select_paths(circuit)
    paths = []
    circuit.outputs.each do |output|
        find_paths_to_output(circuit, output)
    end
    paths
end

def find_paths_to_output(circuit, output)
  if circuit.inputs.include?(output)
    return [[output]]
  end
  paths = []
  circuit.gates.select { |gate| gate.output == output }.each do |gate|
    gate.inputs.each do |input|
      sub_paths = find_paths_to_output(circuit, input)
      sub_paths.each do |sub_path|
        paths << sub_path + [gate.name] + [output]
      end
    end
  end
  paths
end
