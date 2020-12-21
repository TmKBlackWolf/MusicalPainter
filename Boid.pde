class Boid extends Particle
{
  float alignValue = 0.5;
  float cohesionValue = 0.25;
  float seperationValue = 0.5;


  float alignmentPerceptionRadius = 25;
  float cohesionPerceptionRadius = 50;
  float separationPerceptionRadius = 25;

  float searchRadius = 50;
  Boid()
  {
    super();
  }


  Boid(int colour)
  {
    super(colour);
  }

  Boid(int x, int y)
  {
    super(x, y);
  }


  Boid(int x, int y, int colour)
  {
    super(x, y, colour);
  }

  void flock(Boid[] swarm)
  {
    PVector alignmentForce = this.getAlignmentForce(swarm);
    PVector cohesionForce = this.getCohesionForce(swarm);
    PVector separationForce = this.getSeparationForce(swarm);

    alignmentForce.mult(this.alignValue);
    cohesionForce.mult(this.cohesionValue);
    separationForce.mult(this.seperationValue);

    this.applyForce(alignmentForce);
    this.applyForce(cohesionForce);
    this.applyForce(separationForce);
  }

  PVector getAlignmentForce(Boid[] swarm) {

    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other : swarm) {
      
      float d = dist(this.pos.x, this.pos.y, other.pos.x, other.pos.y);
      if (other != this && d < this.alignmentPerceptionRadius) {
        steeringForce.add(other.vel);
        total++;
      }
    }
    if (total > 0) {
      steeringForce.div(total);      
      steeringForce.sub(this.vel);
    }
    return steeringForce;
  }



  PVector getCohesionForce(Boid[] swarm) {

    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other : swarm) {
      float d = dist(this.pos.x, this.pos.y, other.pos.x, other.pos.y);
      if (other != this && d < this.cohesionPerceptionRadius) {
        steeringForce.add(other.pos);
        total++;
      }
    }
    if (total > 0) {
      steeringForce.div(total);
      steeringForce.sub(this.pos);
    }
    return steeringForce;
  }



  PVector getSeparationForce(Boid[] swarm) {

    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other : swarm) {
      float d = dist(this.pos.x, this.pos.y, other.pos.x, other.pos.y);
      if (other != this && d < this.separationPerceptionRadius) {
        PVector diff = PVector.sub(this.pos, other.pos);
        diff.div(d * d);
        steeringForce.add(diff);
        total++;
      }
    }
    if (total > 0) {
      steeringForce.div(total);
      steeringForce.sub(this.vel);
    }
    return steeringForce;
  }

  Rectangle getSearchArea()
  {
    return new Rectangle(
      this.pos.x - searchRadius, 
      this.pos.y - searchRadius, 
      this.searchRadius * 2, 
      this.searchRadius * 2);
  }
}
