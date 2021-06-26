# Signed Distance Transform for images

The repo contains code files to perform signed distance transformation(SDT) on images using CPU and GPU. The file also contains code to compare CPU vs GPU times and Mean Squared Error(MSE).

## Features
1) Calculates edhe pixels on CPU as the task in serial by nature. (Could have broken images into tiles and calculate edge pixels for ech tile parallely to improve runtime.)
2) Uses shared memory tiling on edge_pixels inside GPU kernel.
