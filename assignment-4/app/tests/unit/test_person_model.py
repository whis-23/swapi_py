import pytest
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from models import Person, PersonService


class TestPersonModel:
    def test_person_to_dict_contains_all_fields(self):
        person = Person(1, "Luke Skywalker", "19BBY", "male", 1)
        result = person.to_dict()
        assert result["id"] == 1
        assert result["name"] == "Luke Skywalker"
        assert result["birth_year"] == "19BBY"
        assert result["gender"] == "male"
        assert result["homeworld_id"] == 1

    def test_person_equality_by_id(self):
        p1 = Person(1, "Luke Skywalker", "19BBY", "male", 1)
        p2 = Person(1, "Different", "20BBY", "female", 2)
        assert p1 == p2

    def test_person_inequality_different_id(self):
        p1 = Person(1, "Luke Skywalker", "19BBY", "male", 1)
        p2 = Person(2, "Leia Organa", "19BBY", "female", 2)
        assert p1 != p2

    def test_person_not_equal_to_non_person(self):
        person = Person(1, "Luke Skywalker", "19BBY", "male", 1)
        assert person != "Luke Skywalker"
        assert person != None

    def test_person_repr(self):
        person = Person(1, "Luke Skywalker", "19BBY", "male", 1)
        assert "Luke Skywalker" in repr(person)


class TestPersonService:
    def setup_method(self):
        self.service = PersonService()

    def test_get_all_returns_list(self):
        result = self.service.get_all()
        assert isinstance(result, list)
        assert len(result) == 3

    def test_get_by_id_returns_correct_person(self):
        result = self.service.get_by_id(1)
        assert result is not None
        assert result["name"] == "Luke Skywalker"

    def test_get_by_id_returns_none_for_missing(self):
        result = self.service.get_by_id(9999)
        assert result is None

    def test_count_returns_correct_number(self):
        assert self.service.count() == 3

    def test_person_with_no_homeworld(self):
        result = self.service.get_by_id(3)
        assert result["homeworld_id"] is None
