#pragma once

#ifndef _DT_GPU_H_
#define _DT_GPU_H_

void computeDT_GPU(std::vector<std::vector<Point*> > shapePoints, std::vector<float*> shapeBounds, std::vector<std::vector<int> > triangles);

#endif