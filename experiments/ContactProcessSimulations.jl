using PrettyTables
using Revise
using Plots
include("../src/ContactProcess.jl")
using .ContactProcess
using Random
# set the seed for reproducibility

Random.seed!(1234)

# set b, d with the same values as in the paper
grid_params = ContactProcess.GridParameters(width = 20, height = 20) 
model_params = ContactProcess.ModelParameters(infection_rate = 0.05, recovery_rate = 0.1, time_limit = 1, prob_infections = 0.01, num_simulations = 20_000) # rates are defined to be per day 


state, rates = ContactProcess.initialize_state_and_rates(grid_params, model_params)
pretty_table(state)

# Run the simulation
state_sequence, times, updated_nodes = ContactProcess.run_simulation!(state, rates, grid_params, model_params)
      
# Generate the animation
anim = ContactProcess.generate_animation(state_sequence, times)

# Save the animation
gif(anim, "contact_process.gif", fps = 1)

all_state_sequences, all_times = ContactProcess.multiple_simulations(grid_params, model_params)


# plot all the simulations one by one using gifs

@doc"""
    computing the likelihood of the data given the following model settings: 
    1.) infection_rate, recovery_rate = 0.0499, 0.1001
    2.) infection_rate, recovery_rate = 0.0501, 0.1001
    3.) infection_rate, recovery_rate = 0.0499, 0.0999
    4.) infection_rate, recovery_rate = 0.0501, 0.0999

    The function returns the likelihood of the data given the model settings
"""
model_params_1 = ContactProcess.ModelParameters(infection_rate = 0.0499, recovery_rate = 0.1001, time_limit = 1, prob_infections = 0.01, num_simulations = 20_000) # rates are defined to be per day
model_params_2 = ContactProcess.ModelParameters(infection_rate = 0.0501, recovery_rate = 0.1001, time_limit = 1, prob_infections = 0.01, num_simulations = 20_000) # rates are defined to be per day
model_params_3 = ContactProcess.ModelParameters(infection_rate = 0.0499, recovery_rate = 0.0999, time_limit = 1, prob_infections = 0.01, num_simulations = 20_000) # rates are defined to be per day
model_params_4 = ContactProcess.ModelParameters(infection_rate = 0.0501, recovery_rate = 0.0999, time_limit = 1, prob_infections = 0.01, num_simulations = 20_000) # rates are defined to be per day

# write a function to compute the sum of the edges of a matrix 
function sum_edges(matrix)
    return sum(matrix[2, :]) + sum(matrix[end - 1, :]) + sum(matrix[:, 2]) + sum(matrix[:, end - 1])
end

function likelihood(model_params, state_sequence, times, updated_nodes)
    loglikelihoods = [0.0] # likelihood computed at jump times
    bar_X = sum(state_sequence[1]) 
    hat_X = sum_edges(state_sequence[1])
    time = times[1]
    for i ∈ 2:length(state_sequence)
        updated_node = updated_nodes[i]
        if i == length(state_sequence)
            new_time = model_params.time_limit
        else
            new_time = times[i]
        end
        last_loglikelihood = loglikelihoods[end]
        println(loglikelihoods, (0.3 - model_params.recovery_rate - 4 * model_params.recovery_rate) * bar_X * (new_time - time) - (0.05 - model_params.recovery_rate) * hat_X * (new_time - time))
        loglikelihoods = push!(loglikelihoods, last_loglikelihood + (0.3 - model_params.recovery_rate - 4*model_params.recovery_rate) * bar_X * (new_time - time) - (0.05 - model_params.recovery_rate) * hat_X * (new_time - time))
        # if the state is updated to 1 then add to the loglikelihood log(model_params["infection_rate"]/0.05) else add log(model_params["infection_rate"]/0.01)
        println(state_sequence)
        if state_sequence[i][updated_node[1], updated_node[2]] == 1
            loglikelihoods[end] += log(model_params.infection_rate/0.05)
        else
            loglikelihoods[end] += log(model_params.infection_rate/0.01)
        end
    end
    return loglikelihoods
end

likelihood_1 = likelihood(model_params_1, state_sequence, times, updated_nodes)
# what is the shape of state_sequence
