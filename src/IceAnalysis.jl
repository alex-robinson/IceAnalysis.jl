module IceAnalysis

import JSON
import DataFrames 
import CSV 

using NCDatasets
using LaTeXStrings

using Plots
using Interpolations 

greet() = print("Hello World!")


struct ensemble
    path::AbstractString
    info::DataFrames.DataFrame
    sims::Array{Any}
end

function ensemble_def(path)
    
    # Define the info filename
    fname = string(path,"/","info.txt")

    # Read the ensemble info table into a DataFrame format, if it exists
    if isfile(fname)
        info  = CSV.read(fname,DataFrames.DataFrame,delim=' ',ignorerepeated=true)
    else 
        error(string("ensemble_def:: Error: file does not exist: ",fname))
    end

    # Define new array to hold paths to individual simulations
    nsim = DataFrames.nrow(info) 

    # Initialize an empty array of the right length
    #sims = Array{Union{Missing, String}}(missing, nsim) 
    sims = repeat([""],inner=nsim) 

    # Populate the array
    for i in 1:nsim
        sims[i] = string(path,"/",info[i,"rundir"])
    end

    # Store all information for output in the ensemble object
    ens = ensemble(path,info,sims)

    return ens
end 

function ensemble_get_var(varname::String,filename::String,ens::ensemble) #;ref::Int=1)

    println("\nLoad ",varname," from ",filename)
    println("  Ensemble path: ",ens.path)
    println("  Number of simulations: ",size(ens.sims,1))

    # Set ref sim number to 1 for now
    ref = 2

    # Get total number of sims 
    ns  = size(ens.info,1)

    # Get path of file of interest for reference sim
    path_now = ens.sims[ref] * "/" * filename

    # First load variable from reference sim
    ds = NCDataset(path_now,"r")

    #print(ds)

    if !haskey(ds,varname)
        error("ensemble_get_var:: Error: variable not found in file.")
    end

    # Get dimensions of variable of interest 
    v = ds[varname]

    dims  = dimnames(v);
    nd    = dimsize(v);

    # Add extra dimension for sims
    dims = (dims...,("sim",)...)
    nd   = (nd...,(ns,)...)

    time = ds["time"][:]*1e-3
    var  = [v[:] v[:]*1.1]
    
    # Define new ensemble arrays based on dimensions
    var_out = similar(v[:], nd...)

    # Close NetCDF file
    close(ds) 


### TO DO ###
    # To work, `nd` needs to be defined here...

    # Load current variable 
    #time, var = load_time_var(path_now,varname) 

    # Define new ensemble arrays based on dimensions
    #var_out = similar(var, nd...)
#############

    # Load variable from each simulation in ensemble 
    for k in 1:ns 

        # Get path of file of interest for reference sim
        path_now = ens.sims[k] * "/" * filename

        # Load current variable 
        time_now, var_now = load_time_var(path_now,varname) 

        # Append variable to var_out array
        itp = LinearInterpolation(time_now, var_now, extrapolation_bc = NaN)

        var_out[:,k] = itp(time)
        #var_out[:,k] .= var_now 

    end

    # Store variable in ens object 
    # to do... 

    return (time,var_out)
end 

function load_time_var(path,varname)
    
    if !isfile(path)
        return ([NaN,NaN],[NaN,NaN])
    end 

    # First load variable from reference sim
    ds = NCDataset(path,"r")

    #print(ds)

    if !haskey(ds,varname)
        error("load_var:: Error: variable not found in file.")
    end

    # Get dimensions of variable of interest 
    v = ds[varname];

    time = ds["time"][:]*1e-3
    var  = v[:]
        
    # Close NetCDF file
    close(ds) 

    return (time,var)
end


# function ensemble_plot(time,var,label)

#     # label=v.attrib["long_name"]

#     scalefontsizes()
#     scalefontsizes(1.4)
#     plot(time,var,label=,linecolor="black",linewidth=2,legend=false);
#     xlabel!(L"\textrm{\sffamily Time (kyr)}");
#     ylabel!(L"\textrm{\sffamily Temp. anomaly (}^{\circ}\textrm{\sffamily C)}");
#     plot!(widen=true);
#     plot!(framestyle = :box);
#     plot!(fontfamily="sffamily");
#     plot!(size=(600,400));
#     savefig("./test.pdf")  

# end

end # module
