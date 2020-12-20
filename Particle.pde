import java.lang.*; //<>// //<>//
import java.util.concurrent.locks.ReentrantLock;

class Particle  extends ReentrantLock implements Mapable {
  PVector pos;
  PVector vel;
  PVector drawVel;
  PVector acc;
  boolean wasUpdated;



  int colour;

  float res;

  //PVector prev;

  Particle()
  {
    this.pos = new PVector(random(width), random(height));
    this.init();
    this.colour = 0;
  }


  Particle(int colour)
  {
    this.pos = new PVector(random(width), random(height));
    this.init();
    this.colour = colour;
  }

  Particle(int x, int y)
  {
    this.pos = new PVector(x, y);

    this.init();
    this.colour = 0;
  }


  Particle(int x, int y, int colour)
  {
    this.pos = new PVector(x, y);
    this.init();

    this.colour = colour;
  }


  void init()
  {

    this.drawVel = new PVector(0, 0);
    this.vel = new PVector(0, 0);
    this.acc = new PVector(0, 0);
    this.wasUpdated = true;

    this.res = -0.005;
  }

  void update()
  {
    //this.prev = this.pos.copy();

    this.vel.add(this.acc);    
    this.pos.add(this.vel);
    this.drawVel.add(this.vel);
    this.acc.mult(0);
    this.wasUpdated = true;
  }

  void update(float deltaT)
  {

    this.vel.add(PVector.mult(this.acc, deltaT));    
    PVector dVel = PVector.mult(vel, deltaT); 
    this.pos.add(dVel);
    this.drawVel.add(dVel);
    this.acc.mult(0);
    this.wasUpdated = true;
  }



  void applyForce(PVector f)
  {
    this.acc.add(f);
  } 

  void resist(float deltaT)
  {
    PVector f = this.vel.copy();

    f.normalize();

    double v_sq = mag_double(this.vel);
    double v_sq_1 = v_sq * this.res;
    double v_sq_2 = v_sq_1*mag_double(this.vel);
    float f_v_sq =(float) v_sq_2;
    f.mult(f_v_sq);

    float test = f.mag();
    if ( test != test)
    {
      this.applyForce(PVector.mult(this.vel, -1.));
    } else
    {
      this.applyForce(f);
    }
  }

  float getX()
  {
    return this.pos.x;
  }

  float getY()
  {
    return this.pos.y;
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
        line(this.pos.x, this.pos.y, this.pos.x-this.drawVel.x, this.pos.y- this.drawVel.y);
      this.drawVel.mult(0);
      this.wasUpdated = false;
    }
  }


  void displayPos()
  {
    point(this.pos.x, this.pos.y);
  }

  void edges()
  {
    this.pos.x = (this.pos.x + 20 * width) % width;
    this.pos.y = (this.pos.y + 20 * height) % height;
  }


  void doTimestep(PVector appliedForce, int numberOfSubiterations)
  {
    float deltaT = 1/(float)numberOfSubiterations;   

    for ( int i = 0; i < numberOfSubiterations; i++)
    {
      doSubstep(appliedForce, deltaT);
    }
  }

  void doSubstep(PVector appliedForce, float deltaT)
  {
    //PVector deltaF = appliedForce.mult(deltaT);
    this.lock();
    this.applyForce(appliedForce);
    this.resist(deltaT);
    this.update(deltaT);
    this.edges();  
    this.unlock();
  }
  void doSubstepWithoutForce(float deltaT)
  {    
    this.lock();
    this.resist(deltaT);
    this.update(deltaT);
    this.edges();  
    this.unlock();
  }
}
