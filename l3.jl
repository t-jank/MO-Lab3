using JuMP
using Cbc

function find_T(n,m,p)
    l=0
    r=length(p)-1
    while l<=r
        s=trunc(Int,(l+r)/2)
        if schedule_jobs(n, m, p, s)!=false && schedule_jobs(n, m, p, s-1)==false
            return s
        end
        if schedule_jobs(n, m, p, s)!=false
            r=s-1
        elseif schedule_jobs(n, m, p, s)==false
            l=s+1
        end
    end
    return unsuccessful
end

function greedy(n,m,p)
    schedule=[]
    for i in 1:n
        task=[]
        min_idx=argmin(p[i,:])
        for j in 1:min_idx-1
            push!(task,0)
        end
        push!(task,1)
        for j in min_idx+1:m
            push!(task,0)
        end
        push!(schedule,task)
    end
    time_machines = []
    for i in 1:m
        push!(time_machines,0)
    end
    for i in 1:n
        jm=argmax(schedule[i]) # jm=argmax(schedule[i,:])
        time_machines[jm]+=p[i,jm]
    end
    return maximum(time_machines)
end


function schedule_jobs(n, m, p, T)
    # n - liczba zadań
    # m - liczba maszyn
    # p - macierz czasów wykonania zadań

    model = Model(Cbc.Optimizer)

    @variable(model, x[1:n, 1:m]>=0)# Zmienne decyzyjne x[i,j] = 1, jeśli zadanie i jest przypisane do maszyny j, w przeciwnym razie 0

    # zerowanie >T
    for i in 1:n
        for j in 1:m	
            if p[i,j]>T
                @constraint(model,x[i,j]==0)
            end
        end
    end

    # Każde zadanie jest przypisane do dokładnie jednej maszyny
    @constraint(model, task_assignment[i = 1:n], sum(x[i, j] for j = 1:m) == 1)

    # Każda maszyna wykonuje co najwyżej jedno zadanie w tym samym czasie
    @constraint(model, machine_capacity[j = 1:m], sum(x[i, j] * p[i, j] for i = 1:n) <= T)

    # Minimalizacja makespanu
    #@objective(model, Min, C)

    # Rozwiązanie modelu
    optimize!(model)
    if has_values(model)==false
        return false
    end
    # Pobranie wyników
  #  makespan = objective_value(model)
    schedule = value.(x)
    return schedule
end

# Przykładowe dane
n = 5 # liczba zadań
m = 3 # liczba maszyn
p = [3 2 2; 2 1 4; 1 4 4; 3 2 3; 2 3 2] # macierz czasów wykonania zadań


#schedule = schedule_jobs(n, m, p, 2)
#println("Schedule: ", schedule)
println("T: ",find_T(n,m,p))

