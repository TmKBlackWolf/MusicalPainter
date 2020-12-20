import processing.sound.*;  //<>// //<>//

FFT fft;
AudioIn in;

boolean debug = false;

int bands = 512;
float[] spectrum = new float[bands];

float deltaT = 0.001;
float deltaT_Spectrum = 0.001;

Object spectrumMutex = new Object();


float scale = 0.001;
float zoff = 0;

QuadTree tree;
Object treeMutex = new Object();

OpenSimplexNoise simplex_noise;

int r_max = 10;
int r_min = 9;

float max_a[] = new float[bands];

float current_v[] = new float[bands];
float old_v[] = new float[bands];

boolean zoff_was_updated = true;


int f_start = 0;
int f_min = 50;
int f_max = 10000;
float[] old_spectrum = new float[bands]; 

BoidSwarm swarm;

int treeAlpha = 255;

void setup() {
  colorMode(HSB);
  fullScreen(P2D);
  //size(1600, 1200, P2D );
  background(0);

  swarm = new BoidSwarm( bands*5, width, height); 
  buildTree();


  for ( int i = 0; i < bands; i++)
  {
    max_a[i] = 1.;
  }

  simplex_noise = new OpenSimplexNoise((int)random(0, 25000));


  noiseDetail(25);

  // Create an Input stream which is routed into the Amplitude analyzer
  fft = new FFT(this, bands);
  in = new AudioIn(this, 1);
  in.start();

  fft.input(in);


  thread("runContinousFFTUpdate");

  thread("continousParticleUpdate");
}

void draw() { 
  noStroke();
  fill(0, 10);
  if (debug)
  {
    rect(0, 0, width, height);
  }
  println(frameRate);
  println(deltaT);
  println(zoff);
  println();
  
  if (treeAlpha > 0)
  {
    fill(0);
    rect(0, 0, width, height);
  }


  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);



  for (int i = 0; i < swarm.numberOfParticles; i++) 
  {
    float currentAmplitude = currentAmplitudes[i % bands];
    float maxAmplitude = maxAmplitudes[i % bands];

    float sat = 0;
    float bright = 0;
    float alpha = 0;
    if (maxAmplitude > 0)
    {
      sat = map(currentAmplitude, 0, maxAmplitude, 127, 255);
      bright = map(currentAmplitude, 0, maxAmplitude, 127, 255);

      alpha = map(currentAmplitude, 0, maxAmplitude, 10, 255);
    }

    Boid p = swarm.particles[i]; 
    if (p.tryLock())
    {
      stroke(p.colour, sat, bright, alpha);
      p.display();
      p.unlock();
    }
  }
  if (treeAlpha > 0)
  {    
    stroke(255);
    noFill();
    //showTree();
    showField();
    strokeWeight(3);
    for (int i = 0; i < swarm.numberOfParticles; i++) 
    {
      Boid p = swarm.particles[i]; 
      if (p.tryLock())
      {

        p.displayPos();
        p.unlock();
      }
    }

    if (treeAlpha == 1)
    {
      noStroke();
      fill(0);
      rect(0, 0, width, height);
    }
    treeAlpha--;
  }
}

void buildTree()
{
  synchronized(treeMutex)
  {
    tree = new QuadTree();
    tree.insert(swarm.particles);
  }
}

void showField()
{
  for (int x = 0; x < width; x += 50)
  {
    for (int y = 0; y < height; y += 50)
    {
      float noise_val = current_noise_function(x, y, height/2, zoff );
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      f.mult(25);
      line(x, y, x + f.x, y + f.y);
    }
  }
}


void showTree()
{
  synchronized(treeMutex)
  {
    tree.show();
  }
}

Boid[] queryTree(Boid p)
{
  p.lock();
  Rectangle area = p.getSearchArea();
  p.unlock();
  ArrayList<Boid> ret;
  synchronized(treeMutex)
  {
    ret = tree.queryArea(area);
  }
  if (ret == null)
  {
    return new Boid[0];
  } else
  {
    return ret.toArray(new Boid[0]);
  }
}


void loadCurrentSpectrum(float amplitudes[], float maximumAmplitudes[])
{
  synchronized (spectrumMutex) {
    for (int i = 0; i< bands; i++) {
      amplitudes[i] = spectrum[i];
      maximumAmplitudes[i] = max_a[i];
    }
  }
}

void continousParticleUpdate()
{

  int start_time;

  for (int i = 0; i< bands; i++) {
    old_spectrum[i] = 0.;
  }
  for (;; )
  {    
    start_time = millis();


    float currentAmplitudes[] = new float[bands];
    float maxAmplitudes[] = new float[bands];
    synchronized (spectrumMutex) {
      for (int i = 0; i< bands; i++) {
        currentAmplitudes[i] = spectrum[i];
        maxAmplitudes[i] = max_a[i];
      }
    }
    buildTree();


    float currentAmplitude;
    float maxAmplitude;
    for (int i = 0; i < swarm.numberOfParticles; i++) 
    {
      currentAmplitude = currentAmplitudes[i % bands];
      maxAmplitude = maxAmplitudes[i % bands];

      Boid p= swarm.particles[i];  

      PVector particlePosition = p.pos;
      float noise_val = current_noise_function(p.pos.x, p.pos.y, height/2, zoff + (p.colour  *0.001));
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      float amp =  0;
      if (maxAmplitude > 0)
        amp = map(currentAmplitude, 0, maxAmplitude, 0., 5.);
      //float amp =  0;
      f.mult(random(r_min, r_max)+amp);
      p.applyForce(f);
      //p.flock(swarm.particles);
      p.flock(queryTree(p));
      p.doSubstepWithoutForce(deltaT);
    }  

    float spectrum_sum = 0;
    synchronized (spectrumMutex) {
      zoff += euclidiean_distance(spectrum, old_spectrum)*deltaT*50;
    } 



    deltaT =(float)(millis()-start_time)*6. /1000.;
  }
}


void updateFFT()
{
  synchronized (spectrumMutex) {   
    for (int i = 0; i < bands; i++)
    {
      old_spectrum[i] = spectrum[i];
      max_a[i] *= 0.99999;
    }

    fft.analyze(spectrum);
    for (int i = 0; i < bands; i++) {
      float v = spectrum[i];     
      if (v > max_a[i])
      {
        max_a[i] = v;
      }
    }
  }
}


void runContinousFFTUpdate()
{
  for (;; )
  {
    updateFFT();
  }
}



float euclidiean_distance(float[] a, float[] b)
{
  float sum = 0;
  for (int i = 0; i < bands; i++)
  {
    sum += sq(a[i] - b[i]);
  }

  return sqrt(sum);
}



float get_noise_on_cylinder(float x, float y, float c, float toff)
{
  float x_ = x;
  float theta = (y/c)*PI;

  float y_ = sin(theta)*c*0.5;
  float z_ = (1-cos(theta))*c*0.5;

  return (float) simplex_noise.eval(x_*scale, y_*scale, z_*scale, toff);
}


float current_noise_function(float x, float y, float r, float toff)
{
  return get_noise_on_cylinder(x, y, r, toff);
}


void mousePressed() {
  zoff += 1000;

  String outputFileName ="output/"+ String.valueOf(year()) + "-" 
    +String.valueOf(month()) + "-" 
    +String.valueOf(day())
    +"_frame_####.png";

  saveFrame(outputFileName);
}
