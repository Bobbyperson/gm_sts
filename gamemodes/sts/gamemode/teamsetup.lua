local ply = FindMetaTable("Player")
include("cubes.lua")
teams = {}
teams[1] = {
    name = "Blue",
    color = Vector(0.2, 0.2, 1.0),
    cubes = {
        cube1 = Cube.new("blue_box1", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube2 = Cube.new("blue_box2", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube3 = Cube.new("blue_box3", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube4 = Cube.new("blue_box4", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab")
    },
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
    points = 0
}
team.SetColor(1, Color(51, 51, 255, 255))
teams[2] = {
    name = "Red",
    color = Vector(1.0, 0, 0),
    cubes = {
        cube1 = Cube.new("red_box1", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube2 = Cube.new("red_box2", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube3 = Cube.new("red_box3", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube4 = Cube.new("red_box4", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab")
    },
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
    points = 0
}

team.SetColor(2, Color(255, 0, 0, 255))
teams[3] = {
    name = "Green",
    color = Vector(0.0, 1.0, 0.0),
    cubes = {
        cube1 = Cube.new("green_box1", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube2 = Cube.new("green_box2", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube3 = Cube.new("green_box3", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube4 = Cube.new("green_box4", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab")
    },
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
    points = 0
}

team.SetColor(3, Color(0, 255, 0, 255))
teams[4] = {
    name = "Yellow",
    color = Vector(1.0, 1.0, 0.0),
    cubes = {
        cube1 = Cube.new("yellow_box1", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube2 = Cube.new("yellow_box2", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube3 = Cube.new("yellow_box3", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab"),
        cube4 = Cube.new("yellow_box4", 1, 1, 1, 1, mobs[1]["headcrab"], "headcrab")
    },
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
    points = 0
}

team.SetColor(4, Color(255, 255, 0, 255))
teams[0] = {
    name = "Empty",
    color = Vector(1.0, 1.0, 1.0),
    cubes = {},
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
}

teams[5] = {
    name = "Spectator",
    color = Vector(0.0, 0.0, 0.0),
    cubes = {},
    spawners = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {}
    },
}

-- deprecated?
function ply:SetupTeam(n)
    if not teams[n] then return end
    self:SetTeam(n)
    self:SetPlayerColor(teams[n].color)
    self:SetModel("models/player/police.mdl")
end
