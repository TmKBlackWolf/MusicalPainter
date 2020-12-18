

class Swarm{
  int areaWidth;
  int areaHeight;
  int numberOfParticles;
  int magicNumber;

  Particle[] particles;
  
  Swarm()
  {}


  Swarm(int numberOfParticles, int areaWidth, int areaHeight)
  {
    this.areaWidth = areaWidth;
    this.areaHeight = areaHeight;
    
    this.numberOfParticles = numberOfParticles;
    this.particles = new Particle[this.numberOfParticles];



    for ( int i = 0; i < this.numberOfParticles; i++)
    {
      this.particles[i] = new Particle(i % 256);
    }
  }  
}
