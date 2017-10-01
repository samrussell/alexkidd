input_filename, output_filename, sprite_number = ARGV

File.open(input_filename, mode="rb") do |input_file|
  File.open(output_filename, mode="wb") do |output_file|
    base_pointer = sprite_number.to_i * 2 + 0x10000
    input_file.seek(base_pointer)
    # get address of sprite data
    # will be $8201 for example but is $10000 in file
    sprite_data_pointer = input_file.read(2).unpack("S")[0] + 0x8000
    input_file.seek(sprite_data_pointer)
    # read number of sprites
    num_sprites = input_file.read(1).ord
    # get the pointer to each sprite
    sprite_pointers = num_sprites.times.map { input_file.read(2).unpack("S")[0] + 0x8000 }
    # then read them out - all are 24 bytes with zero 4th byte on each one
    sprite_data = sprite_pointers.map do |sprite_pointer|
      input_file.seek(sprite_pointer)
      packed_sprite = input_file.read(24)
      packed_sprite.chars.each_slice(3).map { |slice| slice + ["\x00".force_encoding('ASCII-8BIT')] }.join
    end

    output_file.write(sprite_data.join)
  end
end