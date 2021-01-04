import java.lang.*; 

class TorusNoiseField extends OpenSimplexNoise
{
  double verticalCircumference;
  double verticalRadius;
  
  double horizontalCircumference;
  double horizontalRadius;

  private TorusNoiseField()
  {
  }


  public TorusNoiseField(double verticalCircumference, double horizontalCircumference) 
  {
    super();
    this.setVerticalCircumference(verticalCircumference);
    this.setHorizontalCircumference(horizontalCircumference);
  }


  public TorusNoiseField(long seed, double verticalCircumference, double horizontalCircumference)
  {
    super(seed);
    this.setVerticalCircumference(verticalCircumference);
    this.setHorizontalCircumference(horizontalCircumference);
  }


  public TorusNoiseField(short[] perm, double verticalCircumference, double horizontalCircumference)
  {
    super(perm);
    this.setVerticalCircumference(verticalCircumference);
    this.setHorizontalCircumference(horizontalCircumference);
  }

  public void setVerticalCircumference(double verticalCircumference)
  {
    this.verticalCircumference = verticalCircumference;
    this.verticalRadius = verticalCircumference / TWO_PI;
  }
  
   public void setHorizontalCircumference(double horizontalCircumference)
  {
    this.horizontalCircumference = horizontalCircumference;
    this.horizontalRadius = horizontalCircumference / TWO_PI;
  }


  public double eval(double x, double y)
  {
    double gamma = (x / this.horizontalCircumference) * TWO_PI;
    double x_ = Math.sin(gamma)*this.horizontalRadius;
    double k_ = (1-Math.cos(gamma))*this.horizontalRadius;
    
    double theta = (y / this.verticalCircumference) * TWO_PI;
    double y_ = Math.sin(theta)*this.verticalRadius;
    double z_ = (1-Math.cos(theta))*this.verticalRadius;

    return super.eval(x_, y_, z_, k_);
  }
  
  public double eval(double x, double y, double z)
  {
     double gamma = (x / this.horizontalCircumference) * TWO_PI;
    double x_ = Math.sin(gamma)*this.horizontalRadius;
    double k_ = (1-Math.cos(gamma))*this.horizontalRadius;
    
    double theta = (y / this.verticalCircumference) * TWO_PI;
    double y_ = Math.sin(theta)*this.verticalRadius;
    double z_ = (1-Math.cos(theta))*this.verticalRadius;

    return super.eval(x_, y_, z_, k_ + z);
  }
}
