class Circuit
  attr_accessor :name, :inputs, :outputs, :wires, :gates

  def initialize(name: nil)
    @name = name
    @inputs = []
    @outputs = []
    @wires = []
    @gates = []
  end

  def fanout_gates(signal)
    @gates.select { |g| g.inputs.include?(signal) }
  end


  def output_load(gate)
    sinks = fanout_gates(gate.output)
    load = sinks.sum(&:input_capacitance)
    load += 1.0 if @outputs.include?(gate.output)
    load = 1.0 if load == 0.0

    load
  end

  def electrical_effort(gate)
    cin = gate.input_capacitance
    cout = output_load(gate)

    return 1.0 if cin == 0.0
    cout / cin
  end

  def gate_delay(gate)
    h = electrical_effort(gate)
    gate.delay(h)
  end
end

class NetlistParser
  def parse_file(path)
    content = File.read(path)
    circuit = Circuit.new
    content.each_line do |line|
      line.strip!
        next if line.empty? || line.start_with?('//')
        if line.start_with?('module')
            m = line.match(/^module\s+(\w+)/)
            circuit.name = m[1] if m
        elsif line.start_with?('input')
            circuit.inputs += parse_signal_list(line.sub('input', ''))
        elsif line.start_with?('output')
            circuit.outputs += parse_signal_list(line.sub('output', ''))
        elsif line.start_with?('wire')
            circuit.wires += parse_signal_list(line.sub('wire', ''))
        else
            gate = parse_gate_instance(line)    
            circuit.gates << gate if gate
        end
    end
    circuit
  end


    
  
  def parse_signal_list(str)
        str.sub(';', '').split(',').map(&:strip).reject(&:empty?)

  end

  def parse_gate_instance(line)
    m = line.match(/(\w+)\s+(\w+)\s*\((.*)\);/)
    return nil unless m

    gate_type = m[1]
    gate_name = m[2]
    ports = m[3].split(',').map(&:strip)

    gate_output = ports[0]
    gate_inputs = ports[1..-1]

    gate_class = case gate_type.upcase
                 when 'AND', 'OR'  # TODO : add more composite gates 
                   CompositeGate
                 else
                   Gate
                 end

    gate_class.new(
      type: gate_type,
      name: gate_name,
      output: gate_output,
      inputs: gate_inputs
    )
  end



end