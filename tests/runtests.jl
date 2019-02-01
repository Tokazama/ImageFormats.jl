using Tests

testfile = "/tmp/typestream.bin"
io = open(testfile, "w+")
A = [1:10...]
write(io, A)
close(io)
NOTMYENDIAN = ifelse(ENDIAN_BOM == 0x01020304, :BigEndian, :LittleEndian)


@testset "TypeStreams" begin
    include("./typestreams.jl")
end
