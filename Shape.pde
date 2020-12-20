abstract class Shape
{
  float x;
  float y;
  Shape(float x,float y)
  {
    this.x = x;
    this.y = y;
  }
}



class Rectangle extends Shape
{
  float rectWidth;
  float rectHeight;
  Rectangle(float x, float y, float rectWidth, float rectHeight)
  {
    super(x, y);
    this.rectWidth = rectWidth;
    this.rectHeight = rectHeight;
  }

  boolean doesOverlap(Rectangle other)
  {
    return !(
      this.x + this.rectWidth < other.x || 
      other.x+ other.rectWidth < this.x || 
      this.y + this.rectHeight < other.y ||
      other.y + other.rectHeight < this.y);
  }

  <T extends Mapable> boolean contains(T element)
  {
    float elementX = element.getX();   
    float elementY = element.getY();    

    return (
      elementX >= this.x && 
      elementX < (this.x+this.rectWidth) &&
      elementY >= this.y && 
      elementY < (this.y+this.rectHeight));
  }
  
  void show()
  {
    rect(this.x, this.y, this.rectWidth, this.rectHeight);
  }
}
