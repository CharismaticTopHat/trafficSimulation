using Agents, Random
using StaticArrays: SVector

# Estados de los Semáforos
@enum LightColor green yellow red

@agent struct Car(ContinuousAgent{2,Float64})
    accelerating::Bool = true
    posCar::SVector = [0,0]
end


@agent struct stopLight(ContinuousAgent{2,Float64})
    status::LightColor = red
    time_counter::Int = 0
    posStopLight::SVector = [0,0]
end

green_duration = 10
yellow_duration = 4


accelerate(agent::Car) = agent.vel[1] + 0.05
decelerate(agent::Car) = agent.vel[1] - 0.1

function car_ahead(agent::Car, model)
    for neighbor in nearby_agents(agent, model, 1.0)
        if neighbor.pos[1] > agent.pos[1]
            return neighbor
        end
    end
end

function is_red_light_ahead(agent::Car, model)
    for neighbor in nearby_agents(agent, model, 1.0)
        if isa(neighbor, stopLight) && neighbor.status == red && neighbor.pos[1] > agent.pos[1]
            return true
        end
    end
    return false
end

function  agent_step!(agent::Car, model)
    new_velocity = agent.accelerating ? accelerate(agent) : decelerate(agent)
    
    if new_velocity >= 1.0
        new_velocity = 1.0
        agent.accelerating = false
    elseif new_velocity <= 0.0
        new_velocity = 0.0
        agent.accelerating = true
    end
    
    agent.vel = (new_velocity, 0.0)
    move_agent!(agent, model, 0.4)
end


function agent_step!(agent::stopLight, model)
    cycle_length = 2 * (green_duration + yellow_duration)  # Ciclo completo de 28 pasos

    # Incrementamos el contador de tiempo del agente
    agent.time_counter += 1

    # Si el contador alcanza el final del ciclo, lo reiniciamos
    if agent.time_counter > cycle_length
        agent.time_counter = 1
    end

    # Cambiamos el estado del semáforo en función del contador
    if agent.time_counter <= green_duration
        agent.status = green
    elseif agent.time_counter <= green_duration + yellow_duration
        agent.status = yellow
    else
        agent.status = red
    end
end

function initialize_model(extent = (25, 10))
    space2d = ContinuousSpace(extent; spacing = 0.5, periodic = true)
    
    rng = Random.MersenneTwister()
    
    model = StandardABM(Union{Car, stopLight}, space2d; rng, agent_step!, scheduler = Schedulers.fastest)
    #model = StandardABM(stopLight, space2d; agent_step!, scheduler = Schedulers.Randomly())
    #model = StandardABM(Car, space2d; rng, agent_step!, scheduler = Schedulers.Randomly())
    add_agent!(stopLight, model; posStopLight = (12, 6.5), vel = (0.0,0.0))
    add_agent!(stopLight, model; posStopLight = (13, 8), vel = (0.0,0.0)) 
    changing = true
    for agent in allagents(model)
        if changing === true
            agent.status = green
            changing = false
        else
            agent.status = red
            agent.time_counter = green_duration + yellow_duration
            changing = true
        end
    end
    first = true
    for px in randperm(25)[1:9]
        if first
            add_agent!(Car, model;posCar = (px, 10), vel=SVector{2, Float64}(1.0, 0.0))
        else
            add_agent!(Car, model; posCar = (px, 10),  vel=SVector{2, Float64}(rand(Uniform(0.2, 0.7)), 0.0))
        end
        first = false
    end
    model
end

#Semáforo = 10 pasos en Verde, 4 pasos en Amarillo, 14 pasos en Rojo