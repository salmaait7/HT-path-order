
class Gate
  attr_reader :type, :input_pins, :output_pin, :logical_effort, :parasitic_delay,
              :input_capacitance_map

  def initialize(type:, input_pins:, output_pin:, logical_effort:, 
                 parasitic_delay:, input_capacitance_map:)
    @type = type.upcase
    @input_pins = input_pins
    @output_pin = output_pin
    @logical_effort = logical_effort
    @parasitic_delay = parasitic_delay
    @input_capacitance_map = input_capacitance_map
  end

  def input_capacitance(pin = nil)
 
      return @input_capacitance_map.values.sum / @input_capacitance_map.size
  
  end

  def delay(load_cap, input_pin = nil)
    cin = input_capacitance(input_pin)
    cout = load_cap.to_f
    h = cout / cin
    g = @logical_effort
    p = @parasitic_delay
    g * h + p
  end
end

class CellLibrary
  attr_reader :cells

  def initialize
    @cells = {}
    load_standard_cells
  end

  def get_cell(type)
    cell = @cells[type.upcase]
    raise "type '#{type}' not found" unless cell
    cell
  end

  def cell_exists?(type)
    @cells.key?(type.upcase)
  end

  def add_cell(cell)
    @cells[cell.type] = cell
  end

  private

  def load_standard_cells

    add_cell(Gate.new(
      type: 'INV',
      input_pins: ['A'],
      output_pin: 'Y',
      logical_effort: 1.0,
      parasitic_delay: 1.0,
      input_capacitance_map: { 'A' => 1.0 }
    ))

  
    add_cell(Gate.new(
      type: 'BUF',
      input_pins: ['A'],
      output_pin: 'Y',
      logical_effort: 2.0,
      parasitic_delay: 2.0,
      input_capacitance_map: { 'A' => 1.0 }
    ))

    # NAND 
    add_cell(Gate.new(
      type: 'NAND',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 4.0 / 3.0,
      parasitic_delay: 2.0,
      input_capacitance_map: { 'A' => 4.0 , 'B' => 4.0 }
    ))

    # NOR
    add_cell(Gate.new(
      type: 'NOR',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 5.0 / 3.0,
      parasitic_delay: 2.0,
      input_capacitance_map: { 'A' => 5.0, 'B' => 5.0  }
    ))

    # AND (nand+inv)
    add_cell(Gate.new(
      type: 'AND',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 4.0 / 3.0 + 1.0,
      parasitic_delay: 2.0 + 1.0,
      input_capacitance_map: { 'A' => 4.0 , 'B' => 4.0}
    ))

    # OR
    add_cell(Gate.new(
      type: 'OR',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 5.0 / 3.0 + 1.0,
      parasitic_delay: 2.0 + 1.0,
      input_capacitance_map: { 'A' => 5.0, 'B' => 5.0  }
    ))

    # XOR
    add_cell(Gate.new(
      type: 'XOR',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 2.4,
      parasitic_delay: 4.0,
      input_capacitance_map: { 'A' => 2.0, 'B' => 2.0 }
    ))

    # XNOR
    add_cell(Gate.new(
      type: 'XNOR',
      input_pins: ['A', 'B'],
      output_pin: 'Y',
      logical_effort: 2.4,
      parasitic_delay: 4.0,
      input_capacitance_map: { 'A' => 2.0, 'B' => 2.0 }
    ))
  end
end
class Path
  include Enumerable

  attr_accessor :gates, :startpoint, :endpoint

  def initialize(gates, startpoint = nil, endpoint = nil)
    @gates = gates
    @startpoint = startpoint
    @endpoint = endpoint
  end

  def node_trace
    trace = []
    trace << @startpoint if @startpoint
    trace.concat(@gates.map(&:name))
    trace << @endpoint if @endpoint && @endpoint != @startpoint
    trace
  end

  def each(&block)
    node_trace.each(&block)
  end

  def join(separator = $,, &block)
    node_trace.join(separator, &block)
  end

  def to_a
    node_trace.dup
  end

  def delay(circuit)
    @gates.sum { |g| circuit.gate_delay(g) } # we ignore wires delay for now
  end
end




