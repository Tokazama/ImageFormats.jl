"""
    TypeStream{T,S}

# Arguments
`io::IO`
`endianness::UInt32`: the format that the stream is saved as `LittlEndian` or
    `BigEndian` which are const values for 0x01020304 and 0x04030201, respectively.
    default value is users `ENDIAN_BOM` so that streams are not swapped by default.
    Should specify the file formats encoding.

```
#NOTMYENDIAN = ifelse(ENDIAN_BOM == 0x01020304, :BigEndian, :LittleEndian)

testfile = "/tmp/typestream.bin"

s = TypeStream{Int}(open(testfile, "w+"))
io = open(testfile, "w+")
A = [1:10...]
write(io, A)
close(io)
s = TypeStream{Int}(open(testfile))
```
"""
# IO subtyping gave ambiguity errors
# looks to be related to using unsafe_read(::TypeStream, ::Ptr{T}...) instead offset
# Ptr{UInt8}, but that makes the byte swapping complicated 
mutable struct TypeStream{T,S} <: IO
    io::IO
    ownstream::Bool
end

const LittleEndian = 0x01020304
const BigEndian = 0x04030201

TypeStream{T}(io::IO, endianness::UInt32=ENDIAN_BOM, ownstream::Bool=false) where T =
    TypeStream{T,ENDIAN_BOM != endianness}(io, ownstream)

TypeStream{T}(f::AbstractString, mode::AbstractString, endianness::Symbol) where T =
    TypeStream{T}(open(f, mode), endianness, true)

Base.eltype(::Type{<:TypeStream{T}}) where {T} = @isdefined(T) ? T : Any
needswap(::Type{<:TypeStream{T,S}}) where {T,S} = @isdefined(S) ? S : false

FileIO.stream(s::TypeStream) = s.io
Base.eltype(s::TypeStream{T}) where T = T
needswap(s::TypeStream{T,S}) where {T,S} = S

@inline Base.convert(::Type{TS}, s::TS) where {TS<:TypeStream} = s
@inline Base.convert(::Type{TS}, s::TypeStream) where {TS<:TypeStream} = TS(s.io)

################
# IO Interface #
################
Base.position(s::TypeStream) = position(stream(s))

Base.seekstart(s::TypeStream) = (seekstart(stream(s)); s)
Base.seekend(s::TypeStream) = (seekend(stream(s)); s)
Base.seek(s::TypeStream, n::Int) = seek(stream(s), n)

Base.skip(s::TypeStream, offset::Integer) = (skip(stream(s), offset); s)
Base.eof(s::TypeStream) = eof(stream(s))
Base.close(s::TypeStream) = s.ownstream && close(stream(s))
Base.isopen(s::TypeStream) = isopen(stream(s))
Base.isreadable(s::TypeStream) = isreadable(stream(s))
Base.iswritable(s::TypeStream) = iswritable(stream(s))
Base.ismarked(s::TypeStream) = ismarked(stream(s))
Base.reset(s::TypeStream) = reset(stream(s))
Base.unmark(s::TypeStream) = unmark(stream(s))
Base.mark(s::TypeStream) = mark(stream(s))
Base.bytesavailable(s::TypeStream) = bytesavailable(stream(s))
Base.readbytes!(s::TypeStream) = error("TypeStream cannot be read byte wise")

#Base.countlines(s::TypeStream) = countlines(stream(s))
#Base.skipchars(predicate, s::TypeStream; linecomment=nothing) = skipchars(predicate, stream(s), linecomment=nothing)


# should make readuntil work
#Base.readuntil_vector!(s::TypeStream, target::AbstractVector{T}, keep::Bool, out) where {T} =
#    Base.readuntil_vector!(stream(s), target, keep, out)
#Base.readline
#Base.readlines
#Base.copy
#Base.readavailable(s::TypeStream{T}) where T = readavailable(stream(s))
#Base.lock(::IO) = nothing
#Base.unlock(::IO) = nothing
#Base.eachline

# Make sure all IO streams support flush, even if only as a no-op,
# to make it easier to write generic I/O code.
#Base.flush(s::TypeStream) = flush(stream(s))

Base.unsafe_read(s::TypeStream{T,false}, p::Ptr{UInt8}, n::UInt) where T = unsafe_read(stream(s), p, n)
@inline function Base.unsafe_read(s::TypeStream{T,true}, ptr::Ptr{UInt8}, n::UInt) where T
    sz = sizeof(T)
    itr = UInt(0)
    buf = Vector{UInt8}(undef, sz)
    while itr < n
        reverse!(read!(stream(s), buf))
        # Count from outside edge to middle
        for i = 0:(sz-1)
            unsafe_store!(ptr+i+itr, buf[i+1])
        end
        itr += sz
    end
    nothing
end

Base.unsafe_write(s::TypeStream{T,false}, p::Ptr{UInt8}, n::UInt) where T = unsafe_write(stream(s), p, n)
@inline function Base.unsafe_write(s::TypeStream{T,true}, p::Ptr{UInt8}, n::UInt) where T
    sz = sizeof(T)
    written::Int = 0
    while written < n
        for i in 0:(sz-1)
            write(stream(s), unsafe_load(p, sz-i+written))
        end
        written += sz
    end
    return written
end



##############
# Conversion #
##############
@inline Base.read(s::TypeStream{Tr}, ::Type{Ts}) where {Tr<:RawType,Ts<:SinkType} =
    convert(Ts, read!(s, Ref{Tr}(0))[]::Tr)::Ts
@inline Base.write(s::TypeStream{Tr}, val::Ts) where {Tr<:RawType,Ts<:SinkType} =
    write(s, Ref(convert(Tr, val)))

# Mapped #
# ------ #
#Base.read!(s::TypeStream{F,T}, sink::AbstractArray) where {F,T} = error("cannot mmap directly to sink")
Base.read(s::TypeStream{F,T}) where {F,T} = read(stream(s), sink{Tuple{size(s)...},eltype(s),ndims(s),length(s)})
Base.read(s::TypeStream{F,T}, sink::Type{Array{T,N}}) where {F,T,N} = Mmap.mmap(stream(s), Array{T,N}, size(s))

# read to type #
# Array
Base.read(s::TypeStream{F,T}, sink::Type{<:Array}, mmap::Val{true}) where {F,T} = Mmap.mmap(stream(s), Array{T,N}, size(s))

# StaticArray
#Base.read(s::TypeStream{F,T}, sink::Type{<:StaticArray}, mmap::Val{true}) where {F,T} = read(stream(s), sink{Tuple{size(s)...},T,N,length(s)})
#    fixendian(read(stream(s), sink{Tuple{size(sink)...},T,ndims(sink),length(sink)}), s)
writeto!(s::TypeStream, a::AbstractArray{<:RawType}) =
    GC.@preserve a unsafe_writeto(s, pointer(a), length(a))

@inline function unsafe_readto(s::TypeStream{Tr}, ptr::Ptr{Ts}, n::UInt) where {Tr,Ts}
    for i in 1:n
        unsafe_store!(ptr, convert(Ts, read(s, Tr)), n)
    end
    nothing
end

@inline function unsafe_writeto(s::TypeStream{Tr}, ptr::Ptr{Ts}, n::UInt) where {Tr,Ts}
    written::Int = 0
    for i in 1:n
        written += write(s, convert(Tr, unsafe_load(ptr, i)))
    end
    return written
end
