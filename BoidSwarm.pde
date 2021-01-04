class BoidSwarm extends Swarm {

  Boid[] particles;

  BoidSwarm(int numberOfParticles, int areaWidth, int areaHeight)
  {
    super(numberOfParticles, areaWidth, areaHeight);
  } 


  protected void initParticles()
  {
    this.particles =  new Boid[this.numberOfParticles];

    for ( int i = 0; i < this.numberOfParticles; i++)
    {
      this.particles[i] = new Boid(i % 256);
    }
  }
}
