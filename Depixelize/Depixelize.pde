PImage img;
Graph similarityGraph;
color[][] imagePixels;
int currState = 0;
boolean generateGraph = false;
boolean cutOffDissimilar = false;
boolean resolveBlueCrossings = false;
boolean resolveRedCrossings = false;
boolean generateVoronoiDiagram = false;
boolean curveIsALoop = false;

// Draw_State for application
final int ORIGINAL_SCALE_STATE = 0;
final int PROCESSING_SCALE_STATE = 1;
final int INITIAL_DEPIXELIZE_STATE = 2;
final int FULLY_CONNECTED_STATE = 3;
final int CUT_OFF_DISSIMILAR = 4;
final int COLOR_CODE_CROSSINGS = 5;
final int RESOLVE_BLUE_CROSSINGS = 6;
final int RESOLVE_RED_CROSSINGS = 7;
final int GENERATE_VORONOI_DIAGRAM = 8;
final int NUM_DRAW_STATES = 9;

// Dissimilarity RGB Constants
final int DIFFERENCE_Y = 48;
final int DIFFERENCE_U = 7;
final int DIFFERENCE_V = 6;

// Heuristic case 3 for resolving red crossings
final int ISLAND_WEIGHT = 5;

// Voronoi Diagram
ArrayList<VoronoiCell> voronoiDiagram;

void setup() {
	size(1024, 1024);
    surface.setResizable(true);
	imageMode(CENTER);

    // Default Image
	img = loadImage("Images/smw_boo_input.png");
	loadImagePixels();
}

void draw() {
	background(255, 255, 255);
	
	switch (currState) {
		case ORIGINAL_SCALE_STATE:
			image(img, width/2.0, height/2.0);
			break;
		case PROCESSING_SCALE_STATE:
			image(img, width/2.0, height/2.0, width, height);
			break;
		case INITIAL_DEPIXELIZE_STATE:
			drawImagePixels();
			break;
        case FULLY_CONNECTED_STATE:
            drawImagePixelsTransparent();
            if (generateGraph) {
                generateGraph();
                generateGraph = false;
            }
            drawGraph();
            break;
        case CUT_OFF_DISSIMILAR:
            drawImagePixelsTransparent();
            if (cutOffDissimilar) {
                cutOffDissimilar();
                cutOffDissimilar = false;
            }
            drawGraph();
            break;
        case COLOR_CODE_CROSSINGS:
            drawImagePixelsTransparent();
            drawGraphColorCodedCrossings();
            break;
        case RESOLVE_BLUE_CROSSINGS:
            drawImagePixelsTransparent();
            if (resolveBlueCrossings) {
                resolveBlueCrossings();
                resolveBlueCrossings = false;
            }
            drawGraphColorCodedCrossings();
            break;
        case RESOLVE_RED_CROSSINGS:
            drawImagePixelsTransparent();
            if (resolveRedCrossings) {
                resolveRedCrossings();
                resolveRedCrossings = false;
            }
            drawGraphColorCodedCrossings();
            break;
        case GENERATE_VORONOI_DIAGRAM:
            if (generateVoronoiDiagram) {
                generateVoronoiDiagram();
                generateVoronoiDiagram = false;
            }
            drawVoronoiDiagram();
            break;
	}
}

void loadImagePixels() {
	loadPixels();
	img.loadPixels();
	
    imagePixels = new color[img.width][img.height];

	for (int y = 0; y < img.height; y++) {
		for (int x = 0; x < img.width; x++) {
			int imageLoc = x + y*img.width;
			int displayLoc = x + y*width;

			float r = red(img.pixels[imageLoc]);
			float g = green(img.pixels[imageLoc]);
			float b = blue(img.pixels[imageLoc]);
			
			color currPixelColor = color(r, g, b);

			imagePixels[x][y] = currPixelColor;
		}
	}
}

void drawImagePixels() {
    noStroke();
	float rectWidth = width/(imagePixels.length * 1.0);
	float rectHeight = height/(imagePixels[0].length * 1.0);
	for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
			fill(imagePixels[x][y]);
			rect(x*rectWidth,y*rectHeight,rectWidth,rectHeight);
		}	
	}
}

void drawImagePixelsTransparent() {
    int alpha = 128; // 50% transparency
    noStroke();
	float rectWidth = width/(imagePixels.length * 1.0);
	float rectHeight = height/(imagePixels[0].length * 1.0);
	for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
			fill(red(imagePixels[x][y]), green(imagePixels[x][y]), blue(imagePixels[x][y]), alpha);
			rect(x*rectWidth,y*rectHeight,rectWidth,rectHeight);
		}	
	}
}

void generateGraph() {
    similarityGraph = new Graph(((imagePixels.length)*(imagePixels[0].length)));

    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) { // Last Column: |
                    similarityGraph.addEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                } else if (y == imagePixels[0].length-1) { // Last Row: -
                    similarityGraph.addEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))));
                } else {
                    similarityGraph.addEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1)))); // -
                    similarityGraph.addEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))); // |
                    similarityGraph.addEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1)))); // \
                    similarityGraph.addEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))); // /
                }
            }
		}
	}
}

void cutOffDissimilar() {
    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) { // Last Column: |
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) {
                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x][y+1]);
                        float G2 = green(imagePixels[x][y+1]);
                        float B2 = blue(imagePixels[x][y+1]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                        }
                    }
                } else if (y == imagePixels[0].length-1) { // Last Row: -
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) {
                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x+1][y]);
                        float G2 = green(imagePixels[x+1][y]);
                        float B2 = blue(imagePixels[x+1][y]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))));
                        }
                    }
                }else {
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) { // -
                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x+1][y]);
                        float G2 = green(imagePixels[x+1][y]);
                        float B2 = blue(imagePixels[x+1][y]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))));
                        }
                    }
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // |
                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x][y+1]);
                        float G2 = green(imagePixels[x][y+1]);
                        float B2 = blue(imagePixels[x][y+1]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                        }
                    }
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) { // \
                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x+1][y+1]);
                        float G2 = green(imagePixels[x+1][y+1]);
                        float B2 = blue(imagePixels[x+1][y+1]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))));
                        }
                    }
                    if(similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // /
                        float R1 = red(imagePixels[x+1][y]);
                        float G1 = green(imagePixels[x+1][y]);
                        float B1 = blue(imagePixels[x+1][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x][y+1]);
                        float G2 = green(imagePixels[x][y+1]);
                        float B2 = blue(imagePixels[x][y+1]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            similarityGraph.removeEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                        }
                    }
                }
            }
		}
	}
}

void drawGraph() {
    stroke(0,0,0);
    strokeWeight(3);
    float lineWidth = width/(imagePixels.length * 1.0);
	float lineHeight = height/(imagePixels[0].length * 1.0);
    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) {  // Last Column: |
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                } else if (y == imagePixels[0].length-1) {  // Last Row: -
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                }else {
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) { // -
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // |
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) { // \
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point(((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                    if(similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // /
                        line(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                }
            }
		}
	}
}

void drawGraphColorCodedCrossings() {
    stroke(0,0,0);
    strokeWeight(3);
    float lineWidth = width/(imagePixels.length * 1.0);
	float lineHeight = height/(imagePixels[0].length * 1.0);
    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) {  // Last Column: |
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                } else if (y == imagePixels[0].length-1) {  // Last Row: -
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                }else {
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+y+(y*(imagePixels.length-1))))) { // -
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                    if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // |
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(10);
                        point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                    }
                    if ((similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) && (similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))))) { // Crossing
                        boolean differentColors = false;

                        float R1 = red(imagePixels[x][y]);
                        float G1 = green(imagePixels[x][y]);
                        float B1 = blue(imagePixels[x][y]);

                        float Y1 = YfromRGB(R1, G1, B1);
                        float U1 = UfromRGB(R1, G1, B1);
                        float V1 = VfromRGB(R1, G1, B1);

                        float R2 = red(imagePixels[x][y+1]);
                        float G2 = green(imagePixels[x][y+1]);
                        float B2 = blue(imagePixels[x][y+1]);

                        float Y2 = YfromRGB(R2, G2, B2);
                        float U2 = UfromRGB(R2, G2, B2);
                        float V2 = VfromRGB(R2, G2, B2);

                        float differenceY = abs(Y1 - Y2);
                        float differenceU = abs(U1 - U2);
                        float differenceV = abs(V1 - V2);

                        if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                            differentColors = true;
                        }

                        if (differentColors) {
                            stroke(255,0,0); // Red
                        } else {
                            stroke(0,0,255); // Blue
                        }
                        
                        // Draw Lines (Crossing)
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        line(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        
                        stroke(0,0,0);
                    } 
                    else { // Single Diagonal
                        if(similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) { // \
                            line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                            strokeWeight(10);
                            point((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                            point(((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                            strokeWeight(3);
                        }
                        if(similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) { // /
                            line(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                            strokeWeight(10);
                            point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                            point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                            strokeWeight(3);
                        }
                    }
                }
            }
		}
	}
}

void resolveBlueCrossings() {
    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 || y == imagePixels[0].length-1)) {
                if ((similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) && (similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))))) { // Crossing
                    boolean differentColors = false;

                    float R1 = red(imagePixels[x][y]);
                    float G1 = green(imagePixels[x][y]);
                    float B1 = blue(imagePixels[x][y]);

                    float Y1 = YfromRGB(R1, G1, B1);
                    float U1 = UfromRGB(R1, G1, B1);
                    float V1 = VfromRGB(R1, G1, B1);

                    float R2 = red(imagePixels[x][y+1]);
                    float G2 = green(imagePixels[x][y+1]);
                    float B2 = blue(imagePixels[x][y+1]);

                    float Y2 = YfromRGB(R2, G2, B2);
                    float U2 = UfromRGB(R2, G2, B2);
                    float V2 = VfromRGB(R2, G2, B2);

                    float differenceY = abs(Y1 - Y2);
                    float differenceU = abs(U1 - U2);
                    float differenceV = abs(V1 - V2);

                    if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                        differentColors = true;
                    }

                    if (!differentColors) {
                        similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))));
                        similarityGraph.removeEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                    }
                }
            }
		}
	}
}

void resolveRedCrossings() {
    int count = 0;
    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            if(!(x == imagePixels.length-1 || y == imagePixels[0].length-1)) {
                if ((similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) && (similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))))) { // Crossing
                    boolean differentColors = false;

                    float R1 = red(imagePixels[x][y]);
                    float G1 = green(imagePixels[x][y]);
                    float B1 = blue(imagePixels[x][y]);

                    float Y1 = YfromRGB(R1, G1, B1);
                    float U1 = UfromRGB(R1, G1, B1);
                    float V1 = VfromRGB(R1, G1, B1);

                    float R2 = red(imagePixels[x][y+1]);
                    float G2 = green(imagePixels[x][y+1]);
                    float B2 = blue(imagePixels[x][y+1]);

                    float Y2 = YfromRGB(R2, G2, B2);
                    float U2 = UfromRGB(R2, G2, B2);
                    float V2 = VfromRGB(R2, G2, B2);

                    float differenceY = abs(Y1 - Y2);
                    float differenceU = abs(U1 - U2);
                    float differenceV = abs(V1 - V2);

                    if (differenceY > DIFFERENCE_Y || differenceU > DIFFERENCE_U || differenceV > DIFFERENCE_V) {
                        differentColors = true;
                    }

                    if (differentColors) {
                        int weightDiagonal1 = 0; // \
                        int weightDiagonal2 = 0; // /

                        // Heuristic 1: Curves
                        int curveLengthDiagonal1 = 1 + measureCurveLength(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))), x+y+(y*(imagePixels.length-1))) + measureCurveLength(((x+1)+(y+1)+((y+1)*(imagePixels.length-1))), x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))));  // \

                        if (curveIsALoop) {
                            curveLengthDiagonal1 = round(curveLengthDiagonal1/2.0);
                            curveIsALoop = false;
                        }

                        int curveLengthDiagonal2 = 1 + measureCurveLength((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))), (x+1)+y+(y*(imagePixels.length-1))) + measureCurveLength((x+(y+1)+((y+1)*(imagePixels.length-1))), (x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))); // /

                        if (curveIsALoop) {
                            curveLengthDiagonal2 = round(curveLengthDiagonal2/2.0);
                            curveIsALoop = false;
                        }

                        if (curveLengthDiagonal1 > curveLengthDiagonal2) {
                            weightDiagonal1 += (curveLengthDiagonal1 - curveLengthDiagonal2);
                        }
                        else if (curveLengthDiagonal2 > curveLengthDiagonal1) {
                            weightDiagonal2 += (curveLengthDiagonal2 - curveLengthDiagonal1);
                        }

                        // Heuristic 2: Sparse Pixels
                        int diagonal1ConnectedComponentSize = 0;
                        int diagonal2ConnectedComponentSize = 0;

                        int topLeftX = max(0, (x-3));
                        int topLeftY = max(0, (y-3));
                        int bottomRightX = min((x+4), imagePixels.length-1);
                        int bottomRightY = min((y+4), imagePixels[0].length-1);
                        
                        int width = (bottomRightX - topLeftX) + 1;
                        int height = (bottomRightY - topLeftY) + 1;

                        ArrayList<IntList> componentLists = similarityGraph.sparsePixelsComponentCount(topLeftX, topLeftY, width, height);
                        
                        for (int i = 0; i < componentLists.size(); i++) {
                            if (componentLists.get(i).hasValue(x+y+(y*(imagePixels.length-1)))) {
                                diagonal1ConnectedComponentSize = componentLists.get(i).size(); // \
                            } else if (componentLists.get(i).hasValue((x+1)+y+(y*(imagePixels.length-1)))) {
                                diagonal2ConnectedComponentSize = componentLists.get(i).size(); // /
                            }
                        }

                        if (diagonal1ConnectedComponentSize < diagonal2ConnectedComponentSize) {
                            weightDiagonal1 += (diagonal2ConnectedComponentSize - diagonal1ConnectedComponentSize);
                        }
                        else if (diagonal2ConnectedComponentSize < diagonal1ConnectedComponentSize) {
                            weightDiagonal2 += (diagonal1ConnectedComponentSize - diagonal2ConnectedComponentSize);
                        }

                        // Heuristic 3: Islands
                        boolean diagonal1IsIsland = islandCheck(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1)))) || islandCheck(((x+1)+(y+1)+((y+1)*(imagePixels.length-1))), x+y+(y*(imagePixels.length-1))); // \
                        boolean diagonal2IsIsland = islandCheck((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))) || islandCheck((x+(y+1)+((y+1)*(imagePixels.length-1))), (x+1)+y+(y*(imagePixels.length-1))); // /

                        if (diagonal1IsIsland && !diagonal2IsIsland) {
                            weightDiagonal1 += ISLAND_WEIGHT;
                        } else if (!diagonal1IsIsland && diagonal2IsIsland) {
                            weightDiagonal2 += ISLAND_WEIGHT;
                        }

                        if (weightDiagonal1 > weightDiagonal2) {
                            similarityGraph.removeEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))); // /
                        } else if (weightDiagonal2 > weightDiagonal1) {
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1)))); // \
                        } else if (weightDiagonal1 == weightDiagonal2) {
                            similarityGraph.removeEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1)))); // /
                            similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1)))); // \
                        }                
                    }
                }
                // Resolve single cross edges surrounded by a box of connected edges
                else if (similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), (x+1)+y+(y*(imagePixels.length-1))) &&
                         similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+1)+(y+1)+((y+1)*(imagePixels.length-1))) &&
                         similarityGraph.isEdge((x+1)+(y+1)+((y+1)*(imagePixels.length-1)), x+(y+1)+((y+1)*(imagePixels.length-1))) &&
                         similarityGraph.isEdge(x+(y+1)+((y+1)*(imagePixels.length-1)), x+y+(y*(imagePixels.length-1)))) {
                             if (similarityGraph.isEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))))) {
                                 similarityGraph.removeEdge(x+y+(y*(imagePixels.length-1)), ((x+1)+(y+1)+((y+1)*(imagePixels.length-1))));
                             }
                             else if (similarityGraph.isEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))))) {
                                 similarityGraph.removeEdge((x+1)+y+(y*(imagePixels.length-1)), (x+(y+1)+((y+1)*(imagePixels.length-1))));
                             }
                }
            }
		}
	}
}

int measureCurveLength(int pixel1, int pixel2, int loopPixel) { // pixel1 == pixel to check valence for, pixel2 so we avoid recounting it, loopPixel to detect curve being a loop
    int valence = 1;
    int extraEdgeConnections = 0;

    int topLeftPixel = -1;
    int topPixel = -1;
    int topRightPixel = -1;
    int leftPixel = -1;
    int rightPixel = -1;
    int bottomLeftPixel = -1;
    int bottomPixel = -1;
    int bottomRightPixel = -1;

    int newPixel = -1;

    if (pixel1 == 0) { // top left corner
        rightPixel = pixel1 + 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
    }
    else if (pixel1 == (imagePixels.length-1)) { // top right corner
        leftPixel = pixel1 - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
    }
    else if (pixel1 == (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom left corner
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 == (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom right corner
        topPixel = pixel1 - (imagePixels.length);
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        leftPixel = pixel1 - 1;
    }
    else if (pixel1 > 0 && pixel1 < (imagePixels.length-1)) { // top row
        leftPixel = pixel1 - 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 > (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1)) && pixel1 < (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom row
        leftPixel = pixel1 - 1;
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 % (imagePixels.length) == 0) { // left column
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
        bottomPixel = pixel1 + (imagePixels.length);
    }
    else if (((pixel1 + 1) % (imagePixels.length)) == 0) { // right column
        topPixel = pixel1 - (imagePixels.length);
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        leftPixel = pixel1 - 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
    }
    else { // anywhere else
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        leftPixel = pixel1 - 1;
        rightPixel = pixel1 + 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
    }

    // Top-left pixel
    if (topLeftPixel != -1 && topLeftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topLeftPixel)) {
            newPixel = topLeftPixel;
            valence++;
        }
    }
    // Top pixel
    if (topPixel != -1 && topPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topPixel)) {
            newPixel = topPixel;
            valence++;
        }
    }
    // Top-right pixel
    if (topRightPixel != -1 && topRightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topRightPixel)) {
            newPixel = topRightPixel;
            valence++;
        }
    }
    // Left pixel
    if (leftPixel != -1 && leftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, leftPixel)) {
            newPixel = leftPixel;
            valence++;
        }
    }
    // Right pixel
    if (rightPixel != -1 && rightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, rightPixel)) {
            newPixel = rightPixel;
            valence++;
        }
    }
    // Bottom-left pixel
    if (bottomLeftPixel != -1 && bottomLeftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomLeftPixel)) {
            newPixel = bottomLeftPixel;
            valence++;
        }
    }
    // Bottom pixel
    if (bottomPixel != -1 && bottomPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomPixel)) {
            newPixel = bottomPixel;
            valence++;
        }
    }
    // Bottom-right pixel
    if (bottomRightPixel != -1 && bottomRightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomRightPixel)) {
            newPixel = bottomRightPixel;
            valence++;
        }
    }

    // if (valence == 1) {} // Done: Dead-End
    if (valence == 2) {
        if (newPixel != loopPixel) {
            extraEdgeConnections = 1 + measureCurveLength(newPixel, pixel1, loopPixel);
        } else {
            curveIsALoop = true;
        }
    }
    // if (valence >= 3) {} // Done: Junction

    return extraEdgeConnections;
}

boolean islandCheck(int pixel1, int pixel2) {
    boolean islandCheck = false;

    int valence = 1;

    int topLeftPixel = -1;
    int topPixel = -1;
    int topRightPixel = -1;
    int leftPixel = -1;
    int rightPixel = -1;
    int bottomLeftPixel = -1;
    int bottomPixel = -1;
    int bottomRightPixel = -1;

    int newPixel = -1;

    if (pixel1 == 0) { // top left corner
        rightPixel = pixel1 + 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
    }
    else if (pixel1 == (imagePixels.length-1)) { // top right corner
        leftPixel = pixel1 - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
    }
    else if (pixel1 == (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom left corner
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 == (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom right corner
        topPixel = pixel1 - (imagePixels.length);
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        leftPixel = pixel1 - 1;
    }
    else if (pixel1 > 0 && pixel1 < (imagePixels.length-1)) { // top row
        leftPixel = pixel1 - 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 > (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1)) && pixel1 < (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom row
        leftPixel = pixel1 - 1;
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
    }
    else if (pixel1 % (imagePixels.length) == 0) { // left column
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        rightPixel = pixel1 + 1;
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
        bottomPixel = pixel1 + (imagePixels.length);
    }
    else if (((pixel1 + 1) % (imagePixels.length)) == 0) { // right column
        topPixel = pixel1 - (imagePixels.length);
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        leftPixel = pixel1 - 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
    }
    else { // anywhere else
        topLeftPixel = pixel1 - (imagePixels.length) - 1;
        topPixel = pixel1 - (imagePixels.length);
        topRightPixel = pixel1 - (imagePixels.length) + 1;
        leftPixel = pixel1 - 1;
        rightPixel = pixel1 + 1;
        bottomLeftPixel = pixel1 + (imagePixels.length) - 1;
        bottomPixel = pixel1 + (imagePixels.length);
        bottomRightPixel = pixel1 + (imagePixels.length) + 1;
    }

    // Top-left pixel
    if (topLeftPixel != -1 && topLeftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topLeftPixel)) {
            newPixel = topLeftPixel;
            valence++;
        }
    }
    // Top pixel
    if (topPixel != -1 && topPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topPixel)) {
            newPixel = topPixel;
            valence++;
        }
    }
    // Top-right pixel
    if (topRightPixel != -1 && topRightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, topRightPixel)) {
            newPixel = topRightPixel;
            valence++;
        }
    }
    // Left pixel
    if (leftPixel != -1 && leftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, leftPixel)) {
            newPixel = leftPixel;
            valence++;
        }
    }
    // Right pixel
    if (rightPixel != -1 && rightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, rightPixel)) {
            newPixel = rightPixel;
            valence++;
        }
    }
    // Bottom-left pixel
    if (bottomLeftPixel != -1 && bottomLeftPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomLeftPixel)) {
            newPixel = bottomLeftPixel;
            valence++;
        }
    }
    // Bottom pixel
    if (bottomPixel != -1 && bottomPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomPixel)) {
            newPixel = bottomPixel;
            valence++;
        }
    }
    // Bottom-right pixel
    if (bottomRightPixel != -1 && bottomRightPixel != pixel2) {
        if (similarityGraph.isEdge(pixel1, bottomRightPixel)) {
            newPixel = bottomRightPixel;
            valence++;
        }
    }

    if (valence == 1) {
        islandCheck = true;
    }

    return islandCheck;
}

void generateVoronoiDiagram() {
    voronoiDiagram = new ArrayList<VoronoiCell>();

    stroke(0,0,0);
    strokeWeight(3);

    float lineWidth = width/(imagePixels.length * 1.0);
	float lineHeight = height/(imagePixels[0].length * 1.0);
    float halfLineWidth = lineWidth / 2.0;
	float halfLineHeight = lineHeight / 2.0;
    float quarterLineWidth = lineWidth / 4.0;
	float quarterLineHeight = lineHeight / 4.0;

    for (int y = 0; y < imagePixels[0].length; y++) {
		for (int x = 0; x < imagePixels.length; x++) {
            boolean checkTopLeftNode = false;
            boolean checkTopNode = false;
            boolean checkTopRightNode = false;
            boolean checkRightNode = false;
            boolean checkBottomRightNode = false;
            boolean checkBottomNode = false;
            boolean checkBottomLeftNode = false;
            boolean checkLeftNode = false;

            boolean edgeToTopLeftNodeExists = false;
            boolean edgeToTopNodeExists = false;
            boolean edgeToTopRightNodeExists = false;
            boolean edgeToRightNodeExists = false;
            boolean edgeToBottomRightNodeExists = false;
            boolean edgeToBottomNodeExists = false;
            boolean edgeToBottomLeftNodeExists = false;
            boolean edgeToLeftNodeExists = false;
            
            int currPixel = (x+y+(y*(imagePixels.length-1)));
            int topLeftPixel = ((x-1)+(y-1)+((y-1)*(imagePixels.length-1)));
            int topPixel = (x+(y-1)+((y-1)*(imagePixels.length-1)));
            int topRightPixel = ((x+1)+(y-1)+((y-1)*(imagePixels.length-1)));
            int leftPixel = ((x-1)+y+(y*(imagePixels.length-1)));
            int rightPixel = ((x+1)+y+(y*(imagePixels.length-1)));
            int bottomLeftPixel = ((x-1)+(y+1)+((y+1)*(imagePixels.length-1)));
            int bottomPixel = (x+(y+1)+((y+1)*(imagePixels.length-1)));
            int bottomRightPixel = ((x+1)+(y+1)+((y+1)*(imagePixels.length-1)));

            // Top-Left Corner Node
            if (x == 0 && y == 0) {
                checkRightNode = true;
                checkBottomRightNode = true;
                checkBottomNode = true;
            }
            // Top-Right Corner Node
            else if (x == imagePixels.length-1 && y == 0) {
                checkBottomNode = true;
                checkBottomLeftNode = true;
                checkLeftNode = true;
            }
            // Bottom-Left Corner Node
            else if (x == 0 && y == imagePixels[0].length-1) {
                checkTopNode = true;
                checkTopRightNode = true;
                checkRightNode = true;
            }
            // Bottom-Right Corner Node
            else if (x == imagePixels.length-1 && y == imagePixels[0].length-1) {
                checkLeftNode = true;
                checkTopLeftNode = true;
                checkTopNode = true;
            }
            // Top-Row Nodes
            else if (x > 0 && x < imagePixels.length-1 && y == 0) {
                checkRightNode = true;
                checkBottomRightNode = true;
                checkBottomNode = true;
                checkBottomLeftNode = true;
                checkLeftNode = true;
            }
            // Bottom-Row Nodes
            else if (x > 0 && x < imagePixels.length-1 && y == imagePixels[0].length-1) {
                checkLeftNode = true;
                checkTopLeftNode = true;
                checkTopNode = true;
                checkTopRightNode = true;
                checkRightNode = true;
            }
            // Left-Column Nodes
            else if (x == 0 && y > 0 && y < imagePixels[0].length) {
                checkTopNode = true;
                checkTopRightNode = true;
                checkRightNode = true;
                checkBottomRightNode = true;
                checkBottomNode = true;
            }
            // Right-Column Nodes
            else if (x == imagePixels.length-1 && y > 0 && y < imagePixels[0].length-1) {
                checkTopNode = true;
                checkTopLeftNode = true;
                checkLeftNode = true;
                checkBottomLeftNode = true;
                checkBottomNode = true;
            }
            // Every Other Node
            else {
                checkTopLeftNode = true;
                checkTopNode = true;
                checkTopRightNode = true;
                checkRightNode = true;
                checkBottomRightNode = true;
                checkBottomNode = true;
                checkBottomLeftNode = true;
                checkLeftNode = true;
            }

            if (checkTopLeftNode) {
                if(similarityGraph.isEdge(currPixel, topLeftPixel)) {
                    edgeToTopLeftNodeExists = true;
                }
            }
            if (checkTopNode) {
                if(similarityGraph.isEdge(currPixel, topPixel)) {
                    edgeToTopNodeExists = true;
                }   
            }
            if (checkTopRightNode) {
                if(similarityGraph.isEdge(currPixel, topRightPixel)) {
                    edgeToTopRightNodeExists = true;
                }
            }
            if (checkRightNode) {
                if(similarityGraph.isEdge(currPixel, rightPixel)) {
                    edgeToRightNodeExists = true;
                }
            }
            if (checkBottomRightNode) {
                if(similarityGraph.isEdge(currPixel, bottomRightPixel)) {
                    edgeToBottomRightNodeExists = true;
                }
            }
            if (checkBottomNode) {
                if(similarityGraph.isEdge(currPixel, bottomPixel)) {
                    edgeToBottomNodeExists = true;
                }
            }
            if (checkBottomLeftNode) {
                if(similarityGraph.isEdge(currPixel, bottomLeftPixel)) {
                    edgeToBottomLeftNodeExists = true;
                }
            }
            if (checkLeftNode) {
                if(similarityGraph.isEdge(currPixel, leftPixel)) {
                    edgeToLeftNodeExists = true;
                }
            }

            ArrayList<Point> vertices = new ArrayList<Point>();

            // Top-Left Edge and Top Edge
            if (edgeToTopLeftNodeExists && edgeToTopNodeExists) {
                Point bottomLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight+quarterLineHeight);
                vertices.add(bottomLeft);
            }
            // Top-Left Edge and Left Edge
            else if (edgeToTopLeftNodeExists && edgeToLeftNodeExists) {
                Point topRight = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight-quarterLineHeight);
                vertices.add(topRight);    
            }
            // Top-Left Edge
            else if (edgeToTopLeftNodeExists) {
                Point bottomLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight+quarterLineHeight);
                Point topRight = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight-quarterLineHeight);
                vertices.add(bottomLeft);
                vertices.add(topRight);    
            } else {
                Point topLeft;
                // Check Edge-Case:
                if (similarityGraph.isEdge(topPixel, leftPixel) && !(similarityGraph.isEdge(currPixel, topPixel) && similarityGraph.isEdge(currPixel, leftPixel))) {
                    topLeft = new Point((x*lineWidth)+(lineWidth/2)-quarterLineWidth, (y*lineHeight)+(lineHeight/2)-quarterLineHeight);
                } else {
                    topLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                }
                vertices.add(topLeft);
            }

            // Top-Right Edge and Top Edge
            if (edgeToTopRightNodeExists && edgeToTopNodeExists) {
                Point bottomRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight+quarterLineHeight);
                vertices.add(bottomRight); 
            }
            // Top-Right Edge and Right Edge
            else if (edgeToTopRightNodeExists && edgeToRightNodeExists) {
                Point topLeft = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight-quarterLineHeight);
                vertices.add(topLeft);
            }
            // Top-Right Edge
            else if (edgeToTopRightNodeExists) {
                Point topLeft = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight-quarterLineHeight);
                Point bottomRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight+quarterLineHeight);
                vertices.add(topLeft);
                vertices.add(bottomRight); 
            } else {
                Point topRight;
                // Check Edge-Case:
                if (similarityGraph.isEdge(topPixel, rightPixel) && !(similarityGraph.isEdge(currPixel, topPixel) && similarityGraph.isEdge(currPixel, rightPixel))) {
                    topRight = new Point((x*lineWidth)+(lineWidth/2)+quarterLineWidth, (y*lineHeight)+(lineHeight/2)-quarterLineHeight);
                } else {
                    topRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                }
                vertices.add(topRight);
            }

            // Bottom-Right Edge and Bottom Edge
            if (edgeToBottomRightNodeExists && edgeToBottomNodeExists) {
                Point topRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight-quarterLineHeight);
                vertices.add(topRight); 
            }
            // Bottom-Right Edge and Right Edge
            else if (edgeToBottomRightNodeExists && edgeToRightNodeExists) {
                Point bottomLeft = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight+quarterLineHeight);
                vertices.add(bottomLeft);    
            }
            // Bottom-Right Edge
            else if (edgeToBottomRightNodeExists) {
                Point topRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight-quarterLineHeight);
                Point bottomLeft = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight+quarterLineHeight);
                vertices.add(topRight);
                vertices.add(bottomLeft);    
            } else {
                Point bottomRight;
                // Check Edge-Case:
                if (similarityGraph.isEdge(bottomPixel, rightPixel) && !(similarityGraph.isEdge(currPixel, bottomPixel) && similarityGraph.isEdge(currPixel, rightPixel))) {
                    bottomRight = new Point((x*lineWidth)+(lineWidth/2)+quarterLineWidth, (y*lineHeight)+(lineHeight/2)+quarterLineHeight);
                } else {
                    bottomRight = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                }
                vertices.add(bottomRight);
            }

            // Bottom-Left Edge and Bottom Edge
            if (edgeToBottomLeftNodeExists && edgeToBottomNodeExists) {
                Point topLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight-quarterLineHeight);
                vertices.add(topLeft);      
            }
            // Bottom-Left Edge and Left Edge
            else if (edgeToBottomLeftNodeExists && edgeToLeftNodeExists) {
                Point bottomRight = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight+quarterLineHeight);
                vertices.add(bottomRight);
            }
            // Bottom-Left Edge
            else if (edgeToBottomLeftNodeExists) {
                Point bottomRight = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth+quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight+quarterLineHeight);
                Point topLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth-quarterLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight-quarterLineHeight);
                vertices.add(bottomRight);
                vertices.add(topLeft);      
            } else {
                Point bottomLeft;
                // Check Edge-Case:
                if (similarityGraph.isEdge(bottomPixel, leftPixel) && !(similarityGraph.isEdge(currPixel, bottomPixel) && similarityGraph.isEdge(currPixel, leftPixel))) {
                    bottomLeft = new Point((x*lineWidth)+(lineWidth/2)-quarterLineWidth, (y*lineHeight)+(lineHeight/2)+quarterLineHeight);
                } else {
                    bottomLeft = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                }
                vertices.add(bottomLeft);
            }

            // Top Edge
            if (edgeToTopNodeExists) {
                Point left = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                Point right = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                vertices.add(left);
                vertices.add(right);
            } else {
                Point top = new Point((x*lineWidth)+(lineWidth/2), (y*lineHeight)+(lineHeight/2)-quarterLineHeight);
                vertices.add(top);
            }

            // Right Edge
            if (edgeToRightNodeExists) {
                Point top = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                Point bottom = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                vertices.add(top);
                vertices.add(bottom);   
            } else {
                Point right = new Point((x*lineWidth)+(lineWidth/2)+quarterLineWidth, (y*lineHeight)+(lineHeight/2));
                vertices.add(right);
            }

            // Bottom Edge
            if (edgeToBottomNodeExists) {
                Point right = new Point((x*lineWidth)+(lineWidth/2)+halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                Point left = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                vertices.add(right);
                vertices.add(left);       
            } else {
                Point bottom = new Point((x*lineWidth)+(lineWidth/2), (y*lineHeight)+(lineHeight/2)+quarterLineHeight);
                vertices.add(bottom);
            }

            // Left Edge
            if (edgeToLeftNodeExists) {
                Point bottom = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)+halfLineHeight);
                Point top = new Point((x*lineWidth)+(lineWidth/2)-halfLineWidth, (y*lineHeight)+(lineHeight/2)-halfLineHeight);
                vertices.add(bottom);
                vertices.add(top);       
            } else {
                Point left = new Point((x*lineWidth)+(lineWidth/2)-quarterLineWidth, (y*lineHeight)+(lineHeight/2));
                vertices.add(left);
            }
            
            // Remove duplicate vertices
            for (int i = 0; i < vertices.size(); i++) {
                Point currPoint = vertices.get(i);
                for (int j = 0; j < vertices.size(); j++) {
                    Point comparePoint = vertices.get(j);
                    if (i != j) {
                        if (int(currPoint.x) == int(comparePoint.x) && int(currPoint.y) == int(comparePoint.y)) {
                            vertices.remove(j);
                            j = 0;
                        }
                    }
                }    
            }

            ArrayList<Point> convexHullVertices = convexHull(vertices);
            voronoiDiagram.add(new VoronoiCell(imagePixels[x][y], convexHullVertices));
		}
	}
}

void drawVoronoiDiagram() {
    for (int i = 0; i < voronoiDiagram.size(); i++) {
        VoronoiCell currCell = voronoiDiagram.get(i);

        fill(currCell.cellColor);

        beginShape();
        for (int j = 0; j < currCell.cellVertices.size(); j++) {
            vertex(currCell.cellVertices.get(j).x, currCell.cellVertices.get(j).y);
        }
        endShape(CLOSE);
    }
}

void keyPressed() {
	if (key == ' ') {
		currState = (currState + 1) % NUM_DRAW_STATES;
        if (currState == FULLY_CONNECTED_STATE) {
            generateGraph = true;
        } 
        else if (currState == CUT_OFF_DISSIMILAR) {
            cutOffDissimilar = true;
        }
        else if (currState == RESOLVE_BLUE_CROSSINGS) {
            resolveBlueCrossings = true;
        }
        else if (currState == RESOLVE_RED_CROSSINGS) {
            resolveRedCrossings = true;
        }
        else if (currState == GENERATE_VORONOI_DIAGRAM) {
            generateVoronoiDiagram = true;
        }
	}
	if ( key == '1' ) {
		img = loadImage("Images/smw_boo_input.png");
		loadImagePixels();
		currState = 0;
	}
	if ( key == '2' ) {
		img = loadImage("Images/smw_dolphin_input.png");
		loadImagePixels();
		currState = 0;
	}
	if ( key == '3' ) {
		img = loadImage("Images/invaders_03_input.png");
		loadImagePixels();
		currState = 0;
	}
	if ( key == '4' ) {
		img = loadImage("Images/gaxe2_axbattler_02_input.png");
		loadImagePixels();
		currState = 0;
	}
	if ( key == '5' ) {
		img = loadImage("Images/win31_keyboard_input.png");
		loadImagePixels();
		currState = 0;
	}
	if ( key == '6' ) {
		img = loadImage("Images/win31_386_input.png");
		loadImagePixels();
		currState = 0;
	}
    if ( key == '7' ) {
		img = loadImage("Images/smb_jump_input.png");
		loadImagePixels();
		currState = 0;
	}
    if ( key == '8' ) {
        img = loadImage("Images/gaxe_skeleton_input.png");
		loadImagePixels();
		currState = 0;
	}
    if ( key == '9' ) {
		img = loadImage("Images/win31_setup_input.png");
		loadImagePixels();
		currState = 0;
	}
}

// https://www.pcmag.com/encyclopedia/term/yuvrgb-conversion-formulas:

float YfromRGB(float R, float G, float B)
{
    return ((0.299 * R) + (0.587 * G) + (0.114 * B));
}

float UfromRGB(float R, float G, float B)
{
  return ((-0.147 * R) - (0.289 * G) + (0.436 * B));
}

float VfromRGB(float R, float G, float B)
{
  return ((0.615 * R) - (0.515 * G) - (0.100 * B));
}

// Used the following site for Convex Hull algorithm (Jarvis March):
// https://www.geeksforgeeks.org/convex-hull-set-1-jarviss-algorithm-or-wrapping/

// Finds the orientation of ordered triplet (p, q, r). 
// return val == 0 --> p, q and r are Colinear 
// return val == 1 --> Clockwise 
// return val == 2 --> Counterclockwise 
int orientation(Point p, Point q, Point r) {
    int val = round((q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)); 

    // if (val == 0) -> Collinear
    if (val > 0) {
        val = 1; // Clockwise
    } else if (val < 0) {
        val = 2; // Counterclockwise 
    }

    return val;
}

ArrayList<Point> convexHull(ArrayList<Point> vertices) {
    int numVertices = vertices.size();
    ArrayList<Point> convexHullVertices = new ArrayList<Point>();

    if (numVertices >= 3) {
        // Find the leftmost point 
        int leftMost = 0; 

        for (int i = 1; i < numVertices; i++) {
            if (vertices.get(i).x < vertices.get(leftMost).x) 
                leftMost = i;
        }

        // Move counterclockwise starting from the leftmost point, until we reach the leftmost point again
        int currPoint = leftMost, nextCounterClockwisePoint; 
        do { 
            // Add current point to Convex hull list
            convexHullVertices.add(vertices.get(currPoint)); 

            // Search for a point 'q' such that orientation(p, x, q) is counterclockwise for all points 'x'
            // The idea is to keep track of the last visited 'most' counterclock-wise point, i.e. q
            // If any point 'i' is more counterclock-wise than q, then update q
            nextCounterClockwisePoint = (currPoint + 1) % numVertices; 
            
            for (int i = 0; i < numVertices; i++) 
            {
                if (orientation(vertices.get(currPoint), vertices.get(i), vertices.get(nextCounterClockwisePoint)) == 2) {
                    nextCounterClockwisePoint = i; 
                }
            }
            currPoint = nextCounterClockwisePoint;
            
        } while (currPoint != leftMost);
    }

    return convexHullVertices;
}

void printPointList(ArrayList<Point> points) {
    print("------------------\n");
    for (int i = 0; i < points.size(); i++) {
        print("(" + points.get(i).x + ", " + points.get(i).y + ")\n"); 
    }
    print("------------------\n");
}

// Used the following site for Graph implementation:
// https://www.programiz.com/dsa/graph-adjacency-matrix
// And the following for graph traversal algorithm (DFS) to count connected component sizes (Heuristic 2: Sparse pixels)
// https://www.geeksforgeeks.org/connected-components-in-an-undirected-graph/
class Graph {
    private boolean adjacencyMatrix[][];
    private int numVertices;

    public Graph (int numVertices) {
        this.numVertices = numVertices;
        adjacencyMatrix = new boolean[numVertices][numVertices];
    }

    public void addEdge(int i, int j) {
        adjacencyMatrix[i][j] = true;
        adjacencyMatrix[j][i] = true;
    }
 
    public void removeEdge(int i, int j) {
        adjacencyMatrix[i][j] = false;
        adjacencyMatrix[j][i] = false;
    }
 
    public boolean isEdge(int i, int j) {
        boolean result = false;
        if (i >= 0 && i < numVertices && j >= 0 && j < numVertices) {
            result = adjacencyMatrix[i][j];
        }
        return result;
    }

    public void DFSUtilPrint(int v, boolean[] visited, IntList componentList) {
        visited[v] = true;
        componentList.append(v);
        
        int topLeftPixel = -1;
        int topPixel = -1;
        int topRightPixel = -1;
        int leftPixel = -1;
        int rightPixel = -1;
        int bottomLeftPixel = -1;
        int bottomPixel = -1;
        int bottomRightPixel = -1;

        if (v == 0) { // top left corner
            rightPixel = v + 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
        }
        else if (v == (imagePixels.length-1)) { // top right corner
            leftPixel = v - 1;
            bottomPixel = v + (imagePixels.length);
            bottomLeftPixel = v + (imagePixels.length) - 1;
        }
        else if (v == (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom left corner
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if (v == (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom right corner
            topPixel = v - (imagePixels.length);
            topLeftPixel = v - (imagePixels.length) - 1;
            leftPixel = v - 1;
        }
        else if (v > 0 && v < (imagePixels.length-1)) { // top row
            leftPixel = v - 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if (v > (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1)) && v < (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom row
            leftPixel = v - 1;
            topLeftPixel = v - (imagePixels.length) - 1;
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if (v % (imagePixels.length) == 0) { // left column
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
            bottomRightPixel = v + (imagePixels.length) + 1;
            bottomPixel = v + (imagePixels.length);
        }
        else if (((v + 1) % (imagePixels.length)) == 0) { // right column
            topPixel = v - (imagePixels.length);
            topLeftPixel = v - (imagePixels.length) - 1;
            leftPixel = v - 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
        }
        else { // anywhere else
            topLeftPixel = v - (imagePixels.length) - 1;
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            leftPixel = v - 1;
            rightPixel = v + 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
        }

        // Top-left pixel
        if (topLeftPixel != -1) {
            if (similarityGraph.isEdge(v, topLeftPixel) && !visited[topLeftPixel]) {
                DFSUtilPrint(topLeftPixel, visited, componentList);
            }
        }
        // Top pixel
        if (topPixel != -1) {
            if (similarityGraph.isEdge(v, topPixel) && !visited[topPixel]) {
                DFSUtilPrint(topPixel, visited, componentList);
            }
        }
        // Top-right pixel
        if (topRightPixel != -1) {
            if (similarityGraph.isEdge(v, topRightPixel) && !visited[topRightPixel]) {
                DFSUtilPrint(topRightPixel, visited, componentList);
            }
        }
        // Left pixel
        if (leftPixel != -1) {
            if (similarityGraph.isEdge(v, leftPixel) && !visited[leftPixel]) {
                DFSUtilPrint(leftPixel, visited, componentList);
            }
        }
        // Right pixel
        if (rightPixel != -1) {
            if (similarityGraph.isEdge(v, rightPixel) && !visited[rightPixel]) {
                DFSUtilPrint(rightPixel, visited, componentList);
            }
        }
        // Bottom-left pixel
        if (bottomLeftPixel != -1) {
            if (similarityGraph.isEdge(v, bottomLeftPixel) && !visited[bottomLeftPixel]) {
                DFSUtilPrint(bottomLeftPixel, visited, componentList);
            }
        }
        // Bottom pixel
        if (bottomPixel != -1) {
            if (similarityGraph.isEdge(v, bottomPixel) && !visited[bottomPixel]) {
                DFSUtilPrint(bottomPixel, visited, componentList);
            }
        }
        // Bottom-right pixel
        if (bottomRightPixel != -1) {
            if (similarityGraph.isEdge(v, bottomRightPixel) && !visited[bottomRightPixel]) {
                DFSUtilPrint(bottomRightPixel, visited, componentList);
            }
        }
    }

    public void printAllConnectedComponents() {
        boolean[] visited = new boolean[numVertices];
        ArrayList<IntList> componentLists = new ArrayList<IntList>();
        
        for (int v = 0; v < numVertices; v++) {
            if(!visited[v]) {
                componentLists.add(new IntList());
                DFSUtilPrint(v, visited, componentLists.get(componentLists.size()-1));
            }
        }
        print("Num Connected Components: " + componentLists.size() + "\n\n");

        for (int i = 0; i < componentLists.size(); i++) {
            print("Component " + (i+1) +": ");
            for (int j = 0; j < componentLists.get(i).size(); j++) {
                print(componentLists.get(i).get(j) + " ");
            }
            print("\n\n");
        }
    }

    public void DFSUtilSparsePixels(int v, int topLeftX, int topLeftY, int width, int height, boolean[] visited, IntList componentList, IntList truncatedVertexList) {
        visited[v] = true;
        componentList.append(v);

        int topLeftPixel = -1;
        int topPixel = -1;
        int topRightPixel = -1;
        int leftPixel = -1;
        int rightPixel = -1;
        int bottomLeftPixel = -1;
        int bottomPixel = -1;
        int bottomRightPixel = -1;

        if (v == (topLeftX+topLeftY+(topLeftY*(imagePixels.length-1))) || v == 0) { // top left corner
            rightPixel = v + 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
        }
        else if (v == ((topLeftX+width-1)+topLeftY+(topLeftY*(imagePixels.length-1))) || v == (imagePixels.length-1)) { // top right corner
            leftPixel = v - 1;
            bottomPixel = v + (imagePixels.length);
            bottomLeftPixel = v + (imagePixels.length) - 1;
        }
        else if (v == (topLeftX+(topLeftY+height-1)+((topLeftY+height-1)*(imagePixels.length-1))) || v == (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom left corner
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if (v == ((topLeftX+width-1)+(topLeftY+height-1)+((topLeftY+height-1)*(imagePixels.length-1))) || v == (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1))) { // bottom right corner
            topPixel = v - (imagePixels.length);
            topLeftPixel = v - (imagePixels.length) - 1;
            leftPixel = v - 1;
        }
        else if ((v > (topLeftX+topLeftY+(topLeftY*(imagePixels.length-1))) && v < ((topLeftX+width-1)+topLeftY+(topLeftY*(imagePixels.length-1)))) || (v > 0 && v < (imagePixels.length-1))) { // top row
            leftPixel = v - 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if ((v > (topLeftX+(topLeftY+height-1)+((topLeftY+height-1)*(imagePixels.length-1))) && v < ((topLeftX+width-1)+(topLeftY+height-1)+((topLeftY+height-1)*(imagePixels.length-1)))) || (v > (imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1)) && v < (imagePixels.length-1)+(imagePixels[0].length-1)+((imagePixels[0].length-1)*(imagePixels.length-1)))) { // bottom row
            leftPixel = v - 1;
            topLeftPixel = v - (imagePixels.length) - 1;
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
        }
        else if (v % (imagePixels.length) == 0) { // left column
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            rightPixel = v + 1;
            bottomRightPixel = v + (imagePixels.length) + 1;
            bottomPixel = v + (imagePixels.length);
        }
        else if ((v + 1) % (imagePixels.length) == 0) { // right column
            topPixel = v - (imagePixels.length);
            topLeftPixel = v - (imagePixels.length) - 1;
            leftPixel = v - 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
        }
        else { // anywhere else
            topLeftPixel = v - (imagePixels.length) - 1;
            topPixel = v - (imagePixels.length);
            topRightPixel = v - (imagePixels.length) + 1;
            leftPixel = v - 1;
            rightPixel = v + 1;
            bottomLeftPixel = v + (imagePixels.length) - 1;
            bottomPixel = v + (imagePixels.length);
            bottomRightPixel = v + (imagePixels.length) + 1;
        }

        // Top-left pixel
        if (topLeftPixel != -1 && truncatedVertexList.hasValue(topLeftPixel)) {
            if (similarityGraph.isEdge(v, topLeftPixel) && !visited[topLeftPixel]) {
                DFSUtilSparsePixels(topLeftPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Top pixel
        if (topPixel != -1 && truncatedVertexList.hasValue(topPixel)) {
            if (similarityGraph.isEdge(v, topPixel) && !visited[topPixel]) {
                DFSUtilSparsePixels(topPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Top-right pixel
        if (topRightPixel != -1 && truncatedVertexList.hasValue(topRightPixel)) {
            if (similarityGraph.isEdge(v, topRightPixel) && !visited[topRightPixel]) {
                DFSUtilSparsePixels(topRightPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Left pixel
        if (leftPixel != -1 && truncatedVertexList.hasValue(leftPixel)) {
            if (similarityGraph.isEdge(v, leftPixel) && !visited[leftPixel]) {
                DFSUtilSparsePixels(leftPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Right pixel
        if (rightPixel != -1 && truncatedVertexList.hasValue(rightPixel)) {
            if (similarityGraph.isEdge(v, rightPixel) && !visited[rightPixel]) {
                DFSUtilSparsePixels(rightPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Bottom-left pixel
        if (bottomLeftPixel != -1 && truncatedVertexList.hasValue(bottomLeftPixel)) {
            if (similarityGraph.isEdge(v, bottomLeftPixel) && !visited[bottomLeftPixel]) {
                DFSUtilSparsePixels(bottomLeftPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Bottom pixel
        if (bottomPixel != -1 && truncatedVertexList.hasValue(bottomPixel)) {
            if (similarityGraph.isEdge(v, bottomPixel) && !visited[bottomPixel]) {
                DFSUtilSparsePixels(bottomPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
        // Bottom-right pixel
        if (bottomRightPixel != -1 && truncatedVertexList.hasValue(bottomRightPixel)) {
            if (similarityGraph.isEdge(v, bottomRightPixel) && !visited[bottomRightPixel]) {
                DFSUtilSparsePixels(bottomRightPixel, topLeftX, topLeftY, width, height, visited, componentList, truncatedVertexList);
            }
        }
    }

    public ArrayList<IntList> sparsePixelsComponentCount(int topLeftX, int topLeftY, int width, int height) {
        boolean[] visited = new boolean[numVertices];
        ArrayList<IntList> componentLists = new ArrayList<IntList>();
        
        IntList truncatedVertexList = new IntList();
        for (int y = topLeftY; y < (topLeftY + height); y++) {
            for (int x = topLeftX; x < (topLeftX + width); x++) {
                truncatedVertexList.append((x+y+(y*(imagePixels.length-1))));
            }
        }
        
        for (int i = 0; i < truncatedVertexList.size(); i++) {
            int v = truncatedVertexList.get(i);
            if(!visited[v]) {
                componentLists.add(new IntList());
                DFSUtilSparsePixels(v, topLeftX, topLeftY, width, height, visited, componentLists.get(componentLists.size()-1), truncatedVertexList);
            }
        }

        return componentLists;
    }
}

class Point {
    public float x;
    public float y;

    public Point(float initX, float initY) {
        x = initX;
        y = initY;
    }
}

class VoronoiCell {
    public color cellColor;
    public ArrayList<Point> cellVertices;

    public VoronoiCell(color initColor, ArrayList<Point> initCellVertices) {
        cellColor = initColor;
        cellVertices = initCellVertices;
    }
}

