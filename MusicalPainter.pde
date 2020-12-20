import processing.sound.*;  //<>// //<>// //<>//

PImage baseImage;
PVector ImageCenterOffset;

FFT fft;
AudioIn in;
int bands = 512;
float[] spectrum = new float[bands];
float[] old_spectrum = new float[bands]; 
float max_a[] = new float[bands];
float expectedMaxAmplitude = 0.1;
Object spectrumMutex = new Object();

OpenSimplexNoise simplex_noise;
float scale = 0.001;
float zoff = 0;

BoidSwarm swarm;
QuadTree tree;
Object treeMutex = new Object();
float deltaT = 0.001;
int r_max = 100;
int r_min = 80;


int warmupCounter = 60 * 1;

void setup() {
  fullScreen(P2D);
  colorMode(HSB);
  background(0);


  setupBaseImage();
  setupParticles();
  setupNoiseField();
  setupAudioInput();
  startAudioProcessingThread();
  startParticleThread();
}


void setupBaseImage()
{

  //baseImage = loadImage("input/winter-1920.jpg");
  baseImage = loadImage("input/Kassenbild.png");
  float imageAspectRatio = baseImage.width/(float)baseImage.height;
  float screenAspectRatio = width/(float)height;

  if (  imageAspectRatio > screenAspectRatio)
  {
    resizeImageToHeight(baseImage);
  }
  else
  {
    resizeImageToWidth(baseImage);
  }
  ImageCenterOffset = new PVector((width - baseImage.width) /2., (height - baseImage.height) /2.);
}

void resizeImageToHeight(PImage img)
{
  img.resize(0, height);
}

void resizeImageToWidth(PImage img)
{
  img.resize(width, 0);
}

void setupParticles()
{
  swarm = new BoidSwarm( bands*5, width, height); 
  buildTree();
}

void setupNoiseField()
{
  simplex_noise = new OpenSimplexNoise((int)random(0, 25000));
  noiseDetail(25);
}

void setupAudioInput()
{
  for ( int i = 0; i < bands; i++)
  {
    max_a[i] = expectedMaxAmplitude;
  }

  fft = new FFT(this, bands);

  in = new AudioIn(this, 1);
  in.start();
  fft.input(in);
}
void startAudioProcessingThread()
{
  thread("runContinousFFTUpdate");
}

void startParticleThread()
{
  thread("continousParticleUpdate");
}


void printDebugInfo()
{
  println("Frame rate  : ", frameRate);
  println("Update rate : ", 1./deltaT);
  println("Delta_T     : ", deltaT);
  println("Z_off       : ", zoff);
  println("A_max       : ", max(max_a));
  println();
}

void draw() { 
  printDebugInfo();


  drawWarmUp();



  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);

  for (int i = 0; i < swarm.numberOfParticles; i++) 
  {
    float currentAmplitude = currentAmplitudes[i % bands];
    float maxAmplitude = maxAmplitudes[i % bands];
    drawParticle(i, currentAmplitude, maxAmplitude );
  }
}


void drawWarmUp()
{
  if (warmupCounter > 0)
  {    
    fill(0);
    noStroke();
    rect(0, 0, width, height);



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

    drawFFT();

    if (warmupCounter == 1)
    {
      noStroke();
      fill(0);
      rect(0, 0, width, height);
    }
    warmupCounter--;
  }
}


void drawFFT()
{
  pushMatrix();

  float fftViewScale = 1./4.;


  translate(width *(1- fftViewScale), height*(1-fftViewScale));
  float viewWidth = width * fftViewScale;
  float viewHeight = height *fftViewScale;


  float barWidth = viewWidth / bands;

  strokeWeight(1);
  stroke(127);
  fill(255);
  rect(0, 0, viewWidth, viewHeight);

  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);

  for (int i = 0; i < bands; i++)  
  {
    float currentAmplitude = currentAmplitudes[i];
    float maxAmplitude = maxAmplitudes[i];
    stroke(127);
    fill(127);
    rect(
      i * barWidth, 
      viewHeight-map(maxAmplitude, 0, expectedMaxAmplitude, 0, viewHeight), 
      (i+1)*barWidth, 
      viewHeight);

    stroke(i%256, 255, 255);
    fill(i%256, 255, 255);
    rect(
      i * barWidth, 
      viewHeight-map(currentAmplitude, 0, expectedMaxAmplitude, 0, viewHeight), 
      (i+1)*barWidth, 
      viewHeight);

    float sat = map(currentAmplitude, 0, maxAmplitude, 127, 255);
    float bright = map(currentAmplitude, 0, maxAmplitude, 127, 255);
    //float alpha = map(currentAmplitude, 0, maxAmplitude, 10, 255);

    noStroke();
    fill(i%256, sat, bright);
    rect(
      i * barWidth, 
      0, 
      (i+1)*barWidth, 
      barWidth*10);
  }
  popMatrix();
}


void drawParticle(int particleIndex, float currentAmplitude, float maxAmplitude)
{

  float sat = 0;
  float bright = 0;
  float alpha = 0;
  Boid p = swarm.particles[particleIndex]; 
  color baseColour = get_image_color(floor(p.getX()), floor(p.getY()));
  sat = saturation(baseColour);
  bright = brightness(baseColour);
  if (maxAmplitude > 0)
  {
    alpha = map(currentAmplitude, 0, maxAmplitude, 10, 127);
  }


  if (p.tryLock())
  {
    stroke(p.colour, sat, bright, alpha);
    p.display();
    p.unlock();
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
      strokeWeight(1);
      line(x, y, x + f.x, y + f.y);
      strokeWeight(3);
      point(x + f.x, y + f.y);
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


color get_image_color(int x, int y)
{
  baseImage.loadPixels();
  return baseImage.pixels[(((x -floor(ImageCenterOffset.x) ))+ ((y - floor(ImageCenterOffset.y) ) )* baseImage.width) ];
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
    buildTree();

    float currentAmplitudes[] = new float[bands];
    float maxAmplitudes[] = new float[bands];
    loadCurrentSpectrum(currentAmplitudes, maxAmplitudes );

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
      {
        amp = map(currentAmplitude, 0, maxAmplitude, 0., 50.);
      }   
      f.mult(random(r_min, r_max) + amp);
      p.applyForce(f);
      p.flock(queryTree(p));
      p.doSubstepWithoutForce(deltaT);
    }  

    float spectrum_sum = 0;
    synchronized (spectrumMutex) {
      zoff += euclidiean_distance(spectrum, old_spectrum)*deltaT*300;
    } 
    deltaT =(millis()-start_time) /1000.;
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
