import java.lang.*; 

class CylindricalNoiseField extends OpenSimplexNoise
{
  double circumference;
  double radius;

  private CylindricalNoiseField()
  {
  }


  public CylindricalNoiseField(double circumference) 
  {
    super();
    this.setCircumference(circumference);
  }


  public CylindricalNoiseField(long seed, double circumference)
  {
    super(seed);
    this.setCircumference(circumference);
  }


  public CylindricalNoiseField(short[] perm, double circumference)
  {
    super(perm);
    this.setCircumference(circumference);
  }

  public void setCircumference(double circumference)
  {
    this.circumference = circumference;
    this.radius = circumference / TWO_PI;
  }


  public double eval(double x, double y)
  {
    double theta = (y / this.circumference) * TWO_PI;
    double y_ = Math.sin(theta)*this.radius;
    double z_ = (1-Math.cos(theta))*this.radius;

    return super.eval(x, y_, z_);
  }
  
  public double eval(double x, double y, double z)
  {
    double theta = (y / this.circumference) * TWO_PI;
    double y_ = Math.sin(theta)*this.radius;
    double z_ = (1-Math.cos(theta))*this.radius;

    return super.eval(x, y_, z_, z);
  }
}
