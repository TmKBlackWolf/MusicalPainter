class BoidSwarm extends Swarm {

  Boid[] particles;
  

  BoidSwarm(PGraphics canvas, int numberOfParticles)
  {
    super(canvas, numberOfParticles);
  } 


  protected void initParticles()
  {
    this.particles =  new Boid[this.numberOfParticles];

    for ( int i = 0; i < this.numberOfParticles; i++)
    {
      this.particles[i] = new Boid(this.canvas, i % 256);
    }
  }
}
