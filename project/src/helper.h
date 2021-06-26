#pragma once

#include <vector>

using namespace std;

struct Point {
  double x, y;

  Point() : x(0.0),y(0.0){};
  Point(double x, double y) : x(x), y(y) {};
  
  inline bool operator==(const Point& p){
    return x==p.x && y==p.y;
  }
};

struct Triangle{
  Point points[3];
  bool is_valid;

  Triangle(){};
  
  Triangle(Point a, Point b, Point c)
  {
      points[0] = a;
      points[1] = b;
      points[2] = c;
  }
};

int distance(Point &A, Point &B);

int np2(int n);

int dist(const Point &a, const Point &b);

vector<Point> translate(float minX, float minY,vector<Point*> &dt_points);

vector<int> drawVoronoiDiagram(vector<Point> &seeds, int rows, int cols);

vector<int> delete_triangles(vector<Point> &owner_points, vector<int> DT, vector<int> svgPathLength);

vector<int> getDelaunayTriangles(vector<Point> &seeds,vector<int> &owner, int rows, int cols);
