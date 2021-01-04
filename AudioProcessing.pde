FFT fft;
AudioIn in;
int bands = 512;
float[] spectrum = new float[bands];
float[] old_spectrum = new float[bands]; 
float max_a[] = new float[bands];
float expectedMaxAmplitude = 0.2;
Object spectrumMutex = new Object();


void setupAudioInput()
{
  for ( int i = 0; i < bands; i++)
  {
    max_a[i] = expectedMaxAmplitude;
  }

  fft = new FFT(this, bands);

  in = new AudioIn(this, 0);
  in.start();
  fft.input(in);
}

void startAudioProcessingThread()
{
  thread("runContinousFFTUpdate");
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

void updateFFT()
{
  synchronized (spectrumMutex) {   
    for (int i = 0; i < bands; i++)
    {
      old_spectrum[i] = spectrum[i];
      max_a[i] *= pow(0.75,deltaT_A);
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
    int start_time = millis();
    updateFFT();
    delay((int)((deltaT*1000)/3));
    deltaT_A =(millis()-start_time) /1000.;
  }
}
