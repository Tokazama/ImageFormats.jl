# All ImageFormats should have these properties
"""
    header(img)
"""
header(img::ImageFormat) = img.properties["header"]
header(A::AbstractArray) = nothing

"""
description(img)

Retrieves description field that may say whatever you like.
"""
description(img::ImageMeta) = img.properties["description"]
description(A::AbstractArray) = ""

"""
auxfile(img)

Retrieves string for auxiliary file associated with the image.
"""
auxfile(img::ImageMeta) = img.properties["auxfile"]
auxfile(A::AbstractArray) = ""

"""
    spataxes(img)

Returns the axis associated with each spatial dimension.
"""
spataxes(A::AbstractArray) = map(i->AxisArrays.axes(a, i), coords_spatial(A))

"""
    spatunits(img)

Returns the units (i.e. Unitful.unit) that each spatial axis is measured in. If
not available `nothing` is returned for each spatial axis.
"""
spatunits(A::AbstractArray) = map(i->unit(i.val[1]), spataxes(img))

"""
    timeunits(img)

Returns the units (i.e. Unitful.unit) the time axis is measured in. If not
available `nothing` is returned.
"""
function timeunits(A::AbstractArray)
    ta = timeaxis(A)
    if ta == nothing
        return nothing
    else
        return unit(ta[1])
    end
end

"""
    filenames(img)
"""
filenames(img::ImageFormat) = img.properties["filenames"]
filenames(A::AbstractArray) = ""
