cd("/share/tmschaef/jkott/modelB")
using DelimitedFiles
using Random
using Glob

const L = parse(Int, ARGS[1])

function autocor_loc_2(x, beg, max, n=2)
	C = zeros(ComplexF64,max+1)
	N = zeros(Int64,max+1)
	for tau in 0:max
		for i in beg:length(x)-max
			j = i + tau
			@inbounds @fastmath  C[tau+1] = C[tau+1] +  (x[i]*conj(x[j]))^n
			@inbounds @fastmath  N[tau+1] = N[tau+1] + 1
		end
	end
	(collect(1:max+1).-1,  real(C) ./ N)
end

function corr(dataset, L)
    (tau, corr) = autocor_loc_2(dataset[:,4].+1.0im.*dataset[:,5], 1, L^4÷40,1)
    corr
end

function variance(x)
    S=zeros(length(x[1]))
    mean = average(x)
    for i in 1:length(x)
      S .= S .+ (x[i] .- mean) .^2
    end
    S./length(x)
end

function average(x)
    sum(x)/length(x)
end

function bootstrap(fs, M)
    len = length(fs)
    #bs_tot = []
    bs_tot = fill(zeros(div(L^4, 40)+1), M)
    @Threads.threads for i in 1:M
        bsD = []
        for j in 1:len
            samp = fs[rand(1:len)]
            push!(bsD, samp)
        end
        #push!(bs_tot, average(bsD))
	bs_tot[i] = average(bsD)
    end
    mean = average(bs_tot)
    var = variance(bs_tot)
    (mean, sqrt.(var))
end

function collect_data()
    dfs = glob("dynamics_L_$(L)_id_*")
    datasets = fill(zeros(div(L^4, 40)+1), length(dfs))
    @Threads.threads for i in 1:length(dfs)
        df = readdlm(dfs[i],' ')
        C = corr(df, L)
        #push!(datasets, C)
	datasets[i] = C
    end

    (C, Cerr) = bootstrap(datasets, 50000)
    step = 10
    Δt = 0.04
    t = [0:length(C)-1;] .* (step*Δt)
    (t, C, Cerr)
end

(t, C, err) = collect_data()

output_file = open("data_$L.jl","w")

write(output_file, "t_$L = ")
show(output_file, t)
write(output_file, "\n\n")

write(output_file, "C_$L = ")
show(output_file, C)
write(output_file, "\n\n")

write(output_file, "Cerr_$L = ")
show(output_file, err)

close(output_file)
