import processing.sound.*; //<>// //<>// //<>// //<>// //<>// //<>//

FFT fft;
//AudioIn in;
//

PinkNoise in;
SoundFile file;
SinOsc sine;
int bands = 512;
float[] spectrum = new float[bands];

float deltaT = 0.001;

int magic_number = 1;

Object spectrumMutex = new Object();


float scale = 0.001;
float zoff = 0;

float circumference1;

OpenSimplexNoise simplex_noise;

int r_max = 10;
int r_min = 9;


float test = 0.;


float max_a[] = new float[bands];

float current_v[] = new float[bands];
float old_v[] = new float[bands];

int blurrUp = 255;

boolean zoff_was_updated = true;


int f_start = 0;
int f_min = 50;
int f_max = 10000;


Swarm swarm;

void setup() {
  colorMode(HSB);
  fullScreen(P2D);
  //size(1600, 1200, P2D );
  background(255);

  swarm = new Swarm( bands*10, width, height, magic_number); 


  for ( int i = 0; i < bands; i++)
  {
    max_a[i] = 0.00000001;
  }


  //simplex_noise = new OpenSimplexNoise((int)random(0, 25000));
  simplex_noise = new OpenSimplexNoise((int)1);


  circumference1 = height/2;

  noiseDetail(25);

  // Create an Input stream which is routed into the Amplitude analyzer
  fft = new FFT(this, bands);
  //in = new AudioIn(this, 1);
  //in.start();

  in = new PinkNoise(this);

  //// patch the AudioIn
  fft.input(in);
  //fft = new FFT(this, bands);

  //sine = new SinOsc(this);
  //sine.play();
  //fft.input(sine);

  file = new SoundFile(this, "simon-swerwer_danger-room.mp3");
  fft.input(file);



  thread("runContinousFFTUpdate");

  thread("continousParticleUpdate");
}

void draw() { 
  fill(0, 10);
  noStroke();
  rect(0,0, width, height);
  
  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);



  for (int i = 0; i < swarm.numberOfParticles; i++) 
  {
    float currentAmplitude = currentAmplitudes[(i*magic_number)% bands];
    float maxAmplitude = maxAmplitudes[(i*magic_number)% bands];

    float sat = 0;
    float bright = 0;
    float alpha = 0;
    if (maxAmplitude > 0)
    {
      sat = map(currentAmplitude, 0, maxAmplitude, 127, 255);
      bright = map(currentAmplitude, 0, maxAmplitude, 127, 255);

      alpha = map(currentAmplitude, 0, maxAmplitude*0.75, 0, 255);
    }

    Particle p = swarm.particles[i]; 

    if (p.tryLock())
    {
      stroke(p.colour, sat, bright, alpha);
      p.display();
      p.unlock();
    }
  } 

  if (frameCount >5 && !file.isPlaying()) 
  {
    file.play();
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
  float[] old_spectrum = new float[bands]; 
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


    float currentAmplitude;
    float maxAmplitude;
    for (int i = 0; i < swarm.numberOfParticles; i++) 
    {

      currentAmplitude = currentAmplitudes[(i*magic_number)% bands];
      maxAmplitude = maxAmplitudes[(i*magic_number)% bands];

      Particle p= swarm.particles[i];  

      PVector particlePosition = p.pos;
      float noise_val = current_noise_function(p.pos.x, p.pos.y, circumference1, zoff + (p.colour  *0.001));
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      float amp =  0;
      if (maxAmplitude > 0)
        amp = map(currentAmplitude, 0, maxAmplitude, 0., 3);
      //float amp =  0;
      f.mult(random(r_min, r_max)+amp);

      p.doSubstep(f, deltaT);
    }  


    float spectrum_sum = 0;
    synchronized (spectrumMutex) {
      //zoff += pow(euclidiean_distance(spectrum, old_spectrum),4)*10000 * deltaT;
      zoff += euclidiean_distance(spectrum, old_spectrum) * 0.1;

      for (int i = 0; i < bands; i++)
      {
        old_spectrum[i] = spectrum[i];
      }
    } 

    for (int i = 0; i < bands; i++)
    {
      max_a[i] *= (1-pow(deltaT, 3));
    }
    deltaT =(float)(millis()-start_time)*6. /1000.;
  }
}




void updateFFT()
{
  synchronized (spectrumMutex) {   
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
    updateFFT();
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

float get_normal_noise(float x, float y, float r, float toff)
{
  float x_ = x;

  float y_ = y;
  float z_ = r;

  return (float) simplex_noise.eval(x_*scale, y_*scale, z_*scale, toff);
}

float current_noise_function(float x, float y, float r, float toff)
{
  return get_noise_on_cylinder(x, y, r, toff);
  //return get_normal_noise(x, y, r, toff);
}


void mousePressed() {
  zoff += 1000;
}
