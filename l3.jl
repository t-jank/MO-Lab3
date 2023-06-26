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
    return "unsuccessful"
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

function fix_schedule(n,m,p,sch)
    number_of_machines_on_job=[]
    number_of_jobs_on_machine=[]
    for i in 1:n
        push!(number_of_machines_on_job,0)
    end
    for i in 1:m
        push!(number_of_jobs_on_machine,0)
    end
    for a in 1:n
        for b in 1:m
            if sch[a,b]!=0
                number_of_jobs_on_machine[b]+=1
                number_of_machines_on_job[a]+=1
            end
        end
    end
    for a in 1:n
        if number_of_machines_on_job!=1
            fixed=false
            for b in 1:m
                if sch[a,b]!=0
                    if number_of_jobs_on_machine[b]==1
                        sch[a,b]=1
                        fixed=true
                    end
                end
            end
            if fixed==false
                sch[a,argmax(sch[a,:])]=1
            end
        end
    end
    
    for a in 1:n
        for b in 1:m
            if sch[a,b]!=1
                sch[a,b]=0
            end
        end
    end
    return sch
end

function time_schedule(n,m,p,schedule)
    time_machines = []
    for i in 1:m
        push!(time_machines,0)
    end
    for i in 1:n
        jm=argmax(schedule[i,:])
        time_machines[jm]+=p[i,jm]
    end
    return maximum(time_machines)
end

# Dane
#n = 5 # liczba zadań
#m = 3 # liczba maszyn
#p = [ 3 2 2; 2 1 4; 1 4 4; 3 2 3; 2 3 2] # macierz czasów wykonania zadań
m=10
n=100
p=[ 60 53 45 33 11 7 4 95 61 100; 58 80 66 8 24 42 42 21 7 89; 80 58 76 14 77 66 25 17 89 74; 89 83 98 73 33 69 42 81 59 56; 62 16 12 14 33 59 35 55 13 80; 65 21 31 55 72 98 98 25 64 79; 50 16 28 71 84 43 94 70 85 22; 74 76 33 76 49 50 85 89 39 58; 76 75 54 80 19 64 42 34 44 1; 79 66 14 91 66 79 56 55 5 68; 63 38 65 13 66 30 17 84 5 35; 60 5 46 61 87 63 85 71 7 38; 1 23 3 17 44 44 23 84 68 13; 53 4 9 72 67 12 81 87 34 88; 22 56 62 86 83 100 84 88 32 9; 53 49 31 89 16 68 33 31 15 42; 94 42 2 29 75 56 2 41 78 24; 78 15 60 25 45 98 63 27 16 9; 89 57 81 24 53 92 44 27 85 35; 86 13 62 96 1 31 73 19 37 35; 46 31 41 20 87 57 77 44 98 98; 11 58 100 37 75 75 7 25 6 35; 51 16 44 97 74 24 54 82 46 13; 51 48 92 74 26 28 74 57 57 14; 56 4 33 37 16 17 31 38 54 58; 51 11 20 3 4 57 75 74 36 95; 30 13 94 34 99 23 33 13 29 40; 47 50 90 83 7 88 38 22 85 36; 48 17 9 91 8 12 56 50 66 35; 27 81 75 84 28 6 5 47 27 17; 42 75 69 89 70 38 37 42 30 51; 45 19 11 80 68 20 78 2 30 24; 34 49 35 40 67 61 82 12 94 99; 79 92 19 54 12 95 62 37 14 12; 47 37 98 13 25 61 14 69 99 82; 47 91 7 66 30 17 19 45 32 99; 20 90 29 16 61 80 73 56 57 52; 26 56 51 80 6 75 68 34 74 90; 55 31 15 62 61 8 85 83 2 27; 46 40 92 75 34 55 23 93 2 87; 67 51 89 52 11 63 15 21 75 29; 33 39 49 30 90 66 100 57 62 38; 93 8 48 96 43 64 93 24 22 94; 16 37 9 46 92 20 58 2 75 6; 94 72 77 57 26 98 16 63 8 15; 64 38 76 71 14 44 96 91 35 63; 14 23 39 6 41 45 15 14 74 70; 64 79 18 41 14 7 57 96 5 49; 90 44 32 92 38 81 16 87 91 78; 55 49 14 31 62 10 21 36 49 28; 83 47 15 40 45 79 50 5 72 47; 57 24 65 18 49 75 92 81 53 35; 88 36 18 29 71 2 39 64 36 55; 58 37 23 64 64 61 93 66 64 92; 88 4 68 7 84 3 99 75 34 92; 3 70 31 77 71 51 1 30 45 69; 17 26 23 82 76 62 87 82 73 97; 81 27 52 91 13 67 9 14 27 9; 19 85 76 66 97 4 22 84 71 28; 35 89 83 21 47 89 26 40 60 42; 13 18 87 54 54 91 58 72 56 86; 56 96 88 21 10 11 56 63 68 66; 82 59 95 68 39 65 74 60 26 31; 63 66 13 68 54 81 67 20 45 38; 47 65 63 32 52 100 63 39 62 21; 40 35 10 88 99 10 94 40 73 10; 96 50 4 18 73 39 89 17 26 31; 92 92 95 94 95 1 33 45 56 76; 50 10 11 27 14 18 77 10 73 51; 7 36 16 42 90 98 22 79 16 33; 53 4 5 96 85 96 1 40 5 29; 49 91 72 54 8 12 59 78 55 9; 62 34 37 77 61 34 11 37 18 64; 24 93 33 86 49 40 84 29 67 8; 92 47 66 92 40 97 83 4 37 15; 86 15 87 14 70 33 48 35 29 17; 87 26 80 38 5 89 100 25 96 96; 4 29 36 79 75 23 6 23 57 6; 75 31 2 92 27 29 11 12 89 12; 22 88 88 33 84 94 15 59 74 26; 69 93 30 63 94 42 40 59 35 64; 61 15 70 6 23 84 35 40 39 15; 79 90 92 62 85 37 73 100 68 53; 23 17 67 80 73 99 69 40 44 57; 90 84 95 29 78 53 72 62 49 52; 30 93 39 41 76 9 63 74 78 37; 31 69 30 76 14 17 21 4 15 52; 89 1 50 11 40 22 66 31 99 79; 90 31 33 62 36 96 58 23 72 16; 12 43 77 95 41 100 39 64 71 23; 93 71 46 51 25 61 36 38 83 89; 79 63 63 31 71 70 20 35 54 98; 70 99 30 21 46 74 79 37 1 41; 86 74 23 12 2 39 75 74 26 27; 81 87 91 37 55 10 92 42 60 67; 88 68 71 87 73 87 73 63 51 94; 28 60 59 83 4 52 46 16 66 66; 42 59 7 80 85 79 10 14 13 5; 99 88 32 49 65 60 100 9 63 74; 3 68 4 9 81 25 37 66 7 63]


t=find_T(n,m,p)
schedule = schedule_jobs(n, m, p, t)
fixed_sch=fix_schedule(n,m,p,schedule)
time_sch=time_schedule(n,m,p,fixed_sch)
println("Funkcja celu: ",time_sch)#
