class Boid extends Particle
{
  final float baseForce = r_max/100.;

  final float alignValue = 1.;
  final float cohesionValue = 0.5;
  final float seperationValue = 0.01;

  final float alignmentPerceptionRadius = 25;
  final float cohesionPerceptionRadius = 50;
  final float separationPerceptionRadius = 25;

  final float maximumForce = 100*baseForce;

  float searchRadius = 50;
  Boid(PGraphics canvas)
  {
    super(canvas);
  }


  Boid(PGraphics canvas, int colour)
  {
    super(canvas, colour);
  }

  Boid(PGraphics canvas, int x, int y)
  {
    super(canvas, x, y);
  }


  Boid(PGraphics canvas, int x, int y, int colour)
  {
    super(canvas, x, y, colour);
  }

  void flock(Boid[] swarm)
  {
    PVector alignmentForce = this.getAlignmentForce(swarm);
    PVector cohesionForce = this.getCohesionForce(swarm);
    PVector separationForce = this.getSeparationForce(swarm);

    alignmentForce.mult(this.alignValue * this.baseForce);
    cohesionForce.mult(this.cohesionValue * this.baseForce);
    separationForce.mult(this.seperationValue * this.baseForce);

    PVector totalForce = PVector.add(alignmentForce, cohesionForce);
    totalForce.add(separationForce);
    totalForce.limit(maximumForce);

    this.applyForce(totalForce);
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
        if (d < 0.001)
        {
          d = 0.001;
        }
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
