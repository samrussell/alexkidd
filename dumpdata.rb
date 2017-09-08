input_filename, output_filename, start, length = ARGV

File.open(input_filename, mode="rb") do |input_file|
  input_file.seek(start.to_i)
  data = input_file.read(length.to_i)
  File.open(output_filename, mode="wb") do |output_file|
    output_file.write(data)
  end
end