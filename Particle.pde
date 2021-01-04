import java.lang.*;  //<>// //<>//
import java.util.concurrent.locks.ReentrantLock;

class Particle  extends ReentrantLock implements Mapable {
  PVector pos;
  PVector vel;
  PVector oldDrawVel;
  PVector drawVel;
  PVector oldDrawAcc;
  PVector drawAcc;
  PVector acc;
  boolean wasUpdated;


  PGraphics canvas;



  int colour;

  float res;


  Particle(PGraphics canvas)
  {
    this.canvas = canvas;
    this.pos = new PVector(random(canvas.width), random(canvas.height));
    this.init();
    this.colour = 0;
  }


  Particle(PGraphics canvas, int colour)
  {
    this.canvas = canvas;
    this.pos = new PVector(random(canvas.width), random(canvas.height));
    this.init();
    this.colour = colour;
  }

  Particle(PGraphics canvas, int x, int y)
  {
    this.canvas = canvas;
    this.pos = new PVector(x, y);

    this.init();
    this.colour = 0;
  }


  Particle(PGraphics canvas, int x, int y, int colour)
  {
    this.canvas = canvas;
    this.pos = new PVector(x, y);
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
    this.pos.add(dVel);
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
      if (this.drawVel.mag() < this.canvas.height/4)
      {
        this.canvas.curve(
          this.pos.x-(this.drawVel.x + this.oldDrawVel.x), this.pos.y-(this.drawVel.y + this.oldDrawVel.y ), 
          this.pos.x - this.drawVel.x, this.pos.y - this.drawVel.y, 
          this.pos.x, this.pos.y, 
          this.pos.x + this.drawVel.x + this.drawAcc.x / 2., this.pos.y + this.drawVel.y + this.drawAcc.y / 2.);
      }
      this.oldDrawVel.set(drawVel);
      this.drawVel.mult(0);
      this.oldDrawAcc.set(drawAcc);
      this.drawAcc.mult(0);
      this.wasUpdated = false;
    }
  }


  void displayPos()
  {
    this.canvas.point(this.pos.x, this.pos.y);
  }

  void edges()
  {
    this.pos.x = ((this.pos.x % this.canvas.width) + this.canvas.width) % this.canvas.width;
    this.pos.y = ((this.pos.y % this.canvas.height) + this.canvas.height) % this.canvas.height;
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
