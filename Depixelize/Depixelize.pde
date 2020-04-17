PImage img;
color[][] imagePixels;
int currState = 0;

// Draw_State for application
final int ORIGINAL_SCALE_STATE = 0;
final int PROCESSING_SCALE_STATE = 1;
final int INITIAL_DEPIXELIZE_STATE = 2;
final int NUM_DRAW_STATES = 3;

void setup() {
	size(1024, 1024);
	imageMode(CENTER);

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
	float rectWidth = width/(imagePixels.length * 1.0);
	float rectHeight = height/(imagePixels[0].length * 1.0);
	for (int x = 0; x < imagePixels.length; x++) {
		for (int y = 0; y < imagePixels[x].length; y++) {
			fill(imagePixels[x][y]);
			rect(x*rectWidth,y*rectHeight,rectWidth,rectHeight);
		}	
	}
}

void keyPressed() {
	if (key == ' ') {
		currState = (currState + 1) % NUM_DRAW_STATES;
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

