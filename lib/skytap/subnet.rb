require 'skytap/ip_address'

class Subnet
  class InvalidSubnet < RuntimeError
  end

  attr_reader :size, :mask, :address

  def initialize(cidr_block)
    unless cidr_block =~ /^(.*)\/(.*)/
      raise InvalidSubnet.new 'Not in CIDR block form (XX.XX.XX.XX/YY)'
    end

    network = $1
    begin
      @size = Integer($2)
    rescue
      raise InvalidSubnet.new 'Invalid size'
    end

    @address = IpAddress.new(network)
    @mask = size_to_mask(@size)
  end

  def network_portion
    @network_portion ||= (mask & address)
  end
  alias_method :min, :network_portion

  def ==(other)
    other.is_a?(Subnet) && \
    (size == other.size) && \
    network_portion == other.network_portion
  end

  def overlaps?(other)
    min <= other.max && max >= other.min
  end

  def subsumes?(other)
    min <= other.min && max >= other.max
  end

  def strictly_subsumes?(other)
    subsumes?(other) && self != other
  end

  def max
    @max ||= (mask.inverse | network_portion)
  end

  def each_address
    (min.to_i..max.to_i).each{|i| yield IpAddress.new(i)}
  end

  def contains?(ip)
    ip = IpAddress.new(ip) unless ip.is_a?(IpAddress)
    (ip & mask) == network_portion
  end

  def num_addresses
    2 ** (32-size)
  end

  def min_machine_ip
    min + 1
  end

  def normalized?
    address == network_portion
  end

  def normalize
    Subnet.new("#{network_portion}/#{size}")
  end

  def to_s
    "#{address}/#{size}"
  end

  def <=>(other)
    to_s <=> other.to_s
  end

  private

  def size_to_mask(numbits)
    raise InvalidSubnet.new("Subnet size in bits must be between 0 and 32") unless numbits >= 0 and numbits <= 32
    IpAddress.new((2**numbits - 1) << (32 - numbits))
  end
end

