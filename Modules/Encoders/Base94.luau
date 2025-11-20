--!optimize 2
--!native
--!strict

local buffer_len=buffer.len
local buffer_create=buffer.create
local buffer_readu8=buffer.readu8
local buffer_writeu16=buffer.writeu16
local buffer_writeu8=buffer.writeu8
local buffer_copy=buffer.copy
local bit32_bor=bit32.bor
local bit32_lshift=bit32.lshift
local bit32_rshift=bit32.rshift
local bit32_band=bit32.band

local DIRECT_LOOKUP = {}
local BIT_MASK = {}

local ENCODE_MAP = {}
local DECODE_MAP = {}

local Base94 = {}

local j = 0
for i = 32, 127 do
	if i ~= 34 and i ~= 92 then
		ENCODE_MAP[j] = i
		DECODE_MAP[i] = j
		j += 1
	end
end

for entry = 0, 8835 do
	DIRECT_LOOKUP[entry] = bit32_bor(
		bit32_lshift(ENCODE_MAP[entry // 94], 8), 
		ENCODE_MAP[entry % 94]
	)
	
	BIT_MASK[entry] = (bit32_band(entry, 8191) < 644) and 14 or 13
end

function Base94.encode(input: buffer): buffer
	local length = buffer_len(input)
	
	local output = buffer_create(math.ceil(length * 1.25) + 2)

	local counter = 0
	local bits = 0
	local offset = 0

	for i = 0, length - 1 do
		counter = bit32_bor(counter, bit32_lshift(buffer_readu8(input, i), bits))
		bits += 8

		if bits > 13 then
			local entry = bit32_band(counter, 8191)
			
			if entry < 644 then
				entry = bit32_band(counter, 16383)
				counter = bit32_rshift(counter, 14)
				bits -= 14
			else
				counter = bit32_rshift(counter, 13)
				bits -= 13
			end
			
			buffer_writeu16(output, offset, DIRECT_LOOKUP[entry])
			offset += 2
		end
	end
	
	if bits > 0 then
		if bits > 7 or counter > 93 then
			buffer_writeu16(output, offset, DIRECT_LOOKUP[counter])
			offset += 2
		else
			buffer_writeu8(output, offset, ENCODE_MAP[counter])
			offset += 1
		end
	end

	local sliced = buffer_create(offset)
	buffer_copy(sliced, 0, output, 0, offset)

	return sliced
end

function Base94.decode(Input: buffer): buffer
	local InputLength = buffer_len(Input)
	local output = buffer_create(InputLength)

	local offset = 0
	local counter = 0
	local bits = 0
	local entry = -1

	for i = 0, InputLength - 1 do
		local val = DECODE_MAP[buffer_readu8(Input, i)]
		if entry == -1 then
			entry = val
		else
			entry += val * 94

			counter = bit32_bor(counter, bit32_lshift(entry, bits))
			bits += BIT_MASK[entry]
			
			if bits >= 16 then
				buffer_writeu16(output, offset, counter)
				offset += 2
				counter = bit32_rshift(counter, 16)
				bits -= 16
			elseif bits >= 8 then
				buffer_writeu8(output, offset, counter)
				offset += 1
				counter = bit32_rshift(counter, 8)
				bits -= 8
			end

			entry = -1
		end
	end
	
	if entry ~= -1 then
		counter = bit32_bor(counter, bit32_lshift(entry, bits))
		if bit32_bor(counter, 0) ~= 0 then
			if bits + (entry < 94 and 7 or 13) >= 8 then
				buffer_writeu8(output, offset, counter)
				offset += 1
			end
		end
	end
	
	local sliced = buffer_create(offset)
	buffer_copy(sliced, 0, output, 0, offset)

	return sliced
end

return Base94
