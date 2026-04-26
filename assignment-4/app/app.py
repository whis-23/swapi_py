from flask import Flask, jsonify, request
from models import PlanetService, PersonService

app = Flask(__name__)
planet_service = PlanetService()
person_service = PersonService()


@app.route("/health")
def health():
    return jsonify({"status": "UP", "service": "swapi-app"}), 200


@app.route("/api/planets", methods=["GET"])
def get_planets():
    planets = planet_service.get_all()
    return jsonify(planets), 200


@app.route("/api/planets/<int:planet_id>", methods=["GET"])
def get_planet(planet_id):
    planet = planet_service.get_by_id(planet_id)
    if planet is None:
        return jsonify({"error": "Planet not found"}), 404
    return jsonify(planet), 200


@app.route("/api/planets", methods=["POST"])
def create_planet():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "name is required"}), 400
    planet = planet_service.create(data)
    return jsonify(planet), 201


@app.route("/api/people", methods=["GET"])
def get_people():
    people = person_service.get_all()
    return jsonify(people), 200


@app.route("/api/people/<int:person_id>", methods=["GET"])
def get_person(person_id):
    person = person_service.get_by_id(person_id)
    if person is None:
        return jsonify({"error": "Person not found"}), 404
    return jsonify(person), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
