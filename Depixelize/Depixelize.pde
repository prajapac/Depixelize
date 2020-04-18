PImage img;
Graph similarityGraph;
color[][] imagePixels;
int currState = 0;
boolean generateGraph = false;

// Draw_State for application
final int ORIGINAL_SCALE_STATE = 0;
final int PROCESSING_SCALE_STATE = 1;
final int INITIAL_DEPIXELIZE_STATE = 2;
final int FULLY_CONNECTED_STATE = 3;
final int CUT_OFF_DISIMILAR = 4;
final int NUM_DRAW_STATES = 5;

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
	for (int x = 0; x < imagePixels.length; x++) {
		for (int y = 0; y < imagePixels[0].length; y++) {
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
	for (int x = 0; x < imagePixels.length; x++) {
		for (int y = 0; y < imagePixels[0].length; y++) {
			fill(red(imagePixels[x][y]), green(imagePixels[x][y]), blue(imagePixels[x][y]), alpha);
			rect(x*rectWidth,y*rectHeight,rectWidth,rectHeight);
		}	
	}
}

void generateGraph() {
    similarityGraph = new Graph(((imagePixels.length)*(imagePixels[0].length)));

    for (int x = 0; x < imagePixels.length; x++) {
		for (int y = 0; y < imagePixels[0].length; y++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) {
                similarityGraph.addEdge(x+y, x+y+imagePixels.length); // |
                } else if (y == imagePixels[0].length-1) {
                    similarityGraph.addEdge(x+y, x+y+1); // -
                } else {
                    similarityGraph.addEdge(x+y, x+y+1); // -
                    similarityGraph.addEdge(x+y, x+y+imagePixels.length); // |
                    similarityGraph.addEdge(x+y, x+y+imagePixels.length+1); // \
                    similarityGraph.addEdge(x+y+1, x+y+imagePixels.length); // /
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
    for (int x = 0; x < imagePixels.length; x++) {
		for (int y = 0; y < imagePixels[0].length; y++) {
            if(!(x == imagePixels.length-1 && y == imagePixels[0].length-1)) {
                if (x == imagePixels.length-1) {
                    if(similarityGraph.isEdge(x+y, x+y+imagePixels.length)) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2)); // |
                    }
                } else if (y == imagePixels[0].length-1) {
                    if(similarityGraph.isEdge(x+y, x+y+1)) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2)); // -
                    }
                }else {
                    if(similarityGraph.isEdge(x+y, x+y+1)) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2)); // -
                    }
                    if(similarityGraph.isEdge(x+y, x+y+imagePixels.length)) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2)); // |
                    }
                    if(similarityGraph.isEdge(x+y, x+y+imagePixels.length+1)) {
                        line((x*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),((x+1)*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2)); // \
                    }
                    if(similarityGraph.isEdge(x+y+1, x+y+imagePixels.length)) {
                        line(((x+1)*lineWidth)+(lineWidth/2),(y*lineHeight)+(lineHeight/2),(x*lineWidth)+(lineWidth/2),((y+1)*lineHeight)+(lineHeight/2)); // /
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

