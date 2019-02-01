testfile = "/tmp/typestream.bin"
io = open(testfile, "w+")
A = [1:10...]
write(io, A)
close(io)
NOTMYENDIAN = ifelse(ENDIAN_BOM == 0x01020304, :BigEndian, :LittleEndian)
open(testfile)

@testset "Swapping" begin
    @testset "Swap" begin
        s = TypeStream{Int}(IOBuffer(), NOTMYENDIAN)
        @test needswap(s) == true
        write(s, 1)
        seek(s, 0)
        ret = read(s, Int)
        @test ret == 1
        @test isa(ret, Int)
        @test position(s) == 8
        seek(s, 0)
        ret = read(s, Float32)
        @test ret == Float32(1.0)
        @test isa(ret, Float32)
        close(s)
    end
    @testset "No Swap" begin
        s = TypeStream{Int}(open(testfile, "w+"))
        @test isreadable(s) == true
        @test iswritable(s) == true
        @test needswap(s) == false
        write(s, [1:10...])
        seek(s, 0)
        ret = read(s, Int)
        @test ret == 1
        @test isa(ret, Int)
        seek(s, 0)
        ret = read(s, Float32)
        @test ret == Float32(1.0)
        @test isa(ret, Float32)
        close(s)
    end
end

@testset "IO Interface" begin
    s = TypeStream{Int}(open(testfile))
    @test isreadable(s) == true
    @test iswritable(s) == false
    @test isopen(s) == true
    @testset "Field accessors" begin
        @test eltype(s) == Int
        @test isa(s, IO) == true
        @test isa(stream(s), IO) == true
    end
    @testset "IO Navigation" begin
        seekend(s)
        @test eof(s) == true
        seekstart(s)
        @test ismarked(s) == false
        @test mark(s)
        @test ismarked(s) == true
        @test position(s) == 0
        skip(s, 8)
        @test position(s) == 8
        reset(s)
        @test position(s) == 0
        @test ismarked(s) == false
        @test bytesavailable(s) == 80
        mark(s)
        unmark(s)
        @test ismarked(s) == false
    end
    close(s)
    @test isopen(s) == false
    # TODO: locks
end


@testset "TypeStream Conversion" begin
    s = TypeStream{Int}(open(testfile))

    ret = read(s, Int32)
    @test isa(ret, Int32)
    @test ret == 1

    ret = read(s, Float32)
    @test isa(ret, Float32)
    @test ret == 2.0

    ret = read(s, Float64)
    @test isa(ret, Float64)
    @test ret == 3.0
end

@testset "TypeStream → Array" begin
end
