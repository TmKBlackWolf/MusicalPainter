class Swarm {
  int areaWidth;
  int areaHeight;
  int numberOfParticles;
  int magicNumber;
  PGraphics canvas;

  Particle[] particles;  

  Swarm(PGraphics canvas, int numberOfParticles)
  {
    this.canvas = canvas;
    this.areaWidth = canvas.width;
    this.areaHeight = canvas.height;

    this.numberOfParticles = numberOfParticles;
    this.initParticles();
  }
  
  protected void initParticles()
  {
        this.particles =  new Particle[this.numberOfParticles];

    for ( int i = 0; i < this.numberOfParticles; i++)
    {
      this.particles[i] = new Particle(this.canvas, i % 256);
    }    
  }
}
