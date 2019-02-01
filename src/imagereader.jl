"""
using ImageForm, FileIO
io = IOBuffer()
axs = (Axis{:x}(1:10), Axis{:y}(1:10))
props = ImageProperties{format"UNKOWN"}(Dict{String,Any}())
# specify all
ImageReader{format"UNKOWN",false,Int,2,typeof(axs)}(io, axs, props, false)

# specify first 4
ImageReader{format"UNKOWN",false,Int,2}(io, axs, props, false)


ImageReader(io, Int, 
"""
struct ImageReader{F,S<:Tuple,Ax}
    io::TypeStream
    axes::Ax
    properties::ImageProperties{F}
end

ImageReader(s::TypeStream, axes::Ax, props::ImageProperties{F}) where {F,Ax} =
    ImageReader{F,Tuple{map(length,axes)...},Ax}(s, axes, props)

# abstractarray interface
Base.size(reader::ImageReader{F,S}, i::Int) where {F,S} = S.parameters[i]
Base.size(reader::ImageReader{F,S}) where {F,S} = (S.parameters...,)
Base.length(reader::ImageReader) = prod(size(reader))
Base.eltype(reader::ImageReader) = eltype(s.io)
Base.ndims(reader::ImageReader) = length(size(s))
Base.axes(reader::ImageReader, i::Int) = reader.axes[i]
Base.axes(reader::ImageReader) = reader.axes

# IO interface
FileIO.stream(reader::ImageReader) = stream(reader.io)


function ImageReader{F,S}(io::IO, axes::Ax, props::ImageProperties{F},
                            needswap::Bool=false, ownstream::Bool=false) where {F,S,Ax}
    ImageReader{F,S,Ax}(io, axes, props, ownstream)
end
function ImageReader{F,S}(io::IO, axes::Ax, needswap::Bool, ownstream::Bool=false;
                            kwargs...) where {F,S,Ax}
    ImageReader{F,S,Ax}(io, axes, ImageProperties{F}(; kwargs...), needswap, ownstream)
end


# create from array
ImageReader{F,S}(io::IO, A::AbstractArray{T,N}, props::ImageProperties{F}, ownstream::Bool=false) where {F,S,T,N} =
    ImageReader{F,S,T,N}(io, AxisArrays.axes(A), props, needswap, ownstream)
ImageReader{F,S}(io::IO, A::AbstractArray{T,N}, ownstream::Bool=false; kwargs...) where {F,S,T,N} =
    ImageReader{F,S,T,N}(io, AxisArrays.axes(A), ImageProperties{F}(; kwargs...), ownstream)
ImageReader{F,S}(io::IO, A::AbstractArray{T,N}, props::Dict{String,Any}, ownstream::Bool=false) where {F,S,T,N} =
    ImageReader{F,S}(io, AxisArrays.axes(A), ImageProperties{F}(props), ownstream)

"""
    imagestreaming(File)
    imagestreaming(Stream)

Each format should provide a `FileIO.metadata` method that receives a FileIO
`Stream` and extracts the appropriate information to construct an `ImageReader`.

Only difference between reading from `File` and `Stream` is that `File` has
ownership over the stream so that upon gc the ImageReader from a `File` is
closed. Original stream must be closed elsewhere if fed to `imagestreaming`.
"""
imagestreaming(f::File{F}) where F = imagestreaming(open(f), true)
imagestreaming(s::Stream{F}, ownstream::Bool=false) where F = ImageReader(metadata(s), ownstream)


Base.setindex!(r::ImageReader, X, propname::AbstractString) = setindex!(r.properties, X, propname)
Base.getindex(r::ImageReader, propname::AbstractString) = r.properties[propname]


function showreader(io::IO, s::ImageReader{F,S,Ax}) where {F,S,Ax}
    print(io, "$(join([size(s)...], "x")), $(eltype(s)) ImageReader\n")
    print(io, "  ImageFormat: $(F.parameters[1])\n")
    print(io, "  Axes:\n")
    for i in s.axes
        print(io, "    $(axisnames(i)[1]), $(i.val)\n")
    end
    print(io, "Properties:\n")
    ImageMetadata.showdictlines(io, s.properties.d, Set([]))
end

Base.show(io::IO, r::ImageReader) = showreader(io, s)
Base.show(io::IO, ::MIME"text/plain", s::ImageReader) = showreader(io, s)

########
# Load #
########
Base.read(s::ImageReader{F,<:RawType}) where {F} =
    ImageMeta(AxisArray(read!(s, Array{eltype(s)}(undef, size(s))), axes(s)), properties(s))

# TODO
function updateaxes!(s::ImageReader, a::AxisArray)
    return nothing
end
# TODO
function updateproperties!(s::ImageReader, a::ImageMeta)
    return nothing
end

Base.read!(s::ImageReader, a::AxisArray) = (updateaxes!(s,a); read!(s, a.data))
Base.read!(s::ImageReader, a::ImageMeta) = (updateproperties!(s,a); read!(s, a.data))
Base.read!(s::ImageReader, a::SizedArray) = read!(s, a.data)

Base.read!(s::ImageReader{<:RawType}, a::AbstractArray{T}) where {T<:SinkType} = readto!(stream(s), a)
Base.read(s::ImageReader, a::Type{<:AbstractArray{T}}) where {T<:SinkType} = transform(T, read(s))


########
# Save #
########
"""
savestream should just work with any Arrayformat and Stream, as long as a given
format has appropriately specified a transform! function, which is called by
write. See transform! for more details.
"""
#image_savestreaming(s::File{F}, A::ArrayFormat) where F = image_savestreaming(open(f), true)
#image_savestreaming(s::Stream{F}, A::ArrayFormat, ownstream::Bool=false) where F =
#    ImageReader(stream(s), A, ownstream)

#function Base.write(f::File{F}, A::ImageFormat; kwargs...) where F
#    savestreaming(f, A; kwargs...) do s
#        write(s, A; kwargs...)
#    end
#end

#Base.write(r::ImageReader{DataFormat{sym}}) where sym =
#    error("Writing an ImageReader is not supported for the $sym DataFormat.")

##########
# Update #
##########
"""
    update!(ImageReader{F})

If a given format (`F`) requires information to be read between blocks of array
like structs then `update` may be used to facilitate this. Each format must
specify this function independently. 

# Example
```
s = loadstreaming(f)  # reads metadata/header info
# read 1st chunk of data
update!(s)  
read(s)
# read 2nd chunk of data
update!(s)  
read(s)
```
"""
update!(r::ImageReader{F}) where F = error("Updating an ImageReader the $sym DataFormat.")

