local HttpService = game:GetService("HttpService")
local EncodingService = game:GetService("EncodingService")
local Zstd = {}

Zstd.CompressBuffer = function(Buffer, CompressionLevel)
	return EncodingService:CompressBuffer(Buffer, Enum.CompressionAlgorithm.Zstd, CompressionLevel)
end

Zstd.DecompressBuffer = function(Buffer)
	return EncodingService:DecompressBuffer(Buffer, Enum.CompressionAlgorithm.Zstd)
end

Zstd.Compress = function(String, CompressionLevel)
	local Buffer = buffer.fromstring(String)
	
	return buffer.tostring(Zstd.CompressBuffer(Buffer, CompressionLevel))
end

Zstd.Decompress = function(String)
	local Buffer = buffer.fromstring(String)

	return buffer.tostring(Zstd.DecompressBuffer(Buffer))
end

return Zstd
