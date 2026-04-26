class Planet:
    def __init__(self, id, name, climate, terrain, population):
        self.id = id
        self.name = name
        self.climate = climate
        self.terrain = terrain
        self.population = population

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "climate": self.climate,
            "terrain": self.terrain,
            "population": self.population,
        }

    def __eq__(self, other):
        if not isinstance(other, Planet):
            return False
        return self.id == other.id

    def __repr__(self):
        return f"Planet(id={self.id}, name={self.name!r})"


class Person:
    def __init__(self, id, name, birth_year, gender, homeworld_id=None):
        self.id = id
        self.name = name
        self.birth_year = birth_year
        self.gender = gender
        self.homeworld_id = homeworld_id

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "birth_year": self.birth_year,
            "gender": self.gender,
            "homeworld_id": self.homeworld_id,
        }

    def __eq__(self, other):
        if not isinstance(other, Person):
            return False
        return self.id == other.id

    def __repr__(self):
        return f"Person(id={self.id}, name={self.name!r})"


class PlanetService:
    def __init__(self):
        self._store = {
            1: Planet(1, "Tatooine", "arid", "desert", 200000),
            2: Planet(2, "Alderaan", "temperate", "grasslands, mountains", 2000000000),
            3: Planet(3, "Yavin IV", "temperate, tropical", "jungle, rainforests", 1000),
        }
        self._next_id = 4

    def get_all(self):
        return [p.to_dict() for p in self._store.values()]

    def get_by_id(self, planet_id):
        planet = self._store.get(planet_id)
        return planet.to_dict() if planet else None

    def create(self, data):
        planet = Planet(
            id=self._next_id,
            name=data["name"],
            climate=data.get("climate", "unknown"),
            terrain=data.get("terrain", "unknown"),
            population=data.get("population", 0),
        )
        self._store[self._next_id] = planet
        self._next_id += 1
        return planet.to_dict()

    def delete(self, planet_id):
        return self._store.pop(planet_id, None) is not None

    def count(self):
        return len(self._store)


class PersonService:
    def __init__(self):
        self._store = {
            1: Person(1, "Luke Skywalker", "19BBY", "male", 1),
            2: Person(2, "Leia Organa", "19BBY", "female", 2),
            3: Person(3, "Han Solo", "29BBY", "male", None),
        }
        self._next_id = 4

    def get_all(self):
        return [p.to_dict() for p in self._store.values()]

    def get_by_id(self, person_id):
        person = self._store.get(person_id)
        return person.to_dict() if person else None

    def count(self):
        return len(self._store)
