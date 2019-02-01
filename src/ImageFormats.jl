module ImageFormats

using FileIO, StaticArrays, AxisArrays, ImageMetadata, ImageAxes, MappedArrays,
      ColorTypes
using Unitful: unit
#using ImageMetadata: @get, data
using GeometryTypes: Point
using Rotations: Quat
using Distributions: TDist,Chi,Chisq,Poisson,FDist,Beta,Binomial,Gamma,Normal,
                     NoncentralT,NoncentralChisq,Logistic,Uniform,NoncentralF,
                     GeneralizedExtremeValue,Distribution

export fileformat, ImageFormat, ImageProperties, ImageReader,
       description, auxfile, timeunits, spatunits, TypeStream

const RawType = Union{Float16, Float32, Float64, Int128, Int16, Int32,
                      Int64, UInt128, UInt16, UInt32, UInt64}
const SinkType = Union{Float16, Float32, Float64, Int128, Int16, Int32,
                       Int64, UInt128, UInt16, UInt32, UInt64}
const ArrayContainer = Union{AxisArray, ImageMeta, SizedArray}


include("typestream.jl")
include("imageproperties.jl")
include("imagereader.jl")
include("traits.jl")


end
