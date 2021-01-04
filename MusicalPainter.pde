import processing.sound.*;   //<>//

final boolean useImages = false;

int inputFileIndex = 0;
PImage baseImage;
PVector ImageCenterOffset;
int ImageChangeIntervalInSeconds = 60 * 7;
Object imageMutex = new Object();

TorusNoiseField noiseField;
float scale = 0.001;
float toff = 0;
float changeFactor = 0.5;
float deltaT_A = 0.1;

BoidSwarm swarm;
QuadTree tree;
Object treeMutex = new Object();
float deltaT = 0.001;
int r_max = 200;  
int r_min = 160;

//int warmupCounter = 60*60;
int warmupCounter = 0;

PGraphics canvas;

void verifyPVector(PVector p) throws Exception
{
  float test = p.mag();
  if (test != test)
  {
    throw new Exception("NaN magnitude PVector");
  }
}

void setup() {
  fullScreen(P2D);
  colorMode(HSB);
  background(0);
  frameRate(30);
  
  canvas = createGraphics(width, height);


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
  float screenAspectRatio = canvas.width/(float)canvas.height;

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
    ImageCenterOffset = new PVector((canvas.width - baseImage.width) /2., (canvas.height - baseImage.height) /2.);
  }
}

void resizeImageToHeight(PImage img)
{
  img.resize(0, canvas.height);
}

void resizeImageToWidth(PImage img)
{
  img.resize(canvas.width, 0);
}

void setupParticles()
{
  swarm = new BoidSwarm(canvas, bands*5); 
  buildTree();
}

void setupNoiseField()
{ 
  noiseField = new TorusNoiseField((long) random(0, 25000), (double) (canvas.height * scale), (double) (canvas.width * scale));
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

void draw() 
{ 
  background(255);
  canvas.beginDraw();
  canvas.colorMode(HSB);
  
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
  
  canvas.endDraw();
  int numberTiles = 6;
  for(int i = 0; i < numberTiles; i++)
  {
    for( int j = 0; j < numberTiles; j++)
    {
      image(canvas, i * (width/numberTiles), j * (height/numberTiles), width/numberTiles, height/numberTiles);
    }
  }
  
}


void drawWarmUp()
{
  if (warmupCounter > 0)
  {    
    canvas.fill(0);
    canvas.noStroke();
    canvas.rect(0, 0, canvas.width, canvas.height);
    if (useImages)
    {
      canvas.image(baseImage, ImageCenterOffset.x, ImageCenterOffset.y);
    }
    
    canvas.stroke(255);
    canvas.noFill();
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
      canvas.noStroke();
      canvas.fill(0);
      canvas.rect(0, 0, canvas.width, canvas.height);
    }
    warmupCounter--;
  }
}


void drawFFT()
{
  canvas.pushMatrix();

  float fftViewScale = 1./4.;

  canvas.translate(canvas.width *(1- fftViewScale), canvas.height*(1-fftViewScale));
  float viewWidth = canvas.width * fftViewScale;
  float viewHeight = canvas.height *fftViewScale;

  canvas.strokeWeight(1);
  canvas.stroke(127);
  canvas.fill(255);
  canvas.rect(0, 0, viewWidth, viewHeight);

  float currentAmplitudes[] = new float[bands];
  float maxAmplitudes[] = new float[bands];

  loadCurrentSpectrum(currentAmplitudes, maxAmplitudes);
  float barWidth = viewWidth / bands;
  for (int i = 0; i < bands; i++)  
  {

    float maxAmplitude = maxAmplitudes[i];
    float barHeight = map(maxAmplitude, 0, expectedMaxAmplitude, 0, viewHeight);

    canvas.stroke(127);
    canvas.fill(127);
    canvas.rect(
      i * barWidth, 
      viewHeight-barHeight, 
      barWidth, 
      barHeight);

    float currentAmplitude = currentAmplitudes[i];
    barHeight = map(currentAmplitude, 0, expectedMaxAmplitude, 0, viewHeight);

    canvas.stroke(i%256, 255, 255);
    canvas.fill(i%256, 255, 255);
    canvas.rect(
      i * barWidth, 
      viewHeight-barHeight, 
      barWidth, 
      barHeight);

    float sat = map(currentAmplitude, 0, maxAmplitude, 127, 255);
    float bright = map(currentAmplitude, 0, maxAmplitude, 127, 255);

    canvas.stroke(i%256, sat, bright);
    canvas.fill(i%256, sat, bright);
    canvas.rect(
      i * barWidth, 
      0, 
      barWidth, 
      barWidth*10);
  }
  canvas.popMatrix();
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

  canvas.stroke(p.colour, sat, bright, alpha);
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
    alpha = map(currentAmplitude, 0, maxAmplitude, 10, 64);
  }

  Boid p = swarm.particles[particleIndex]; 
  canvas.stroke(p.colour, sat, bright, alpha);
  displayParticleIfUnlocked(p);
}

void displayParticleIfUnlocked(Particle p)
{
  canvas.noFill();
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
    tree = new QuadTree(canvas);
    tree.insert(swarm.particles);
  }
}

void showField()
{
  for (int x = 0; x < canvas.width; x += 50)
  {
    for (int y = 0; y < canvas.height; y += 50)
    {

      float noise_val = (float) noiseField.eval(x*scale, y*scale, toff);
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      f.mult(25);
      canvas.strokeWeight(1);
      canvas.line(x, y, x + f.x, y + f.y);
      canvas.strokeWeight(3);
      canvas.point(x + f.x, y + f.y);
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

      float noise_val = (float) noiseField.eval(
        p.pos.x * scale, 
        p.pos.y * scale, 
        toff + ((p.colour - 128) * scale));
      PVector f =  PVector.fromAngle(noise_val*PI*4);
      f.normalize();
      float amp =  0;
      if (maxAmplitude > 0)
      {
        amp = map(currentAmplitude, 0, maxAmplitude, 0., r_max);
      }   
      f.mult(0.5*random(r_min, r_max) + amp);
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
