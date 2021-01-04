class QuadTree <T extends Mapable>
{
  Rectangle area;
  ArrayList<T> elements;
  int maxElements;
  static final int defaultMaxElements = 4;
  QuadTree northWestQuadrant;
  QuadTree northEastQuadrant;
  QuadTree southWestQuadrant;
  QuadTree southEastQuadrant;
  boolean isDivided;
  
  QuadTree()
  {
    this.initQuadrants();
    this.initArea(new Rectangle(0, 0, width, height));
    this.initList(QuadTree.defaultMaxElements);
  }

  QuadTree(PGraphics canvas)
  {
    this.initQuadrants();
    this.initArea(new Rectangle(0, 0, canvas.width, canvas.height));
    this.initList(QuadTree.defaultMaxElements);
  }

  QuadTree(Rectangle area)
  {
    this.initQuadrants();
    this.initArea(area);
    this.initList(QuadTree.defaultMaxElements);
  }

  QuadTree(int maxElements)
  {
    this.initQuadrants();
    this.initArea(new Rectangle(0, 0, width, height));
    this.initList(maxElements);
  }

  QuadTree(Rectangle area, int maxElements)
  {
    this.initQuadrants();
    this.initArea(area);
    this.initList(maxElements);
  }

  private void initQuadrants()
  {
    this.northWestQuadrant = null;
    this.northEastQuadrant = null;
    this.southWestQuadrant = null;
    this.southEastQuadrant = null;

    this.isDivided = false;
  }

  private void initArea(Rectangle area)
  {
    this.area = area;
  }

  private void initList(int maxElements)
  {
    this.elements = new ArrayList<T>();
    this.maxElements = maxElements;
  }

  private void divide()
  {
    Rectangle northWestArea = new Rectangle(
      this.area.x, 
      this.area.y, 
      this.area.rectWidth/2., 
      this.area.rectHeight/2.);
    this.northWestQuadrant = new QuadTree(northWestArea, this.maxElements);

    Rectangle northEastArea = new Rectangle(
      this.area.x + this.area.rectWidth/2., 
      this.area.y, 
      this.area.rectWidth/2., 
      this.area.rectHeight/2.);    
    this.northEastQuadrant = new QuadTree(northEastArea, this.maxElements);

    Rectangle southWestArea = new Rectangle(
      this.area.x, 
      this.area.y + this.area.rectHeight/2., 
      this.area.rectWidth/2., 
      this.area.rectHeight/2.); 
    this.southWestQuadrant = new QuadTree(southWestArea, this.maxElements);

    Rectangle southEastArea = new Rectangle(
      this.area.x + this.area.rectWidth/2., 
      this.area.y + this.area.rectHeight/2., 
      this.area.rectWidth/2., 
      this.area.rectHeight/2.); 
    this.southEastQuadrant = new QuadTree(southEastArea, this.maxElements);
    this.isDivided = true;
  }


  void insert (T[] elements)
  {
    for (T element : elements)
    {
      this.insert(element);
    }
  }

  void insert (T element)
  {
    if (this.area.contains(element))
    {
      if (!this.isFull())
      {
        this.elements.add(element);
      } else
      {
        if (!this.isDivided)
        {
          this.divide();
        }
        this.northWestQuadrant.insert(element);
        this.northEastQuadrant.insert(element);
        this.southWestQuadrant.insert(element);
        this.southEastQuadrant.insert(element);
      }
    }
  }

  ArrayList<T> queryArea(Rectangle area)
  {
    if (this.area.doesOverlap(area))
    {
      ArrayList<T> ret = new ArrayList<T>();
      for (T element : this.elements)
      {
        if (area.contains(element))
        {
          ret.add(element);
        }
      }
      if (this.isDivided)
      {
        ArrayList<T> subRet = this.northWestQuadrant.queryArea(area);
        if (subRet != null)
        {
          ret.addAll(subRet);
        }
        subRet = this.northEastQuadrant.queryArea(area);
        if (subRet != null)
        {
          ret.addAll(subRet);
        }
        subRet = this.southWestQuadrant.queryArea(area);
        if (subRet != null)
        {
          ret.addAll(subRet);
        }
        subRet = this.southEastQuadrant.queryArea(area);
        if (subRet != null)
        {
          ret.addAll(subRet);
        }
      }

      return ret;
    } else
    {
      return null;
    }
  }

  void show()
  {
    this.area.show();
    if (this.isDivided)
    {
      this.northWestQuadrant.show();
      this.northEastQuadrant.show();
      this.southWestQuadrant.show();
      this.southEastQuadrant.show();
    }
  }

  private boolean isFull()
  {
    return !(this.elements.size()<this.maxElements);
  }
}


interface Mapable {
  float getX();
  float getY();
}
