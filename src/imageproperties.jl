"""
* spatialproperties
* header
* minimeta

"""
struct ImageProperties{F<:DataFormat} <: AbstractDict{String,Any}
    d::AbstractDict

    ImageProperties{F}(d::AbstractDict{String,Any}) where F = new{F}(d)
end

ImageProperties{F}(; kwargs...) where F = ImageProperties{F}(Dict{String,Any}([kwargs...]))

Base.setindex!(p::ImageProperties, X, propname::AbstractString) = setindex!(p.d, X, propname)
Base.getindex(p::ImageProperties, propname::AbstractString) = p.d[propname]

Base.copy(p::ImageProperties) = ImageFormat{F}(deepcopy(p.d))
Base.delete!(p::ImageProperties, key::String) = (delete!(p.d, key);p)
Base.empty!(p::ImageProperties) = (empty!(p.d);p)
Base.empty(p::ImageProperties{F}) where F = ImageProperties{F}()
Base.isempty(p::ImageProperties) = isempty(p.d)

Base.in(item, p::ImageProperties) = in(item, p.d)

Base.pop!(p::ImageProperties, key, default) = pop!(p.d, key, default)
Base.pop!(p::ImageProperties, key) = pop!(p.d, key, Base.secret_table_token)
Base.push!(p::ImageProperties, kv::Pair) = insert!(p, kv[1], kv[2])
Base.push!(p::ImageProperties, kv) = insert!(p.d, kv[1], kv[2])

Base.haskey(p::ImageProperties, k::String) = haskey(p.d, k)
Base.keys(p::ImageProperties) = keys(p.d)
Base.getkey(p::ImageProperties, key, default) = getkey(p.d, key, default)
Base.get!(f::Function, h::ImageProperties, key) = get!(f, p.d, key)

# iteration interface
Base.iterate(p::ImageProperties) = iterate(p.d)
Base.iterate(p::ImageProperties, state) = iterate(p.d, state)

Base.length(p::ImageProperties) = length(p.d)
Base.filter!(f, p::ImageProperties) = filter!(f, p.d)

const ImageFormat{F,T,N,D,Ax} = ImageMeta{T,N,AxisArray{T,N,D,Ax},ImageProperties{F}}
ImageFormat(A::AbstractArray, props::ImageProperties{F}, axes::Axis...) where F =
    ImageMeta(AxisArray(A, axes...), props)
ImageFormat(A::AbstractArray, props::ImageProperties{F}, names::Symbol...) where F =
    ImageMeta(AxisArray(A, names...), props)
ImageFormat(A::AbstractArray, props::ImageProperties{F}, names::NTuple{N,Symbol}, steps::NTuple{N,Number}, offsets::NTuple{N,Number}=map(zero, steps)) where {F,N} =
    ImageMeta(AxisArray(A, names, steps, offsets), props)

ImageFormat{F}(A::AbstractArray, props::AbstractDict{String,Any}, axes::Axis...) where F =
    ImageMeta(AxisArray(A, axes...), ImageFormat{F}(props))
ImageFormat{F}(A::AbstractArray, props::Dict, names::Symbol...) where F =
    ImageMeta(AxisArray(A, names...), ImageFormat{F}(props))
ImageFormat{F}(A::AbstractArray, props::Dict, names::NTuple{N,Symbol}, steps::NTuple{N,Number}, offsets::NTuple{N,Number}=map(zero, steps)) where {F,N} =
    ImageMeta(AxisArray(A, names, steps, offsets), props)

ImageFormat{F}(A::AbstractArray, axes::Axis...; kwargs...) where F =
    ImageMeta(AxisArray(A, axes...), ImageProperties{F}([kwargs...]))
ImageFormat{F}(A::AbstractArray, names::Symbol...; kwargs...) where F =
    ImageMeta(AxisArray(A, names...), ImageProperties{F}([kwargs...]))
ImageFormat{F}(A::AbstractArray, names::NTuple{N,Symbol}, steps::NTuple{N,Number}, offsets::NTuple{N,Number}=map(zero, steps); kwargs...) where {F,N} =
    ImageMeta(AxisArray(A, names, steps, offsets), ImageProperties{F}([kwargs...]))


struct ChunkedProperties{F<:DataFormat} <: AbstractDict{String,Any}
end
