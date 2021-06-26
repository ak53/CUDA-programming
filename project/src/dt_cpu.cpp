#include <cstddef>  
#include <assert.h>
#include <cmath>
#include <vector>
#include <unordered_set>
#include <unordered_map>
#include<iostream>
#include <fstream>
using std::ofstream;

#include "helper.h"

using namespace std;

unordered_map<string,int> m; //TRIANGLE INDEX ARE 0-INDEXED


int distance(Point &A, Point &B){
  int dx = A.x-B.x;
  int dy = A.y-B.y;
  return (dx*dx + dy*dy);
}

int np2(int n){
  int p = 1;
  if (n && !(n & (n - 1)))
    return n;
  while (p < n)
      p <<= 1;
  return p;
}

vector<Point> translate(float minX, float minY,vector<Point*> &dt_points){
  vector<Point> mapped_points;
  for (int i = 0; i < dt_points.size(); ++i){
    mapped_points.push_back(Point(floor(dt_points[i]->x-minX+1), ceil(dt_points[i]->y-minY+1))); //CONFIRM X==C??
  }
  return mapped_points;
}

vector<int> drawVoronoiDiagram(vector<Point> &seeds, int rows, int cols){
  vector<int> owner(rows*cols,-1);
  // printf("%d %d\n",rows,cols );
  for (int i=0;i<seeds.size();i++){
    Point p = seeds[i];
    int od_cord = p.y*cols+p.x; 
    // printf("%f %f\n",p.y,p.x);
    owner[od_cord]=i; 
  }
  int step = np2(min(rows,cols))/2;
  const int dc[8] = {0,0,1,-1,1,1,-1,-1}; 
  const int dr[8] = {1,-1,0,0,1,-1,1,-1}; 
  while (step>=1){
    for (int r=0;r<rows;r++){
      for (int c=0;c<cols;c++){
        Point A = Point(c,r);  
        int od_cord_A = r*cols+c;
        for (int k=0;k<8;k++){
          int C = c+dc[k]*step;
          int R = r+dr[k]*step;
          int od_cord_B = R*cols+C;
          if (C>=0 && C<cols && R>=0 && R<rows && owner[od_cord_B]!=-1){
            int owner_B_index = owner[od_cord_B];
            int owner_A_index = owner[od_cord_A]; 

            if (owner_A_index==-1 ||
            distance(seeds[owner_B_index],A)<=distance(seeds[owner_A_index],A))
              owner[od_cord_A] = owner[od_cord_B];
          }
        }
      }
    }
    step/=2;
  }

  ofstream outdata; // outdata is like cin
  outdata.open("cpu.txt"); // opens the file
  if( !outdata ) { // file couldn't be opened
    std::cerr << "Error: file could not be opened" << endl;
    exit(1);
  }
  else{
    outdata << "[";
    for (int i = 0; i < rows; ++i){
      outdata << "[";
      for (int j = 0; j < cols; ++j)
        outdata << owner[i*cols+j] <<",";
      outdata << "],";
    }
    outdata << "]\n";
    outdata.close();
  }

  return owner;
}

bool insertToMap(int inds[3],int ptr){
  int p1 = inds[0];
  int p2 = inds[1];
  int p3 = inds[2];
  string edge=(to_string(p1)+","+to_string(p2));
  if (m.count(edge)>0){
    int tri1 = m[edge];
    edge=(to_string(p2)+","+to_string(p3));
    if (m.count(edge)>0){
      int tri2 = m[edge];
      if (tri1==tri2) return false;
      else m[to_string(p3)+","+to_string(p2)] = ptr;
    }else{
      m[to_string(p2)+","+to_string(p3)] = ptr;
    }
    m[to_string(p2)+","+to_string(p1)] = ptr;
    if (m.count(to_string(p1)+","+to_string(p3))>0)
      m[to_string(p3)+","+to_string(p1)] = ptr;
    else m[to_string(p1)+","+to_string(p3)] = ptr;
    return true;
  }else{
    m[to_string(p1)+","+to_string(p2)] = ptr;
    m[to_string(p2)+","+to_string(p3)] = ptr;
    m[to_string(p3)+","+to_string(p1)] = ptr;
    return true;
  }
}

vector<int> getDelaunayTriangles(
  vector<Point> &seeds,vector<int> &owner, int rows, int cols){
  vector<int> triangle_points;
  int ptr=0;
  const int dc[3] = {1,0,1};
  const int dr[3] = {0,1,1};
  for(int r=0; r < rows - 1; r++){
    for(int c=0; c<cols -1 ; c++){
      Point now_point(c, r);
      unordered_set<int> colors;
      colors.insert(owner[r*cols+c]);
      for (int k=0;k<3;k++){
        int C = c+dc[k];
        int R = r+dr[k];
        colors.insert(owner[R*cols+C]);
      }
      if(colors.size() == 3){
        int indexes[3];
        int p = 0;
        for(int index: colors){
          indexes[p] = index;
          p++;
        }
        if (insertToMap(indexes,ptr)){
          triangle_points.push_back(indexes[0]);
          triangle_points.push_back(indexes[1]);
          triangle_points.push_back(indexes[2]);
          ptr++;
        }
      }
      else if(colors.size() == 4){
        int indexes1[3] = {owner[r*cols+c],owner[r*cols+(c+1)],owner[(r+1)*cols+c]};
        if (insertToMap(indexes1,ptr)){
          triangle_points.push_back(indexes1[0]);
          triangle_points.push_back(indexes1[1]);
          triangle_points.push_back(indexes1[2]);
          ptr++;
        }
        int indexes2[3] = {owner[r*cols+(c+1)],owner[(r+1)*cols+c],owner[(r+1)*cols+(c+1)]};
        if (insertToMap(indexes2,ptr)){
          triangle_points.push_back(indexes2[0]);
          triangle_points.push_back(indexes2[1]);
          triangle_points.push_back(indexes2[2]);
          ptr++;
        }        
      }
    }
  }
  return triangle_points;
}

void mark_triangle_if_invalid(vector<Point> &owner_points,vector<int> &DT,int flag, Point& p1, Point& p4, Point& vec1,int triangle_pointer){
  int ptr = 3*triangle_pointer;
  while (p1==owner_points[DT[ptr]] || p4==owner_points[DT[ptr]])
    ptr++; 
  Point p = owner_points[DT[ptr]];
  Point vec2 = Point(p.x-p1.x,p.y-p1.y);
  int cross_product = vec1.x*vec2.y - vec1.y*vec2.x;
  // printf("%d\n", cross_product);
  if (flag==1 && cross_product<0 || flag==0 && cross_product>0){
    DT[3*triangle_pointer] = -1;
    DT[3*triangle_pointer+1] = -1;
    DT[3*triangle_pointer+2] = -1;
  }

}

int cross_product(Point a,Point b,Point c){
  Point l1 = Point(b.x-a.x,b.y-a.y);
  Point l2 = Point(c.x-b.x,c.y-b.y);
  int p = l1.x*l2.y - l1.y*l2.x;
}

bool find_intersect(Point p1,Point p2, Point p3, Point p4){
  int cp1 = cross_product(p4,p2,p3);
  int cp2 = cross_product(p2,p3,p1);
  int cp3 = cross_product(p3,p1,p4);
  int cp4 = cross_product(p1,p4,p2);
  if (cp1>0 && cp2>0 && cp3>0 && cp4>0 || cp1<0 && cp2<0 && cp3<0 && cp4<0) return true;
  else return false;
}

vector<int> delete_triangles(vector<Point> &owner_points, vector<int> DT, vector<int> svgPathLength){
  int n_tri = DT.size()/3;
  vector<int> innerTriangles;
  for (int i = 0; i < n_tri; ++i){
    float mean_x = (owner_points[DT[3*i]].x + owner_points[DT[3*i+1]].x + owner_points[DT[3*i+2]].x)/3;
    float mean_y = (owner_points[DT[3*i]].y + owner_points[DT[3*i+1]].y + owner_points[DT[3*i+2]].y)/3;
    int counter = 0;
    for (int j = 1; j<svgPathLength.size(); ++j){
      int pathPoints = svgPathLength[j]-svgPathLength[j-1];
      for(int k = svgPathLength[j-1]; k<svgPathLength[j]; ++k){
        Point a = owner_points[k%pathPoints];
        Point b = owner_points[(k+1)%pathPoints];
        Point m = Point(mean_x,mean_y);
        Point o = Point(0,0);
        if (find_intersect(a,b,o,m))
          ++counter;
      }
    }
    if (counter%2 == 1){
      innerTriangles.push_back(DT[3*i]);
      innerTriangles.push_back(DT[3*i+1]);
      innerTriangles.push_back(DT[3*i+2]);
    }
  }
  return innerTriangles;
}