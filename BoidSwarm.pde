
class BoidSwarm extends Swarm{
  
  Boid[] particles;
  
  BoidSwarm(int numberOfParticles, int areaWidth, int areaHeight)
  {
    this.areaWidth = areaWidth;
    this.areaHeight = areaHeight;
    
    this.numberOfParticles = numberOfParticles;
    this.particles = new Boid[this.numberOfParticles];



    for ( int i = 0; i < this.numberOfParticles; i++)
    {
      this.particles[i] = new Boid(i % 256);
    }
  }
}
