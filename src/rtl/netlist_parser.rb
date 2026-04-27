class Circuit
  attr_accessor :name, :inputs, :outputs, :wires, :gates, :cell_lib

  def initialize(name: nil, cell_lib: nil)
    @name = name
    @inputs = []
    @outputs = []
    @wires = []
    @gates = []
    @cell_lib = cell_lib || CellLibrary.new
  end

  def fanout_gates(signal)
    @gates.select { |g| g.inputs.include?(signal) }
  end

  def driving_gate(signal)
    @gates.find { |g| g.output == signal }
  end

  def output_load(gate)
    sinks = fanout_gates(gate.output)
    load = sinks.sum do |sink_gate|
      pin = sink_gate.connections.find { |k, v| v == gate.output }&.first
      sink_gate.input_capacitance(pin)
    end
    
    load += 2.0 if @outputs.any? { |out| out.name == gate.output }
    load = 1.0 if load == 0.0

    load
  end


  def gate_delay(gate)
    load = output_load(gate)
    gate.delay(load)
  end

  def find_paths_to_output(output_signal)
    output_name = output_signal.is_a?(CircuitSignal) ? output_signal.name : output_signal
    
    if inputs.any? { |inp| inp.name == output_name }
      return [Path.new([], output_name, output_name)]
    end

    paths = []
    gates.select { |g| g.output == output_name }.each do |gate|
      gate.inputs.each do |input|
        sub_paths = find_paths_to_output(input)
        sub_paths.each do |sub_path|
          paths << Path.new(sub_path.gates + [gate], sub_path.startpoint, output_name)
        end
      end
    end
    paths
  end
end

class CircuitSignal
  attr_reader :name, :msb, :lsb

  def initialize(name, msb: nil, lsb: nil)
    @name = name
    @msb = msb
    @lsb = lsb
  end

  def bus?
    !@msb.nil?
  end

  def width
    bus? ? (@msb - @lsb).abs + 1 : 1
  end

  def to_s
    bus? ? "#{@name}[#{@msb}:#{@lsb}]" : @name
  end
end

class GateInstance
  attr_reader :type, :name, :connections, :cell
  attr_accessor :output, :inputs

  def initialize(type:, name:, connections:, cell_lib:)
    @type = type
    @name = name
    @connections = connections
    @cell_lib = cell_lib
    
    @cell = @cell_lib.get_cell(type)
    
    @output = @connections[@cell.output_pin]
    @inputs = @cell.input_pins.map { |pin| @connections[pin] }.compact
  end

  def input_capacitance(pin = nil)
    @cell.input_capacitance(pin)
  end

  def delay(load_cap, input_pin = nil)
    @cell.delay(load_cap, input_pin)
  end

  def to_s
    "#{@type} #{@name} (#{@connections.map { |k, v| ".#{k}(#{v})" }.join(', ')})"
  end
end

class NetlistParser
  def initialize(cell_lib: nil)
    @cell_lib = cell_lib || CellLibrary.new
    @in_multi_line_cmt = false
  end

  def parse_file(path)
    content = File.read(path)
    parse(content)
  end

  def parse(content)
    circuit = Circuit.new(cell_lib: @cell_lib)
    
    content = remove_comments(content)
    
    content.each_line.with_index do |line, line_num|
      begin
        line = line.strip
        
        next if line.empty? || line.start_with?('//')
        
        if line.start_with?('module')
          circuit.name = parse_module_name(line)
          
        elsif line.start_with?('input')
          circuit.inputs.concat(parse_signal_declaration(line, 'input'))
          
        elsif line.start_with?('output')
          circuit.outputs.concat(parse_signal_declaration(line, 'output'))
          
        elsif line.start_with?('wire')
          circuit.wires.concat(parse_signal_declaration(line, 'wire'))
          
        elsif line.start_with?('endmodule')
          # End of module
          
        else
          gate = parse_gate_instance(line)
          circuit.gates << gate if gate
        end

      rescue => e
        # Error handling for individual lines
        # puts "Warning: Error parsing line #{line_num}: #{e.message}"
      end
    end
    
    circuit
  end

  def remove_comments(content)
    content.gsub(/\/\*.*?\*\//m, '')
  end

  def parse_module_name(line)
    match = line.match(/module\s+(\w+)/)
    match ? match[1] : 'unknown'
  end 

  def parse_signal_declaration(line, keyword)
    line = line.sub(/^#{keyword}\s+/, '').sub(/;.*$/, '').strip
    
    signals = []
    
    # Check for buses
    if line =~ /\[(\d+):(\d+)\]/
      msb = $1.to_i
      lsb = $2.to_i
      line = line.sub(/\[\d+:\d+\]/, '').strip
      
      names = line.split(',').map(&:strip).reject(&:empty?)
      names.each do |name|
        signals << CircuitSignal.new(name, msb: msb, lsb: lsb)
      end
    else
      # Simple signals (no bus)
      names = line.split(',').map(&:strip).reject(&:empty?)
      names.each do |name|
        signals << CircuitSignal.new(name)
      end
    end
    
    signals
  end

  def parse_gate_instance(line)
    # Format 1: gate_type instance_name (out, in1, in2, ...);
    # Format 2: gate_type instance_name (.Y(out), .A(in1), .B(in2));
    
    return nil unless line.include?('(') && line.include?(')')
    
    match = line.match(/^(\w+)\s+(\w+)\s*\((.+)\);?/)
    return nil unless match
    
    gate_type = match[1]
    instance_name = match[2]
    ports_str = match[3]
    
    return nil unless @cell_lib.cell_exists?(gate_type)
  
    connections = parse_port_connections(ports_str, gate_type)
    GateInstance.new(
      type: gate_type,
      name: instance_name,
      connections: connections,
      cell_lib: @cell_lib
    )
  end

  def parse_port_connections(ports_str, gate_type)
    connections = {}
    cell = @cell_lib.get_cell(gate_type)
    
    ports_str = ports_str.strip
    
    if ports_str.include?('.')
      ports_str.scan(/\.(\w+)\(([^)]+)\)/).each do |pin, signal|
        signal = signal.strip
        next if signal =~ /^\d+'b[01]$/ || signal == '1' || signal == '0'
        connections[pin] = signal
      end
    else

      signals = ports_str.split(',').map(&:strip)
      connections[cell.output_pin] = signals[0] if signals[0]
      cell.input_pins.each_with_index do |pin, idx|
        signal = signals[idx + 1]
        next unless signal
        next if signal =~ /^\d+'b[01]$/ || signal == '1' || signal == '0'
        connections[pin] = signal
      end
    end
    
    connections
  end
end