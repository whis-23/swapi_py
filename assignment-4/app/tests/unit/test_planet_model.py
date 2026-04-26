import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from models import Planet, PlanetService


class TestPlanetModel:
    def test_planet_to_dict_contains_all_fields(self):
        planet = Planet(1, "Tatooine", "arid", "desert", 200000)
        result = planet.to_dict()
        assert result["id"] == 1
        assert result["name"] == "Tatooine"
        assert result["climate"] == "arid"
        assert result["terrain"] == "desert"
        assert result["population"] == 200000

    def test_planet_equality_by_id(self):
        p1 = Planet(1, "Tatooine", "arid", "desert", 200000)
        p2 = Planet(1, "Different Name", "cold", "ice", 0)
        assert p1 == p2

    def test_planet_inequality_different_id(self):
        p1 = Planet(1, "Tatooine", "arid", "desert", 200000)
        p2 = Planet(2, "Alderaan", "temperate", "grasslands", 2000000000)
        assert p1 != p2

    def test_planet_not_equal_to_non_planet(self):
        planet = Planet(1, "Tatooine", "arid", "desert", 200000)
        assert planet != "Tatooine"
        assert planet != 1
        assert planet != None

    def test_planet_repr(self):
        planet = Planet(1, "Tatooine", "arid", "desert", 200000)
        assert "Tatooine" in repr(planet)
        assert "1" in repr(planet)


class TestPlanetService:
    def setup_method(self):
        self.service = PlanetService()

    def test_get_all_returns_list(self):
        result = self.service.get_all()
        assert isinstance(result, list)
        assert len(result) == 3

    def test_get_by_id_returns_correct_planet(self):
        result = self.service.get_by_id(1)
        assert result is not None
        assert result["name"] == "Tatooine"

    def test_get_by_id_returns_none_for_missing(self):
        result = self.service.get_by_id(9999)
        assert result is None

    def test_create_increments_count(self):
        initial = self.service.count()
        self.service.create({"name": "Coruscant", "climate": "temperate"})
        assert self.service.count() == initial + 1

    def test_create_assigns_unique_id(self):
        p1 = self.service.create({"name": "Coruscant"})
        p2 = self.service.create({"name": "Naboo"})
        assert p1["id"] != p2["id"]

    def test_create_uses_defaults_for_missing_fields(self):
        result = self.service.create({"name": "Unknown"})
        assert result["climate"] == "unknown"
        assert result["terrain"] == "unknown"
        assert result["population"] == 0

    def test_delete_removes_planet(self):
        initial = self.service.count()
        removed = self.service.delete(1)
        assert removed is True
        assert self.service.count() == initial - 1

    def test_delete_returns_false_for_missing(self):
        assert self.service.delete(9999) is False
