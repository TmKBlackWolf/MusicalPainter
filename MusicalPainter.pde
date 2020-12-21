import processing.sound.*;   //<>//

final boolean useImages = true;

int inputFileIndex = 1;
PImage baseImage;
PVector ImageCenterOffset;
int ImageChangeIntervalInSeconds = 6000;
Object imageMutex = new Object();


CylindricalNoiseField noiseField;
float scale = 0.001;
float toff = 0;
float changeFactor = 10.;
float deltaT_A = 0.1;

BoidSwarm swarm;
QuadTree tree;
Object treeMutex = new Object();
float deltaT = 0.001;
int r_max = 100;
int r_min = 80;


int warmupCounter = 60*60;

void setup() {
  fullScreen(P2D);
  colorMode(HSB);
  background(0);

  


  if (useImages)
  {
    setupBaseImage();
    thread("updateImagecontinously");
  }
  setupParticles();
  setupNoiseField();
  setupAudioInput();
  startAudioProcessingThread();
  startParticleThread();
}





void setupBaseImage()
{    
  String inputPath = sketchPath("") + "\\input\\";
  String[] filenames = new File(inputPath).list();

  inputFileIndex = (inputFileIndex + filenames.length) % filenames.length;
  PImage newImage= loadImage(inputPath + filenames[inputFileIndex]);

  float imageAspectRatio = newImage.width/(float)newImage.height;
  float screenAspectRatio = width/(float)height;

  if (  imageAspectRatio > screenAspectRatio)
  {
    resizeImageToHeight(newImage);
  } else
  {
    resizeImageToWidth(newImage);
  }
  synchronized(imageMutex)
  {
    baseImage = newImage;
    ImageCenterOffset = new PVector((width - baseImage.width) /2., (height - baseImage.height) /2.);
  }
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
  noiseField = new CylindricalNoiseField((long) random(0, 25000), (double) (height * scale));
  noiseDetail(25);
}

void startParticleThread()
{
  thread("continousParticleUpdate");
}


void printDebugInfo()
{
  println("Frame rate   : ", frameRate);
  println("Update rate  : ", 1./deltaT);
  println("Delta_T      : ", deltaT);
  println("Z_off        : ", toff);
  println("Spec_max     : ", max(spectrum));
  println("A_max        : ", max(max_a));
  println("ChangeFactor : ", changeFactor);
  println("WarmupCounter: ", warmupCounter);
  println("deltaT_A     : ", deltaT_A);
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
    if (useImages)
    {
      drawParticleUsingImage(i, currentAmplitude, maxAmplitude );
    } else
    {
      drawParticle(i, currentAmplitude, maxAmplitude );
    }
  }
}


void drawWarmUp()
{
  if (warmupCounter > 0)
  {    
    fill(0);
    noStroke();
    rect(0, 0, width, height);
    if (useImages)
    {
      image(baseImage, ImageCenterOffset.x, ImageCenterOffset.y);
    }


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

  strokeWeight(1);
  stroke(127);
  fill(255);
  rect(0, 0, viewWidth, viewHeight);

  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);

  for (int i = 0; i < bands; i++)  
  {
    float barWidth = viewWidth / bands;
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


void drawParticleUsingImage(int particleIndex, float currentAmplitude, float maxAmplitude)
{
  Boid p = swarm.particles[particleIndex]; 

  color baseColour = get_image_color(floor(p.getX()), floor(p.getY()));
  float sat = saturation(baseColour);
  float bright = brightness(baseColour);

  float alpha = 0;  
  if (maxAmplitude > 0)
  {
    alpha = map(currentAmplitude, 0, maxAmplitude, 10, 64);
  }

  stroke(p.colour, sat, bright, alpha);
  displayParticleIfUnlocked(p);
}


void drawParticle(int particleIndex, float currentAmplitude, float maxAmplitude)
{
  float sat = 0;
  float bright = 0;
  float alpha = 0;
  if (maxAmplitude > 0)
  {
    sat = map(currentAmplitude, 0, maxAmplitude, 127, 255);
    bright = map(currentAmplitude, 0, maxAmplitude, 127, 255);
    alpha = map(currentAmplitude, 0, maxAmplitude, 10, 255);
  }

  Boid p = swarm.particles[particleIndex]; 
  stroke(p.colour, sat, bright, alpha);
  displayParticleIfUnlocked(p);
}

void displayParticleIfUnlocked(Particle p)
{
  noFill();
  if (p.tryLock())
  {    
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

      float noise_val = (float) noiseField.eval(x*scale, y*scale, toff);
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
  color ret;
  synchronized(imageMutex)
  {
    baseImage.loadPixels();
    int x_ = x - floor(ImageCenterOffset.x);
    int y_ = y - floor(ImageCenterOffset.y);
    int index = x_+ (y_ * baseImage.width);
    ret = baseImage.pixels[((index % baseImage.pixels.length) + baseImage.pixels.length)% baseImage.pixels.length];
  }
  return ret;
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

      float noise_val =(float) noiseField.eval(
        p.pos.x * scale, 
        p.pos.y * scale, 
        toff + ((p.colour - 128) * scale));
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      float amp =  0;
      if (maxAmplitude > 0)
      {
        amp = map(currentAmplitude, 0, maxAmplitude, 0., 5*r_max);
      }   
      f.mult(random(r_min, r_max) + amp);
      p.applyForce(f);
      p.flock(queryTree(p));
      p.doSubstepWithoutForce(deltaT);
    }  

    float spectrum_sum = 0;
    synchronized (spectrumMutex) {
      toff += euclidiean_distance(spectrum, old_spectrum)*deltaT*changeFactor;
    } 
    deltaT =(millis()-start_time) /1000.;
  }
}




float euclidiean_distance(float[] a, float[] b)
{
  float sum = 0;
  for (int i = 0; i < bands; i++)
  {
    sum += sq(a[i] - b[i]);
  }
  sum = sqrt(sum);

  if (sum != sum)
  {
    println("Euclid NaN!");
  }  
  return sum;
}

void mousePressed() {

  String outputFileName ="output/"+ String.valueOf(year()) + "-" 
    +String.valueOf(month()) + "-" 
    +String.valueOf(day())
    +"_frame_####.png";

  saveFrame(outputFileName);
}


void updateImagecontinously()
{
  for (;; )
  {
    delay(ImageChangeIntervalInSeconds*1000);
    inputFileIndex++;
    setupBaseImage();
  }
}

void keyPressed() 
{
  switch (key)
  {
  case CODED:
    handleCodedKey();
    break;
  case 'w':
    changeFactor += 10.;
    break;
  case 's':
    changeFactor -= 10.;
    break;
  case 'e':
    warmupCounter = 60;
    break;
  default:
    break;
  }
}

void handleCodedKey()
{
  switch(keyCode)
  {
  case RIGHT:
    if (useImages)
    {
      inputFileIndex++;
      setupBaseImage();
    } else {
      toff += 10.;
    }
    break;
  case LEFT:
    if (useImages)
    {
      inputFileIndex--;
      setupBaseImage();
    } else {
      toff -= 10.;
    }
    break;
  case UP:
    toff += 0.1;
    break;
  case DOWN:
    toff -= 0.1;
    break;
  default:
    break;
  }
}
