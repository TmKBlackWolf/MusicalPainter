import java.lang.*;  //<>// //<>//
import java.util.concurrent.locks.ReentrantLock;

class Particle  extends ReentrantLock implements Mapable {
  ArrayList<PVector> previousPositions = new ArrayList<PVector>();
  PVector currentPosition;
  PVector vel;
  PVector oldDrawVel;
  PVector drawVel;
  PVector oldDrawAcc;
  PVector drawAcc;
  PVector acc;
  boolean wasUpdated;



  int colour;

  float res;


  Particle()
  {
    this.currentPosition = new PVector(random(width), random(height));
    this.init();
    this.colour = 0;
  }


  Particle(int colour)
  {
    this.currentPosition = new PVector(random(width), random(height));
    this.init();
    this.colour = colour;
  }

  Particle(int x, int y)
  {
    this.currentPosition = new PVector(x, y);

    this.init();
    this.colour = 0;
  }


  Particle(int x, int y, int colour)
  {
    this.currentPosition = new PVector(x, y);
    this.init();

    this.colour = colour;
  }


  void init()
  {


    this.vel = new PVector(0, 0);
    this.oldDrawVel = new PVector(0, 0);
    this.drawVel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    this.oldDrawAcc = new PVector(0, 0);
    this.drawAcc = new PVector(0, 0);
    this.wasUpdated = true;

    this.res = -0.001;
  }

  void update()
  {
    this.update(1.);
  }

  void update(float deltaT)
  {

    PVector dAcc = PVector.mult(this.acc, deltaT);
    this.vel.add(dAcc); 
    this.drawAcc.add(dAcc);
    PVector dVel = PVector.mult(vel, deltaT); 
    //this.previousPositions.add(this.currentPosition.copy());
    //if (this.previousPositions.size() >= 60)
    //{
    //  this.previousPositions.remove(0);
    //}
    this.currentPosition.add(dVel);
    this.drawVel.add(dVel);
    this.acc.mult(0);
    this.wasUpdated = true;
  }



  void applyForce(PVector f)
  {
    this.lock();
    this.acc.add(f);
    this.unlock();
  } 

  void resist()
  {    
    PVector f = this.vel.copy();

    f.normalize();

    double v_sq = mag_double(this.vel);
    double v_sq_1 = v_sq * this.res;
    double v_sq_2 = v_sq_1 * v_sq;
    float f_v_sq =(float) v_sq_2;

    f.mult(f_v_sq);

    try {
      verifyPVector(f);
      this.applyForce(f);
    }
    catch(Exception e)
    {
      this.acc.mult(0.);
    }
  }

  float getX()
  {
    return this.currentPosition.x;
  }

  float getY()
  {
    return this.currentPosition.y;
  }


  double mag_double(PVector p)
  {
    double x = p.x;
    double y = p.y;
    double z = p.z;

    return Math.sqrt(x*x + y*y + z*z);
  }

  void display()
  { 
    if (this.wasUpdated)
    {
      if (this.drawVel.mag() < height/4)
      {
        curve(
          this.currentPosition.x-(this.drawVel.x + this.oldDrawVel.x), this.currentPosition.y-(this.drawVel.y + this.oldDrawVel.y ), 
          this.currentPosition.x - this.drawVel.x, this.currentPosition.y - this.drawVel.y, 
          this.currentPosition.x, this.currentPosition.y, 
          this.currentPosition.x + this.drawVel.x + this.drawAcc.x / 2., this.currentPosition.y + this.drawVel.y + this.drawAcc.y / 2.);
      }
      this.oldDrawVel.set(drawVel);
      this.drawVel.mult(0);
      this.oldDrawAcc.set(drawAcc);
      this.drawAcc.mult(0);
      this.wasUpdated = false;
    }
  }

  void displayPath()
  { 
    if (this.previousPositions.size() > 0)
    {

      beginShape();
      PVector previous = this.previousPositions.get(0);
      curveVertex(previous.x, previous.y, 0.);
      for (int i = 1; i < this.previousPositions.size(); i ++)
      {     

        PVector current = this.previousPositions.get(i);
        if (dist(previous.x, previous.y, current.x, current.y) >= height/4)
        {
          endShape();
          i+=4;
          beginShape();
        } else
        {
          curveVertex(current.x, current.y, i*30);
        }
        previous = current;
      }
      endShape();
    }

    if (this.wasUpdated)
    {
      this.previousPositions.add(this.currentPosition.copy()); 
      this.wasUpdated = false;
    }
    if (this.previousPositions.size() >= 60)
    {
      this.previousPositions.remove(0);
    }
  }


  void displayPos()
  {
    point(this.currentPosition.x, this.currentPosition.y);
  }

  void edges()
  {
    this.currentPosition.x = ((this.currentPosition.x % width) +  width) % width;
    this.currentPosition.y = ((this.currentPosition.y % height) +  height) % height;
  }


  void doSubstep(PVector appliedForce, float deltaT)
  {
    this.lock();
    this.applyForce(appliedForce);
    this.resist();
    this.update(deltaT);
    this.edges();  
    this.unlock();
  }

  void doSubstepWithoutForce(float deltaT)
  {    
    this.lock();
    this.resist();
    this.update(deltaT);
    this.edges();  
    this.unlock();
  }
}
