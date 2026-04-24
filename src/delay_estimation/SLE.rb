
class Gate
  attr_accessor :type, :name, :output, :inputs

  def initialize(type:, name:, output:, inputs:)
    @type = type.upcase
    @name = name
    @output = output
    @inputs = inputs
  end

  def delay(load_cap)
    le = logical_effort
    h = load_cap.to_f / input_capacitance
    le[:p] + le[:g] * h
  end

  def input_count
    @inputs.length
  end


  def input_capacitance
    n = input_count

    case @type
    when 'INV'
      1.0
    when 'NAND'
      (n + 2.0) / 3.0
    when 'NOR'
      (2.0 * n + 1.0) / 3.0
    else
      1.0
    end
  end


  def logical_effort
    n = input_count

    case @type
    when 'INV', 'NOT'
      { g: 1.0, p: 1.0 }

    when 'NAND'
      { g: (n + 2.0) / 3.0, p: n.to_f }

    when 'NOR'
      { g: (2.0 * n + 1.0) / 3.0, p: n.to_f }

    else
      raise "Unsupported gate type #{@type}"
    end
  end

end

class CompositeGate < Gate
  def delay(load_cap)
    case @type
    when 'AND'
      first_stage = Gate.new(type: 'NAND', name: "#{@name}_nand", output: 'n1', inputs: @inputs)
      second_stage = Gate.new(type: 'INV', name: "#{@name}_inv", output: @output, inputs: ['n1'])

    when 'OR'
      first_stage = Gate.new(type: 'NOR', name: "#{@name}_nor", output: 'n1', inputs: @inputs)
      second_stage = Gate.new(type: 'INV', name: "#{@name}_inv", output: @output, inputs: ['n1'])

    else
      raise "Unsupported type #{@type}"
    end

    first_stage.delay(second_stage.input_capacitance) + second_stage.delay(load_cap)
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



