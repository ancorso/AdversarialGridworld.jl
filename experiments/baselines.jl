include("../src/task_generator.jl")
include("../../DecomposedMDPSolver/src/q_learning_solver.jl")
include("../../DecomposedMDPSolver/src/pg_solver.jl")
using Plots

## Generate training and test sets
N_train = 30
N_test = 5
train_seed = 0
test_seed = 1

# Generate training tasks
# train_tasks = generate_task_set(train_seed, N_train, folder = "train_tasks", save = true)
# If the tasks have already been generated then load them
train_tasks = load_items("train_tasks")

# Solve for training policies
# train_policies = solve_for_policies(train_tasks, folder = "train_policies", save = true)
# If tasks have already been solved, load the policies
train_policies = load_items("train_policies")

# Generate a test set of tasks
# test_tasks = generate_task_set(test_seed, N_test, folder = "test_tasks", save = true)
# If the test tasks have already been generated then load them
test_tasks = load_items("test_tasks")

# Solve for test optimal policies
# test_policies = solve_for_policies(test_tasks, folder = "test_policies", save = true)
# If test tasks have already been soved, load the policies
test_policies = load_items("test_policies")


# ## Evaluate different baselines
# N_trials = 100
#
# # Evaluate a random policy
# random_policies = [RandomPolicy(t) for t in test_tasks]
# random_pol_r = evaluate_policies(test_tasks, random_policies, N_trials)
# println("random policy reward: ", random_pol_r)
#
# # Evaluate the optimal adversary policy
# optimal_pol_r = evaluate_policies(test_tasks, test_policies, N_trials)
# println("optimal policy reward: ", optimal_pol_r)
#
# # Evaluate a policy optimized on one of the training tasks
# train_optimal = rand(train_policies)
# train_optimal_r = evaluate_policies(test_tasks, [train_optimal for t in test_tasks], N_trials)
# println("train policy reward: ", train_optimal_r)

N_trans = 500
N_iter = 50
N_eps = 100 # for validation
lr = 1e-4
Qmax = 1
MC = Inf
i = 1


## Mearsure the performance of the difference algorithms using a previously seen training task
t = train_tasks[i]
tr_ps = train_policies

lb_train = average_performance(t, RandomPolicy(t), N_eps)
ub_train = average_performance(t, train_policies[i], N_eps)

# Policy gradient
tr_exp_pg, tr_perf_pg, tr_pol_pg = solve_test_task_PG(t, tr_ps, N_trans, N_iter, lr, N_eps)

# Q learning with 1 step bootstrap
tr_exp_Q, tr_perf_Q, tr_pol_Q = solve_test_task_Q(t, tr_ps, N_trans, N_iter, Qmax, N_eps)

# MC learning
tr_exp_MC, tr_perf_MC, tr_pol_MC  = solve_test_task_Q(t, tr_ps, N_trans, N_iter, MC, N_eps)


## Measure the performance of the algorithms on a new task
t = test_tasks[i]

lb_test = average_performance(t, RandomPolicy(t), N_eps)
ub_test = average_performance(t, test_policies[i], N_eps)

# Policy gradient
te_exp_pg, te_perf_pg, te_pol_pg = solve_test_task_PG(t, tr_ps, N_trans, N_iter, lr, N_eps)

# Q learning with 1 step bootstrap
te_exp_Q, te_perf_Q, te_pol_Q = solve_test_task_Q(t, tr_ps, N_trans, N_iter, Qmax, N_eps)

# MC learning
te_exp_MC, te_perf_MC, te_pol_MC  = solve_test_task_Q(t, tr_ps, N_trans, N_iter, MC, N_eps)
te_exp_pg, [lb_test for i=1:te_exp_pg[end]]

plot(title = "Seen Task Performance", legend=:bottomright)
plot!(tr_exp_pg, [lb_train for i=1:length(te_exp_pg)], label = "Random Policy")
plot!(tr_exp_pg, [ub_train for i=1:length(te_exp_pg)], label = "Optimal Policy")
plot!(tr_exp_pg, tr_perf_pg, label = "Policy Gradient")
plot!(tr_exp_Q, tr_perf_Q, label = "Q Learning (1 step return)")
plot!(tr_exp_MC, tr_perf_MC, label = "Monte Carlo")

savefig("train_task_perf.pdf")

plot(title = "Coefficient of correct train task", legend = :bottomright)
plot!(tr_exp_pg, [p.μ[1] for p in tr_pol_pg], label="Policy Gradient")
plot!(tr_exp_Q, [p.w.θ[1] for p in tr_pol_Q], label="Q Learning")
plot!(tr_exp_Q, [p.w.θ[1] for p in tr_pol_MC], label="MC Learning")

savefig("train_parameters.pdf")

plot(title = "Unseen Task Performance", legend=:bottomright)
plot!(te_exp_pg, [lb_test for i=1:length(te_exp_pg)], label = "Random Policy")
plot!(te_exp_pg, [ub_test for i=1:length(te_exp_pg)], label = "Optimal Policy")
plot!(te_exp_pg, te_perf_pg, label = "Policy Gradient")
plot!(te_exp_Q, te_perf_Q, label = "Q Learning (1 step return)")
plot!(te_exp_MC, te_perf_MC, label = "Monte Carlo")

savefig("test_task_perf.pdf")

