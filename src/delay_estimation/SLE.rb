
class Gate
  attr_accessor :type, :name, :output, :inputs

  def initialize(type:, name:, output:, inputs:)
    @type = type.upcase
    @name = name
    @output = output
    @inputs = inputs
  end

  def delay(h)
    le = logical_effort
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
  def delay(h)
    case @type
    when 'AND'
      nand = Gate.new(type: 'NAND', name: "#{@name}_nand", output: 'n1', inputs: @inputs, h: h)
      inv  = Gate.new(type: 'INV',  name: "#{@name}_inv",  output: @output, inputs: ['n1'], h: 1.0)
      nand.delay(h) + inv.delay(1.0)

    when 'OR'
      nor = Gate.new(type: 'NOR', name: "#{@name}_nor", output: 'n1', inputs: @inputs, h: h)
      inv = Gate.new(type: 'INV', name: "#{@name}_inv", output: @output, inputs: ['n1'], h: 1.0)
      nor.delay(h) + inv.delay(1.0)

    else
      raise "Unsupported type #{@type}"
    end
  end
end


class Path
  attr_accessor :gates

  def initialize(gates)
    @gates = gates
  end

  def delay(circuit)
    raise ArgumentError, 'Missing circuit for delay calculation' unless circuit

    @gates.sum { |g| circuit.gate_delay(g) } # we ignore wire delay for now
  end
end



# g1 = CompositeGate.new(type: 'AND', name: 'G1', output: 'Y', inputs: ['A', 'B'], h: 2.0)
# g2 = CompositeGate.new(type: 'OR',  name: 'G2', output: 'Z', inputs: ['A', 'B'], h: 2.0)
# g3 = Gate.new(type: 'NAND', name: 'G3', output: 'W', inputs: ['A', 'B'], h: 2.0)

# path1 = Path.new([g1, g2])
# puts "AND-OR path delay = #{path1.delay}"


# puts "AND delay = #{g1.delay}"
# puts "OR delay  = #{g2.delay}"
# puts "NAND delay = #{g3.delay}"