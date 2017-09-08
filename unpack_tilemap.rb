input_filename, output_filename = ARGV

rows = []

File.open(input_filename, "rb") do |input_file|
  4.times do
    data = []
    while true do
      # get byte
      coded_instructions = input_file.read(1).bytes[0]
      break if coded_instructions == 0
      # when bit 7 is unset, then we are repeating
      repeat = (coded_instructions & 0x80) == 0
      num_bytes = coded_instructions & 0x7F
      if repeat
        byte = input_file.read(1).bytes[0]
        num_bytes.times do
          data.push(byte)
        end
      else
        bytes = input_file.read(num_bytes).bytes
        data.push(*bytes)
      end
    end
    rows.push(data)
  end
end

File.open(output_filename, "wb") do |output_file|
  # first write out 0x20 0 bytes
  zero_bytes = [0] * 0x20
  output_file.write(zero_bytes.pack("C*"))

  first_row = rows[0]
  zipped_rows = first_row.zip(*rows[1..3])
  zipped_rows.each do |bytes|
    output_data = bytes.pack("C*")
    output_file.write(output_data)
  end
end