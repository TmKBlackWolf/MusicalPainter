class Boid extends Particle
{
  float alignValue = 0.05;
  float cohesionValue = 0.05;
  float seperationValue = 0.05;
  int alignmentPerceptionRadius = 50;
  int cohesionPerceptionRadius = 100;
  int separationPerceptionRadius = 50;
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
    super(x,y, colour);
  }
  
  void flock(BoidSwarm swarm)
  {
    PVector alignmentForce = this.getAlignmentForce(swarm);
    PVector cohesionForce = this.getCohesionForce(swarm);
    PVector separationForce = this.getSeparationForce(swarm);

    alignmentForce.mult(alignValue);
    cohesionForce.mult(cohesionValue);
    separationForce.mult(seperationValue);

    this.applyForce(alignmentForce);
    this.applyForce(cohesionForce);
    this.applyForce(separationForce);
    
  }
  
  PVector getAlignmentForce(BoidSwarm swarm) {
    
    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other: swarm.particles) {
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
  
  
  
  PVector getCohesionForce(BoidSwarm swarm) {
    
    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other: swarm.particles) {
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
  
  
  
    PVector getSeparationForce(BoidSwarm swarm) {
    
    PVector steeringForce = new PVector();
    int total = 0;
    for (Particle other: swarm.particles) {
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
  
  
  
  
  
}
