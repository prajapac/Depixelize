Tested on:
<br>
OS: Windows 10 64-bit
<br>
IDE: Processing 3.5.4 + VSCode
<br>
GPU: Intel HD Graphics 5500 128MB
<br>
CPU: i5-5300U @ 2.30GHz
<br>
RAM: 8GB

Setup:
- Install Processing 3 on your machine

Running the Program:
- Open Depixelize.pde in the Depixelize folder

- Press the space key to cycle through the different stages in the algorithm:
    1) Frame 1: Pixel art rendered at its original resolution (very tiny)
    2) Frame 2: Procesing's scale to full screen (very blurry)
    3) Frame 3: Pixel Scaling to full screen by looping through all pixels and drawing rectangles
    4) Frame 4: Fully connected similarity graph of all pixels
    5) Frame 5: Similarity graph with all edges between pixels with dissimilar edges cut off
    6) Frame 6: Similarity graph with crossings color-coded, blue -> part of a continously shaded region, so can be removed safely,
                red -> ambiguous crossings since both edges are different colors, so requires some heuristics to determine which edge
                to remove.
    7) Frame 7: Similarity graph with blue crossings removed
    8) Frame 8: Similarity graph with red crossings resolved and removed
    9) Frame 9: Dual/Voronoi Diagram generated from similarity graph which has the desired properties

- Press keys 1-9 to (reset and) change the pixel art to apply the algorithm on

Frame 1:
<br>
![Boo_Frame_1](Screenshots/Boo_0.png)

Frame 2:
<br>
![Boo_Frame_2](Screenshots/Boo_1.png)

Frame 3:
<br>
![Boo_Frame_3](Screenshots/Boo_2.png)

Frame 4:
<br>
![Boo_Frame_4](Screenshots/Boo_3.png)

Frame 5:
<br>
![Boo_Frame_5](Screenshots/Boo_4.png)

Frame 6:
<br>
![Boo_Frame_6](Screenshots/Boo_5.png)

Frame 7:
<br>
![Boo_Frame_7](Screenshots/Boo_6.png)

Frame 8:
<br>
![Boo_Frame_8](Screenshots/Boo_7.png)

Frame 9:
<br>
![Boo_Frame_9](Screenshots/Boo_8.png)
