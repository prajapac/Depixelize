PImage img;
Graph similarityGraph;
color[][] imagePixels;
int currState = 0;
boolean generateGraph = false;
boolean cutOffDissimilar = false;

// Draw_State for application
final int ORIGINAL_SCALE_STATE = 0;
final int PROCESSING_SCALE_STATE = 1;
final int INITIAL_DEPIXELIZE_STATE = 2;
final int FULLY_CONNECTED_STATE = 3;
final int CUT_OFF_DISSIMILAR = 4;
final int COLOR_CODE_CROSSINGS = 5;
final int NUM_DRAW_STATES = 6;

// Dissimilarity RGB Constants
final int DIFFERENCE_Y = 48;
final int DIFFERENCE_U = 7;
final int DIFFERENCE_V = 6;

void setup() {
	size(1024, 1024);
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
                        
                        // (Edge) Points
                        strokeWeight(10);
                        point(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2));
                        point((x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2));
                        strokeWeight(3);
                        
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

void keyPressed() {
	if (key == ' ') {
		currState = (currState + 1) % NUM_DRAW_STATES;
        if (currState == FULLY_CONNECTED_STATE) {
            generateGraph = true;
        } 
        else if (currState == CUT_OFF_DISSIMILAR) {
            cutOffDissimilar = true;
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

// Used the following site for Graph implementation:
// https://www.programiz.com/dsa/graph-adjacency-matrix
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
        return adjacencyMatrix[i][j];
    }
}

